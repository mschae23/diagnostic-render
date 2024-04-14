const std = @import("std");
const io = @import("../io.zig");
const file = @import("../file.zig");
const diag = @import("../diagnostic.zig");
const Diagnostic = diag.Diagnostic;
const Annotation = diag.Annotation;
const ColorConfig = @import("../ColorConfig.zig");

/// Represents a location in a specific source file,
/// using line and column indices.
///
/// Note that these are indices and not user-facing numbers,
/// so they are `0`-indexed.
///
/// It is not necessarily checked that this position exists
/// in the source file.
pub const LineColumn = struct {
    /// The `0`-indexed line index.
    line_index: usize,
    /// The `0`-indexed column index.
    column_index: usize,

    pub fn init(line_index: usize, column_index: usize) LineColumn {
        return LineColumn {
            .line_index = line_index,
            .column_index = column_index,
        };
    }
};

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
            const allocator = diagnostic_allocator.allocator();
            errdefer diagnostic_allocator.deinit();

            while (i < diagnostics.len) : (i += 1) {
                const diagnostic = &diagnostics[i];
                try self2.renderDiagnostic(allocator, diagnostic);

                if (i < diagnostics.len - 1) {
                    try self2.writer.writeByte('\n');
                }

                _ = diagnostic_allocator.reset(.retain_capacity);
            }

            diagnostic_allocator.deinit();
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

                    const line_index = (try self.files.lineIndex(annotation.file_id, annotation.range.end)) orelse return error.FileNotFound;
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
            try self.colors.setColor(self.writer, self.config.colors.getSeverity(diagnostic.severity));
            try self.writer.print("{any}", .{diagnostic.severity});

            if (diagnostic.name) |name| {
                try self.writer.writeByte('[');
                try self.colors.setColor(self.writer, self.config.colors.getName(diagnostic.severity));
                try self.writer.writeAll(name);
                try self.colors.setColor(self.writer, self.config.colors.getSeverity(diagnostic.severity));
                try self.writer.writeByte(']');
            }

            if (diagnostic.message.len != 0) {
                try self.colors.setColor(self.writer, self.config.colors.message);
                try self.writer.print(": {s}\n", .{diagnostic.message});
            }

            try self.colors.setColor(self.writer, self.config.colors.reset);

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
            _ = allocator;
            _ = diagnostic;

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
            try self.colors.setColor(self.writer, self.config.colors.path);
            try self.writer.writeAll(self.files.name(file_id) orelse return error.FileNotFound);

            const user_location = try self.files.location(file_id, location, self.config.tab_length) orelse return error.FileNotFound;

            try self.writer.print(":{d}:{d}\n", .{user_location.line_number, user_location.column_number});
            try self.colors.setColor(self.writer, self.config.colors.reset);
        }

        const LineNumberSeparator = enum {
            arrow,
            pipe,
            end,
        };

        fn writeLineNumber(self: *Self, line: ?usize, separator: LineNumberSeparator) anyerror!void {
            if (line) |line2| {
                try self.colors.setColor(self.writer, self.config.colors.line_number);
                try self.writer.print("{[number]:>[fill]}", .{ .number = line2, .fill = self.line_digits, });
            } else {
                try self.writer.writeByteNTimes(' ', self.line_digits);
            }

            switch (separator) {
                .arrow => {
                    try self.colors.setColor(self.writer, self.config.colors.line_number_separator);
                    try self.writer.writeAll("-->");
                    try self.colors.setColor(self.writer, self.config.colors.reset);
                },
                .pipe => {
                    try self.writer.writeByte(' ');
                    try self.colors.setColor(self.writer, self.config.colors.line_number_separator);
                    try self.writer.writeByte('|');
                    try self.colors.setColor(self.writer, self.config.colors.reset);
                    try self.writer.writeByte(' ');
                },
                .end => {
                    try self.writer.writeByte(' ');
                    try self.colors.setColor(self.writer, self.config.colors.line_number_separator);
                    try self.writer.writeByte('=');
                    try self.colors.setColor(self.writer, self.config.colors.reset);
                    try self.writer.writeByte(' ');
                },
            }
        }
    };
}
