// diagnostic-render - library for printing formatted diagnostics
// Copyright (C) 2024  mschae23
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const io = @import("../io.zig");
const file = @import("../file.zig");
const LineColumn = file.LineColumn;
const diag = @import("../diagnostic.zig");
const Diagnostic = diag.Diagnostic;
const Annotation = diag.Annotation;
const ColorConfig = @import("../ColorConfig.zig");
const calculate = @import("./calculate/mod.zig");

/// Contains some configuration parameters for [`DiagnosticRenderer`].
///
/// [`DiagnosticRenderer`]: DiagnosticRenderer
pub const RenderConfig = struct {
    /// How many lines of source code to include around annotated lines for context.
    surrounding_lines: usize = 1,
    /// The display width of horizontal tab characters.
    tab_length: usize = 4,
    /// The color config.
    colors: ColorConfig = ColorConfig.DEFAULT,
};

/// A renderer for diagnostics using an "ASCII art"-like format.
pub fn DiagnosticRenderer(comptime FileId: type) type {
    return struct {
        global_allocator: std.mem.Allocator,
        writer: std.io.AnyWriter, colors: std.io.tty.Config, files: file.Files(FileId), config: RenderConfig,

        max_nested_blocks: usize, line_digits: u32,

        const Self = @This();

        /// Creates a new diagnostics renderer.
        pub fn init(allocator: std.mem.Allocator, writer: std.io.AnyWriter, colors: std.io.tty.Config, files: file.Files(FileId), config: RenderConfig) Self {
            return Self {
                .global_allocator = allocator,
                .writer = writer, .colors = colors, .files = files, .config = config,
                .max_nested_blocks = 0, .line_digits = 0,
            };
        }

        /// Renders the given diagnostics.
        ///
        /// Consider the renderer deinitialized after this call.
        pub fn render(self: *Self, diagnostics: []const Diagnostic(FileId)) anyerror!void {
            if (diagnostics.len == 0) {
                return;
            }

            defer {
                var files = self.files;
                files.deinit();
            }

            return self.renderImpl(diagnostics);
        }

        fn renderImpl(self: *Self, diagnostics: []const Diagnostic(FileId)) anyerror!void {
            var self2 = self;
            var i: usize = 0;

            var diagnostic_allocator = std.heap.ArenaAllocator.init(self.global_allocator);
            defer diagnostic_allocator.deinit();
            const allocator = diagnostic_allocator.allocator();

            while (i < diagnostics.len) : (i += 1) {
                defer _ = diagnostic_allocator.reset(.retain_capacity);

                const diagnostic = &diagnostics[i];
                try self2.renderDiagnostic(allocator, diagnostic);

                if (i < diagnostics.len - 1) {
                    try self2.writer.writeByte('\n');
                }
            }
        }

        fn renderDiagnostic(self: *Self, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId)) anyerror!void {
            try self.renderDiagnosticHeader(diagnostic);

            if (diagnostic.annotations.len != 0) {
                var annotations_by_file = std.AutoArrayHashMap(FileId, std.ArrayListUnmanaged(*const Annotation(FileId))).init(allocator);

                defer {
                    const values = annotations_by_file.values();

                    for (values) |*value| {
                        value.deinit(allocator);
                    }

                    annotations_by_file.deinit();
                }

                var i: usize = 0;
                var max_line_number: usize = 0;

                while (i < diagnostic.annotations.len) : (i += 1) {
                    const annotation = &diagnostic.annotations[i];
                    const entry = try annotations_by_file.getOrPut(annotation.file_id);

                    if (!entry.found_existing) {
                        errdefer _ = annotations_by_file.orderedRemove(annotation.file_id);
                        entry.value_ptr.* = try std.ArrayListUnmanaged(*const Annotation(FileId)).initCapacity(allocator, 1);
                    }

                    try entry.value_ptr.insert(allocator, std.sort.upperBound(*const Annotation(FileId), annotation, entry.value_ptr.items, {}, struct {
                        pub fn inner(_: void, a: *const Annotation(FileId), b: *const Annotation(FileId)) bool {
                            return a.range.start < b.range.start;
                        }
                    }.inner), annotation);

                    const line_index = (try self.files.lineIndex(annotation.file_id, annotation.range.end, .exclusive)) orelse return error.FileNotFound;
                    const line_number = self.files.lineNumber(annotation.file_id, line_index);
                    max_line_number = @max(max_line_number, line_number);
                }

                const last_printed_line_number = max_line_number + self.config.surrounding_lines;
                self.line_digits = std.math.log10_int(last_printed_line_number) + 1;

                var iter = annotations_by_file.iterator();

                while (iter.next()) |entry| {
                    try self.renderDiagnosticFile(allocator, diagnostic, entry.key_ptr.*, entry.value_ptr);
                }
            }

            try self.renderDiagnosticFooter(diagnostic);

            if (diagnostic.suppressed_count > 0) {
                try self.writer.print("... and {d} more\n", .{diagnostic.suppressed_count});
            }

            self.max_nested_blocks = 0;
            self.line_digits = 0;
        }

        fn renderDiagnosticHeader(self: *Self, diagnostic: *const Diagnostic(FileId)) anyerror!void {
            try self.config.colors.writeSeverity(self.colors, self.writer, diagnostic.severity);
            try self.writer.print("{any}", .{diagnostic.severity});

            if (diagnostic.name) |name| {
                try self.writer.writeByte('[');
                try self.config.colors.writeName(self.colors, self.writer, diagnostic.severity);
                try self.writer.writeAll(name);
                try self.config.colors.writeSeverity(self.colors, self.writer, diagnostic.severity);
                try self.writer.writeByte(']');
            }

            if (diagnostic.message.len != 0) {
                try self.config.colors.writeReset(self.colors, self.writer);
                try self.writer.writeAll(": ");
                try self.config.colors.writeMessage(self.colors, self.writer);
                try self.writer.writeAll(diagnostic.message);
                try self.config.colors.writeReset(self.colors, self.writer);
                try self.writer.writeByte('\n');
            }

            try self.config.colors.writeReset(self.colors, self.writer);

            if (diagnostic.message.len == 0) {
                try self.writer.writeByte('\n');
            }
        }

        fn renderDiagnosticFooter(self: *Self, diagnostic: *const Diagnostic(FileId)) anyerror!void {
            // Render notes
            _ = self;
            _ = diagnostic;
        }

        fn renderDiagnosticFile(self: *Self, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId), file_id: FileId, annotations: *std.ArrayListUnmanaged(*const Annotation(FileId))) anyerror!void {
            var location: usize = 0;

            {
                var i: usize = 0;

                while (i < annotations.items.len) : (i += 1) {
                    const annotation = annotations.items[i];

                    if (annotation.style == .primary) {
                        location = annotation.range.start;
                        break;
                    } else if (i == 0) {
                        location = annotation.range.start;
                    }
                }
            }

            try self.writeLineNumber(null, .arrow);
            try self.writer.writeByte(' ');
            try self.config.colors.writePath(self.colors, self.writer);
            try self.writer.writeAll(self.files.name(file_id) orelse return error.FileNotFound);

            const user_location = try self.files.codepointLocation(file_id, location) orelse unreachable;

            try self.writer.print(":{d}:{d}\n", .{user_location.line_number, user_location.column_number});
            try self.config.colors.writeReset(self.colors, self.writer);

            // Annotations list is already sorted by start byte index

            {
                var max_nested_blocks: usize = 0;
                var current_nested_blocks = try std.ArrayListUnmanaged(usize).initCapacity(allocator, 0);
                defer current_nested_blocks.deinit(allocator);

                for (annotations.items) |annotation| {
                    const start_line_index = try self.files.lineIndex(file_id, annotation.range.start, .inclusive) orelse unreachable;
                    const end_line_index = try self.files.lineIndex(file_id, annotation.range.end, .exclusive) orelse unreachable;

                    if (start_line_index == end_line_index) {
                        continue;
                    }

                    {
                        var i: usize = 0;

                        while (i < current_nested_blocks.items.len) {
                            if (current_nested_blocks.items[i] <= start_line_index) {
                                // Order of current_nested_blocks doesn't matter, only how many items are in it at the same time
                                _ = current_nested_blocks.swapRemove(i);
                                continue;
                            }

                            i += 1;
                        }
                    }

                    (try current_nested_blocks.addOne(allocator)).* = end_line_index;
                    max_nested_blocks = @max(max_nested_blocks, current_nested_blocks.items.len);
                }

                self.max_nested_blocks = max_nested_blocks;
                // std.debug.print("[debug] Max nested blocks: {d}\n", .{self.max_nested_blocks});
            }

            return self.renderLinesWithAnnotations(allocator, diagnostic, file_id, annotations);
        }

        fn renderLinesWithAnnotations(self: *Self, diagnostic_allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId), file_id: FileId, annotations: *std.ArrayListUnmanaged(*const Annotation(FileId))) anyerror!void {
            var current_line_index: usize = try self.files.lineIndex(file_id, annotations.items[0].range.start, .inclusive) orelse unreachable;
            var last_line_index: ?usize = null;
            var already_printed_end_line_index: usize = 0;

            const last_line_index_in_file = try self.files.getLastLineIndex(file_id) orelse unreachable;
            var should_continue = true;

            var line_allocator = std.heap.ArenaAllocator.init(diagnostic_allocator);
            defer line_allocator.deinit();
            const allocator = line_allocator.allocator();

            while (should_continue) : (current_line_index += 1) {
                if (current_line_index > last_line_index_in_file) {
                    break;
                }

                defer _ = line_allocator.reset(.retain_capacity);
                should_continue = false;

                var continuing_annotations = try std.ArrayListUnmanaged(*const Annotation(FileId)).initCapacity(allocator, 0);
                defer continuing_annotations.deinit(allocator);
                var active_annotations = try std.ArrayListUnmanaged(*const Annotation(FileId)).initCapacity(allocator, 0);
                defer active_annotations.deinit(allocator);

                var i: usize = 0;

                while (i < annotations.items.len) : (i += 1) {
                    const annotation = annotations.items[i];
                    const start_line_index = try self.files.lineIndex(file_id, annotation.range.start, .inclusive) orelse unreachable;
                    const end_line_index = try self.files.lineIndex(file_id, annotation.range.end, .exclusive) orelse unreachable;

                    if (start_line_index > current_line_index) {
                        should_continue = true;
                        break;
                    } else if (start_line_index < current_line_index and end_line_index > current_line_index) {
                        (try continuing_annotations.addOne(allocator)).* = annotation;
                        should_continue = true;
                        continue;
                    } else if (start_line_index != current_line_index and end_line_index != current_line_index) {
                        continue;
                    }

                    if (start_line_index < current_line_index) {
                        (try continuing_annotations.addOne(allocator)).* = annotation;
                    }

                    if (end_line_index > current_line_index) {
                        should_continue = true;
                    }

                    (try active_annotations.addOne(allocator)).* = annotation;
                }

                if (active_annotations.items.len != 0) {
                    try self.renderPartLines(allocator, diagnostic, file_id, current_line_index, last_line_index,
                        continuing_annotations, active_annotations, &already_printed_end_line_index);
                }

                last_line_index = current_line_index;
            }

            if (last_line_index) |last_line| {
                if (last_line <= last_line_index_in_file) {
                    try self.renderPostSurroundingLines(diagnostic_allocator, diagnostic, file_id, last_line_index_in_file + 1, last_line, &.{}, &already_printed_end_line_index);
                }
            }
        }

        fn renderPostSurroundingLines(self: *Self, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId), file_id: FileId, main_line: usize, last_line: usize, continuing_annotations: []const *const Annotation(FileId), already_printed_end_line_index: *usize) anyerror!void {
            // self.debug.print("[debug] potentially printing post surrounding lines, last line: {}, already printed to: {}\n", .{last_line, already_printed_to.*})?;

            if (last_line + 1 >= already_printed_end_line_index.*) {
                const first_print_line = @max(last_line + 1, already_printed_end_line_index.*);
                const last_print_line = @min(last_line + self.config.surrounding_lines, main_line - 1);

                // self.debug.print("[debug] printing post surrounding lines, last line: {}, first: {}, last: {}", .{last_line, first_print_line, last_print_line})?;

                if (last_print_line >= first_print_line) {
                    var line: usize = first_print_line;

                    while (line <= last_print_line) : (line += 1) {
                        try self.writeSourceLine(allocator, diagnostic, file_id, line, .pipe, continuing_annotations);
                        already_printed_end_line_index.* = line + 1;
                    }
                }
            }
        }

        fn renderPartLines(self: *Self, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId), file_id: FileId, current_line_index: usize, last_line_index: ?usize, continuing_annotations: std.ArrayListUnmanaged(*const Annotation(FileId)), active_annotations: std.ArrayListUnmanaged(*const Annotation(FileId)), already_printed_end_line_index: *usize) anyerror!void {
            if (last_line_index) |last_line| {
                try self.renderPostSurroundingLines(allocator, diagnostic, file_id, current_line_index, last_line, continuing_annotations.items, already_printed_end_line_index);
            }

            const first_print_line_index = @max(current_line_index -| self.config.surrounding_lines, already_printed_end_line_index.*);
            const last_print_line_index = current_line_index;

            // std.debug.print("[debug] current line ({}); first = {}, last = {}\n", .{current_line_index, first_print_line_index, last_print_line_index});

            if (first_print_line_index != 0 and first_print_line_index > already_printed_end_line_index.*) {
                try self.writeSourceLine(allocator, diagnostic, file_id, null, .ellipsis, continuing_annotations.items);
            }

            var line: usize = first_print_line_index;

            while (line <= last_print_line_index) : (line += 1) {
                try self.renderLine(allocator, diagnostic, file_id, line, current_line_index, &continuing_annotations, &active_annotations);
                already_printed_end_line_index.* += 1;
            }
        }

        fn writeSourceLine(self: *Self, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId), file_id: FileId, line_index: ?usize, separator: LineNumberSeparator, continuing_annotations: []const *const Annotation(FileId)) anyerror!void {
            const line_number: ?usize = if (line_index) |line| block: {
                break :block self.files.lineNumber(file_id, line);
            } else block: {
                break :block null;
            };

            try self.writeLineNumber(line_number, separator);

            if (separator == .pipe or separator == .end) {
                try self.writer.writeByte(' ');
            }

            var i: usize = 0;

            while (i < continuing_annotations.len) : (i += 1) {
                const annotation = continuing_annotations[i];

                try self.config.colors.writeAnnotation(self.colors, self.writer, annotation.style, diagnostic.severity);
                try self.writer.writeByte('|');
                try self.config.colors.writeReset(self.colors, self.writer);

                try self.writer.writeByte(' ');
            }

            if (line_index) |line| {
                const reader = self.files.reader(file_id) orelse unreachable;
                const seeker = self.files.seeker(file_id) orelse unreachable;
                const line_range = try self.files.lineRange(file_id, line) orelse unreachable;

                if (line_range.end != line_range.start) {
                    try self.writer.writeByteNTimes(' ', 2 * (self.max_nested_blocks - continuing_annotations.len));

                    try seeker.seekTo(@as(u64, line_range.start));

                    // TODO Handle UTF-8 manually as specified in https://encoding.spec.whatwg.org/#utf-8-decoder.
                    //      This way, we can ensure that ill-conforming code unit sequences are handled the exact
                    //      same way as Files.columnIndex.
                    //      The drawback is that, while it won't need the allocator anymore, this function will
                    //      have to stream the line from the reader to the writer byte for byte (because it has to
                    //      constantly decode and re-encode the UTF-8 data).
                    // TODO Also handle tabs

                    const buf: []u8 = try allocator.alloc(u8, line_range.end - line_range.start);
                    defer allocator.free(buf);
                    try reader.readNoEof(buf);

                    try self.config.colors.writeSource(self.colors, self.writer);
                    try self.writer.writeAll(buf);
                    try self.config.colors.writeReset(self.colors, self.writer);
                }
            }

            try self.writer.writeByte('\n');
        }

        fn renderLine(self: *Self, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId), file_id: FileId, line_index: usize, main_line_index: usize, continuing_annotations: *const std.ArrayListUnmanaged(*const Annotation(FileId)), active_annotations: *const std.ArrayListUnmanaged(*const Annotation(FileId))) anyerror!void {
            try self.writeSourceLine(allocator, diagnostic, file_id, line_index, .pipe, continuing_annotations.items);

            if (line_index != main_line_index or active_annotations.items.len == 0) {
                return;
            }

            return self.renderLineAnnotations(allocator, diagnostic, file_id, line_index, continuing_annotations, active_annotations);
        }

        fn renderLineAnnotations(self: *Self, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId), file_id: FileId, line_index: usize, continuing_annotations: *const std.ArrayListUnmanaged(*const Annotation(FileId)), active_annotations: *const std.ArrayListUnmanaged(*const Annotation(FileId))) anyerror!void {
            var annotation_data = try calculate.calculate(FileId, allocator, diagnostic, &self.files, file_id, line_index, self.config.tab_length, continuing_annotations.items, active_annotations.items);
            defer annotation_data.deinit(allocator);

            const ConnectingData = struct {
                style: diag.AnnotationStyle,
                severity: diag.Severity,
                multiline: bool,
                end_location: LineColumn,
            };

            var connection_stack = try std.ArrayListUnmanaged(ConnectingData).initCapacity(allocator, 0);
            defer connection_stack.deinit(allocator);

            var vertical_bar_index: usize = 0;
            var pre_source = true;
            var column_index: usize = 0;
            var first = true;
            var last_label = false;

            for (annotation_data.items) |item| {
                if (first) {
                    try self.writeLineNumber(null, .pipe);
                    first = false;
                }

                if (last_label and item != .newline) {
                    unreachable;
                }

                switch (item) {
                    .continuing_multiline => |data| {
                        std.debug.assert(pre_source);

                        try self.writer.writeByte(' ');
                        try self.config.colors.writeAnnotation(self.colors, self.writer, data.style, data.severity);
                        try self.writer.writeByte('|');
                        try self.config.colors.writeReset(self.colors, self.writer);

                        vertical_bar_index += 1;
                    },
                    .connecting_multiline => |data| {
                        std.debug.assert(pre_source);

                        if (vertical_bar_index < data.vertical_bar_index + 1) {
                            try self.writer.writeByteNTimes(' ', 2 * (1 + data.vertical_bar_index - vertical_bar_index));
                        }

                        (try connection_stack.addOne(allocator)).* = ConnectingData {
                            .style = data.style, .severity = data.severity,
                            .multiline = true,
                            .end_location = data.end_location,
                        };

                        // To get to column_index == 0
                        try self.config.colors.writeAnnotation(self.colors, self.writer, data.style, data.severity);
                        try self.writer.writeByte('_');
                        pre_source = false;
                    },
                    .start => |data| {
                        try self.writeConnectionUpTo(ConnectingData, vertical_bar_index, &pre_source, &column_index, &connection_stack, data.location.column_index);

                        try self.config.colors.writeAnnotation(self.colors, self.writer, data.style, data.severity);
                        try self.writer.writeByte(switch (data.style) {
                            .primary => '^',
                            .secondary => '-',
                        });
                        column_index += 1;
                    },
                    .connecting_singleline => |data| {
                        try self.writeConnectionUpTo(ConnectingData, vertical_bar_index, &pre_source, &column_index, &connection_stack, data.start_column_index);

                        (try connection_stack.addOne(allocator)).* = ConnectingData {
                            .style = data.style, .severity = data.severity,
                            .multiline = data.as_multiline,
                            .end_location = LineColumn.init(data.line_index, data.end_column_index),
                        };
                    },
                    .end => |data| {
                        try self.writeConnectionUpTo(ConnectingData, vertical_bar_index, &pre_source, &column_index, &connection_stack, data.location.column_index);

                        try self.config.colors.writeAnnotation(self.colors, self.writer, data.style, data.severity);
                        try self.writer.writeByte(switch (data.style) {
                            .primary => '^',
                            .secondary => '-',
                        });
                        column_index += 1;
                    },
                    .hanging => |data| {
                        try self.writeConnectionUpTo(ConnectingData, vertical_bar_index, &pre_source, &column_index, &connection_stack, data.location.column_index);

                        try self.config.colors.writeAnnotation(self.colors, self.writer, data.style, data.severity);
                        try self.writer.writeByte('|');
                        column_index += 1;
                    },
                    .label => |data| {
                        try self.writeConnectionUpTo(ConnectingData, vertical_bar_index, &pre_source, &column_index, &connection_stack, data.location.column_index);

                        try self.config.colors.writeAnnotation(self.colors, self.writer, data.style, data.severity);
                        try self.writer.writeAll(data.label);
                        column_index += data.label.len;
                        last_label = true;
                    },
                    .newline => {
                        while (connection_stack.getLastOrNull()) |top| {
                            if (top.end_location.column_index <= column_index) {
                                _ = connection_stack.pop();
                            } else {
                                try self.config.colors.writeAnnotation(self.colors, self.writer, top.style, top.severity);

                                try self.writer.writeByteNTimes(if (top.multiline) '_' else switch (top.style) {
                                    .primary => '^',
                                    .secondary => '-',
                                }, top.end_location.column_index - column_index);
                                column_index += top.end_location.column_index - column_index;

                                _ = connection_stack.pop();
                            }
                        }

                        vertical_bar_index = 0;
                        pre_source = true;
                        column_index = 0;
                        first = true;
                        last_label = false;
                        try self.config.colors.writeReset(self.colors, self.writer);
                        try self.writer.writeByte('\n');
                    },
                }
            }
        }

        fn writeConnectionUpTo(self: *Self, comptime ConnectingData: type, vertical_bar_index: usize, pre_source: *bool, column_index: *usize, connection_stack: *std.ArrayListUnmanaged(ConnectingData), end_column_index: usize) anyerror!void {
            if (pre_source.*) {
                if (vertical_bar_index < self.max_nested_blocks) {
                    try self.writer.writeByteNTimes(' ', 2 * (self.max_nested_blocks - vertical_bar_index));
                }

                try self.writer.writeByte(' ');
                pre_source.* = false;
            }

            while (column_index.* < end_column_index) {
                var connection: ?ConnectingData = connection_stack.getLastOrNull();
                var new = true;

                while (connection) |top| {
                    if (top.end_location.column_index <= column_index.*) {
                        _ = connection_stack.pop();
                        connection = connection_stack.getLastOrNull();
                        new = true;
                    } else {
                        break;
                    }
                }

                if (new) {
                    if (connection) |top| {
                        try self.config.colors.writeAnnotation(self.colors, self.writer, top.style, top.severity);
                    } else {
                        try self.config.colors.writeReset(self.colors, self.writer);
                    }

                    new = false;
                }

                if (connection) |top| {
                    try self.writer.writeByte(if (top.multiline) '_' else switch (top.style) {
                        .primary => '^',
                        .secondary => '-',
                    });
                } else {
                    try self.writer.writeByte(' ');
                }

                column_index.* += 1;
            }
        }

        const LineNumberSeparator = enum {
            arrow,
            ellipsis,
            pipe,
            end,
        };

        fn writeLineNumber(self: *Self, line: ?usize, separator: LineNumberSeparator) anyerror!void {
            if (line) |line2| {
                try self.config.colors.writeLineNumber(self.colors, self.writer);
                try self.writer.print("{[number]:>[fill]}", .{ .number = line2, .fill = self.line_digits, });
            } else {
                try self.writer.writeByteNTimes(' ', self.line_digits);
            }

            switch (separator) {
                .arrow => {
                    try self.config.colors.writeLineNumberSeparator(self.colors, self.writer);
                    try self.writer.writeAll("-->");
                    try self.config.colors.writeReset(self.colors, self.writer);
                },
                .ellipsis => {
                    try self.config.colors.writeLineNumberSeparator(self.colors, self.writer);
                    try self.writer.writeAll("...");
                    try self.config.colors.writeReset(self.colors, self.writer);
                },
                .pipe => {
                    try self.writer.writeByte(' ');
                    try self.config.colors.writeLineNumberSeparator(self.colors, self.writer);
                    try self.writer.writeByte('|');
                    try self.config.colors.writeReset(self.colors, self.writer);
                },
                .end => {
                    try self.writer.writeByte(' ');
                    try self.config.colors.writeLineNumberSeparator(self.colors, self.writer);
                    try self.writer.writeByte('=');
                    try self.config.colors.writeReset(self.colors, self.writer);
                    try self.writer.writeByte(' ');
                },
            }
        }
    };
}
