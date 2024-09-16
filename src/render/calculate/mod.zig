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
const io = @import("../../io.zig");
const file = @import("../../file.zig");
const LineColumn = file.LineColumn;
const diag = @import("../../diagnostic.zig");
const Diagnostic = diag.Diagnostic;
const Annotation = diag.Annotation;

const calculate_data = @import("./data.zig");
pub const LocatedAnnotation = calculate_data.LocatedAnnotation;
pub const ContinuingMultilineAnnotationData = calculate_data.ContinuingMultilineAnnotationData;
pub const ConnectingMultilineAnnotationData = calculate_data.ConnectingMultilineAnnotationData;
pub const StartAnnotationData = calculate_data.StartAnnotationData;
pub const ConnectingSinglelineAnnotationData = calculate_data.ConnectingSinglelineAnnotationData;
pub const EndAnnotationData = calculate_data.EndAnnotationData;
pub const HangingAnnotationData = calculate_data.HangingAnnotationData;
pub const LabelAnnotationData = calculate_data.LabelAnnotationData;
pub const BothAnnotationData = calculate_data.BothAnnotationData;
pub const StartEndAnnotationData = calculate_data.StartEndAnnotationData;
pub const AnnotationData = calculate_data.AnnotationData;

pub fn StartEnd(comptime FileId: type) type {
    return struct {
        annotation: *const Annotation(FileId),
        data: StartEndAnnotationData,
        vertical_bar_index: ?usize,
    };
}

pub const VerticalOffset = struct {
    connection: usize,
    label: usize,
};

pub fn calculate(comptime FileId: type, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId),
    line_index: usize,
    continuing_annotations: []const ?*const Annotation(FileId),
    active_annotations: []const LocatedAnnotation(FileId)) anyerror!std.ArrayListUnmanaged(AnnotationData) {
    var starts_ends = try std.ArrayListUnmanaged(StartEnd(FileId)).initCapacity(allocator, active_annotations.len);
    defer starts_ends.deinit(allocator);

    {
        var i: usize = 0;

        while (i < active_annotations.len) : (i += 1) {
            const annotation = active_annotations[i];
            const start = annotation.start_location;
            const end = annotation.end_location;

             // Either start or end has to match line_index
             var start_part: ?StartAnnotationData = null;
             var end_part: ?EndAnnotationData = null;

             if (start.line_index == line_index) {
                start_part = StartAnnotationData {
                    .style = annotation.annotation.style,
                    .severity = diagnostic.severity,
                    .location = start,
                };
             }

             if (end.line_index == line_index) {
                end_part = EndAnnotationData {
                    .style = annotation.annotation.style,
                    .severity = diagnostic.severity,
                    .location = end,
                };
             }

             var start_end: StartEnd(FileId) = undefined;

             if (start_part != null and end_part != null) {
                start_end = StartEnd(FileId) {
                    .annotation = annotation.annotation,
                    .data = StartEndAnnotationData { .both = BothAnnotationData {
                        .start = start_part.?,
                        .end = end_part.?,
                    }},
                    .vertical_bar_index = annotation.vertical_bar_index,
                };
             } else if (start_part) |start_data| {
                start_end = StartEnd(FileId) {
                    .annotation = annotation.annotation,
                    .data = StartEndAnnotationData { .start = start_data },
                    .vertical_bar_index = annotation.vertical_bar_index,
                };
             } else if (end_part) |end_data| {
                 start_end = StartEnd(FileId) {
                    .annotation = annotation.annotation,
                    .data = StartEndAnnotationData { .end = end_data },
                    .vertical_bar_index = annotation.vertical_bar_index,
                };
             } else {
                std.debug.panic("Annotation neither starts nor ends in this line, despite previous check", .{});
             }

            // Insert sorted by column index (ascending). Line indices are ignored, since starts_ends items are
            // assumed to always be on the same line (the current line index).
            // For the "both" variant, the start column index is used.
            starts_ends.insertAssumeCapacity(std.sort.upperBound(StartEnd(FileId), starts_ends.items, start_end, struct {
                pub fn inner(context: StartEnd(FileId), lhs: StartEnd(FileId)) std.math.Order {
                    const a_start = switch (lhs.data) {
                        .start => |data| data.location,
                        .end => |data| data.location,
                        .both => |data| data.start.location,
                    };
                    const b_start = switch (context.data) {
                        .start => |data| data.location,
                        .end => |data| data.location,
                        .both => |data| data.start.location,
                    };

                    return std.math.order(a_start.column_index, b_start.column_index);
                }
             }.inner), start_end);
        }
    }

    var vertical_offsets = try calculateVerticalOffsets(FileId, allocator, starts_ends.items);
    defer vertical_offsets.deinit(allocator);

    return try calculateFinalData(FileId, allocator, diagnostic, starts_ends.items, vertical_offsets.items, continuing_annotations);
}

pub fn calculateVerticalOffsets(comptime FileId: type, allocator: std.mem.Allocator, starts_ends: []const StartEnd(FileId)) std.mem.Allocator.Error!std.ArrayListUnmanaged(VerticalOffset) {
    var vertical_offsets = try std.ArrayListUnmanaged(VerticalOffset).initCapacity(allocator, starts_ends.len);
    errdefer vertical_offsets.deinit(allocator);

    vertical_offsets.items.len = starts_ends.len;
    @memset(vertical_offsets.items, VerticalOffset { .connection = 0, .label = 0, });

    var next_connection_offset: usize = 0;
    var next_label_offset: usize = 0;

    // Process the annotations ending on this line.
    //
    // Iterates through all multi-line annotations ending on this line in
    // descending start byte index order, to be able to assign lower vertical offsets
    // to the continuing vertical bars that are more on the right, to avoid intersecting lines.
    //
    // === Examples ===
    // Here, there is only a single ending annotation:
    //
    // 23 | | pub fn test(&mut self, arg: i32) -> bool {
    //    | |_____________^ label
    //
    // Multiple ending annotations get incrementing vertical offsets for descending start byte indices:
    //
    // 23 | | | | pub fn test(&mut self, arg: i32) -> bool {
    //    | | | |        ^                       ^         ^
    //    | | | |________|_______________________|_________|
    //    | | |__________|_______________________|         label 1
    //    | |____________|                       label 2
    //    |              label 3
    {
        const EndingData = struct {
            start_byte_index: usize,
            annotation_index: usize,
        };

        // Create a list of ending annotations sorted by start byte index (ascending).
        var ending_annotation_indices = try std.ArrayListUnmanaged(EndingData).initCapacity(allocator, 0);
        defer ending_annotation_indices.deinit(allocator);

        var i: usize = 0;

        while (i < starts_ends.len) : (i += 1) {
            const start_end = starts_ends[i];

            switch (start_end.data) {
                .start => continue,
                .end => {
                    try ending_annotation_indices.insert(allocator, std.sort.upperBound(EndingData, ending_annotation_indices.items, start_end.annotation.range.start, struct {
                        pub fn inner(context: usize, lhs: EndingData) std.math.Order {
                            return std.math.order(lhs.start_byte_index, context);
                        }
                    }.inner), EndingData { .start_byte_index = start_end.annotation.range.start, .annotation_index = i, });
                },
                .both => continue,
            }
        }

        // Iterate through the list of ending annotations in reverse to set the vertical_offset.connection values.
        // That means this effectively iterates through the list of ending annotations in descending start byte index order.
        i = ending_annotation_indices.items.len;

        while (i > 0) {
            i -= 1;

            const ending_data = ending_annotation_indices.items[i];
            const j = ending_data.annotation_index;
            const start_end = starts_ends[j];
            const annotation = start_end.annotation;
            _ = annotation;

            if (next_connection_offset == 0 and j > 0) {
                // Special case: if there are any other annotations before this ending
                // annotation, use vertical offset 1 at minimum.
                next_connection_offset = 1;
            }

            vertical_offsets.items[j].connection = next_connection_offset;
            next_connection_offset += 1;
        }

        // Iterate through ending annotations again, this time in descending end byte index order, to set
        // the label offsets.
        i = starts_ends.len;

        while (i > 0) {
            i -= 1;

            const start_end = starts_ends[i];
            var vertical_offset = &vertical_offsets.items[i];

            switch (start_end.data) {
                .start => continue,
                .end => if (start_end.annotation.label.len != 0) {
                    vertical_offset.label = @max(if (vertical_offset.connection == 0) 0 else vertical_offset.connection + 1, next_label_offset);
                    next_label_offset = vertical_offset.label + std.mem.count(u8, std.mem.trim(u8, start_end.annotation.label, &.{'\n'}), "\n") + 1;

                    if (next_label_offset == 1) {
                        next_label_offset = 2;
                    }
                },
                .both => continue,
            }
        }
    }

    // Process the annotations starting on this line.
    //
    // Iterates through all multi-line annotations starting on this line in
    // ascending start byte index order, to be able to assign lower vertical offsets
    // to the continuing vertical bars that are more on the right, to avoid intersecting lines.
    //
    // === Examples ===
    // Here, there is only a single starting annotation:
    //
    // 23 |   pub fn test(&mut self, arg: i32) -> bool {
    //    |  _____________^
    //    | |
    //
    // Multiple ending annotations get incrementing vertical offsets for ascending start byte indices:
    //
    // 23 |       pub fn test(&mut self, arg: i32) -> bool {
    //    |  ____________^                       ^         ^
    //    | |  __________________________________|         |
    //    | | |  __________________________________________|
    //    | | | |
    //
    // Behaviour when interacting with ending and single-line annotations:
    //
    // 23 | | pub fn test(&mut self, arg: i32) -> bool {
    //    | |     ^  ^^^^                    ^         ^
    //    | |_____|__|_________________________________|
    //    |  _____|  |                                 label 1
    //    | |        label 3
    //
    // 23 |     pub fn test(&mut self, arg: i32) -> bool {
    //    |  __________^               --------          ^
    //    | |  ________________________|_________________|
    //    | | |                        |
    //    | | |                        label 1
    {
        var i: usize = 0;
        var first: bool = true;

        while (i < starts_ends.len) : (i += 1) {
            const start_end = starts_ends[i];
            const annotation = start_end.annotation;
            _ = annotation;

            switch (start_end.data) {
                .start => |data| {
                    _ = data;

                    if (!first and next_connection_offset == 0) {
                        next_connection_offset = 1;
                        next_label_offset = 2;
                    }

                    first = false;
                    vertical_offsets.items[i].connection = next_connection_offset;
                    vertical_offsets.items[i].label = 0;
                    next_connection_offset += 1;
                    next_label_offset = @max(vertical_offsets.items[i].connection + 2, next_label_offset);
                },
                .end => |data| {
                    _ = data;
                    first = false;
                },
                .both => |data| {
                    _ = data;
                    first = false;
                },
            }
        }
    }

    // Process all kinds of annotations again, but especially single-line.
    //
    // The start / end data vector is iterated in reverse and every annotation is given incrementing
    // vertical offsets.
    // This means that the rightmost annotations (by start column index) are given lower offsets
    // than ones that come before them on the line.
    //
    // === Examples ===
    // Here, the annotations are not overlapping. You can see that they are assigned their
    // vertical offset from right to left.
    //
    // 23 | pub fn example_function(&mut self, argument: usize) -> usize {
    //    |                         ---------  --------            ----- return type
    //    |                         |          |
    //    |                         |          a parameter
    //    |                         self parameter
    //
    // Here, there are two overlapping annotations. They are still assigned their vertical
    // offset from right to left.
    //
    // 23 | pub fn example_function(&mut self, argument: usize) -> usize {
    //    |                        ------------^^^^^^^^^^^^^^^-
    //    |                        |           |
    //    |                        |           a parameter
    //    |                        the parameter list
    //
    // === Starting annotations ===
    // Annotations starting on this line interact weirdly with ending annotations.
    //
    // If they start on a lower column index than the ending annotations end, they behave normally,
    // simply taking the next vertical offset:
    //
    // 23 | | | pub fn test(&mut self, arg: i32) -> bool {
    //    | | |        ^                       ^         ^
    //    | | |________|_______________________|_________|
    //    | |__________|_______________________|         label 1
    //    |  __________|                       label 2
    //    | |
    //
    // However, if they start *after* one of the ending annotations ends, they cause all preceding ending
    // annotations to get an additional vertical offset for their label:
    //
    // 23 | | | pub fn test(&mut self, arg: i32) -> bool {
    //    | | |        ^                       ^         ^
    //    | | |________|_______________________|_________|
    //    | |__________|                       |         label 1
    //    |  __________|_______________________|
    //    | |          |
    //    | |          label 2
    //
    // With multiple starting annotations:
    //
    // 23 | | | pub fn test(&mut self, arg: i32) -> bool {
    //    | | |        ^               ^       ^         ^
    //    | | |________|_______________|_______|_________|
    //    | |__________|               |       |         label 1
    //    |  __________|_______________|       |
    //    | |  ________|_______________________|
    //    | | |        |
    //    | | |        label 2
    //
    // However, this just works in a normal way again for preceding single-line annotations:
    //
    // 23 | | pub fn test(&mut self, arg: i32) -> bool {
    //    | |        ^^^^                    ^         ^
    //    | |________|_______________________|_________|
    //    |  ________|_______________________|         label 1
    //    | |        |
    //    | |        label 3

    {
        var minimum_label_offset: usize = 0;

        var i: usize = starts_ends.len;

        while (i > 0) {
            i -= 1;

            const start_end = starts_ends[i];
            const annotation = start_end.annotation;

            switch (start_end.data) {
                .start => |data| {
                    _ = data;

                    minimum_label_offset += 1;

                    if (minimum_label_offset == 1) {
                        minimum_label_offset = 3;
                    }
                },
                .end => |data| {
                    _ = data;

                    if (start_end.annotation.label.len != 0) {
                        // There need to be more tests affected by this, since
                        // changing how this works often doesn't seem to break much.
                        if (minimum_label_offset != 0 and vertical_offsets.items[i].label == 0) {
                            vertical_offsets.items[i].label = minimum_label_offset;
                        } else {
                            vertical_offsets.items[i].label = @max(vertical_offsets.items[i].label, minimum_label_offset);
                        }

                        minimum_label_offset = vertical_offsets.items[i].label + 1 + std.mem.count(u8, std.mem.trim(u8, start_end.annotation.label, &.{'\n'}), "\n");
                        // Singleline annotations don't take minimum_label_offset into account, so just set next_label_offset to the current minimum
                        next_label_offset = minimum_label_offset;
                    }
                },
                .both => |data| {
                    if (annotation.label.len == 0) {
                        // A single-line annotation without a label doesn't take space.

                        if (i == starts_ends.len - 1) {
                            // Except if it's the rightmost one, in which case the next annotation
                            // can still use a connection line on vertical offset 0, but has to display its
                            // label on at least vertical offset 2.
                            next_label_offset += 2;
                            minimum_label_offset = @max(minimum_label_offset, 2);
                        }

                        continue;
                    }

                    if (next_connection_offset == 0) {
                        // Special case for when there is a rightmost single-line annotation,
                        // but another one ends after that one starts.
                        // In this case, all vertical offsets need to be incremented by 1.
                        //
                        // Iterate through starts_ends again (same order, in reverse).
                        // The last one has to be skipped, as that is definitely this one
                        // and will make the condition always match.

                        var j = starts_ends.len - 1; // should be len, but we have to skip the last element

                        while (j > 0) {
                            j -= 1;

                            const end = switch (starts_ends[j].data) {
                                // If one of these ends after the rightmost single-line annotation,
                                // increase vertical_offset by 1 for all annotations
                                .start => |data2| data2.location.column_index,
                                .end => |data2| data2.location.column_index,
                                .both => |data2| data2.end.location.column_index,
                            };

                            if (end >= data.start.location.column_index) {
                                next_connection_offset = 1;
                                next_label_offset = @max(2, next_label_offset);
                                break;
                            }
                        }
                    }

                    if (i == starts_ends.len - 1) {
                        var last = true;
                        var j: usize = 0;

                        while (j < starts_ends.len) : (j += 1) {
                            if (i == j) {
                                continue;
                            }

                            switch (starts_ends[j].data) {
                                .start => |data2| if (data2.location.column_index >= data.start.location.column_index) {
                                    last = false;
                                    break;
                                },
                                .end => |data2| if (data2.location.column_index >= data.start.location.column_index) {
                                    last = false;
                                    break;
                                },
                                .both => |data2| if (data2.end.location.column_index >= data.start.location.column_index) {
                                    last = false;
                                    break;
                                },
                            }
                        }

                        if (last) {
                            vertical_offsets.items[i].connection = 0;
                            vertical_offsets.items[i].label = 0;

                            next_connection_offset = @max(next_connection_offset, 1);
                            const lines = 1 + std.mem.count(u8, std.mem.trim(u8, start_end.annotation.label, &.{'\n'}), "\n");
                            next_label_offset = @max(next_label_offset, @max(2, lines));
                            minimum_label_offset = @max(minimum_label_offset, @max(2, lines));
                            continue;
                        }
                    }

                    vertical_offsets.items[i].connection = next_connection_offset;
                    vertical_offsets.items[i].label = next_label_offset;

                    next_connection_offset += 1;
                    next_label_offset += 1 + std.mem.count(u8, std.mem.trim(u8, start_end.annotation.label, &.{'\n'}), "\n");

                    if (next_label_offset == 1) {
                        next_label_offset = 2;
                    }

                    minimum_label_offset = @max(minimum_label_offset, next_label_offset);
                },
            }
        }
    }

    return vertical_offsets;
}

pub fn calculateFinalData(comptime FileId: type, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId),
    starts_ends: []const StartEnd(FileId), vertical_offsets: []const VerticalOffset,
    continuing_annotations: []const ?*const Annotation(FileId)) anyerror!std.ArrayListUnmanaged(AnnotationData) {
    // std.debug.print("[debug] Vertical offsets: {any}\n", .{vertical_offsets});

    var final_data = try std.ArrayListUnmanaged(AnnotationData).initCapacity(allocator, 0);

    errdefer final_data.deinit(allocator);

    var current_vertical_offset: usize = 0;
    var continue_next_line: bool = false;

    const RestLabel = struct {
        style: diag.AnnotationStyle,
        severity: diag.Severity,
        location: LineColumn,
        label: []const u8,
    };

    var rest_label: ?RestLabel = null;

    var active_continuing_annotations = try std.bit_set.DynamicBitSetUnmanaged.initFull(allocator, continuing_annotations.len);
    defer active_continuing_annotations.deinit(allocator);

    var additional_continuing_annotations = try std.ArrayListUnmanaged(*const Annotation(FileId)).initCapacity(allocator, 0);
    defer additional_continuing_annotations.deinit(allocator);

    while (true) : (current_vertical_offset += 1) {
        continue_next_line = false;

        {
            const connecting_annotation: ?*const StartEnd(FileId) = connect: {
                var i: usize = 0;

                while (i < starts_ends.len) : (i += 1) {
                    const vertical_offset = vertical_offsets[i];

                    if (vertical_offset.connection > current_vertical_offset) {
                        continue_next_line = true;
                        continue;
                    }

                    if (vertical_offset.connection == current_vertical_offset) {
                        const start_end = &starts_ends[i];

                        if (start_end.data == .both) {
                            continue;
                        }

                        break :connect start_end;
                    }
                }

                break :connect null;
            };

            // Add continuing multiline data for annotations starting on previous lines
            try final_data.ensureTotalCapacity(allocator, final_data.items.len + continuing_annotations.len + additional_continuing_annotations.items.len);
            var i: usize = 0;
            var continuing_end_index: usize = 0;

            while (i < continuing_annotations.len) : (i += 1) {
                if (active_continuing_annotations.isSet(i)) {
                    const a = continuing_annotations[i];

                    if (a) |annotation| {
                        final_data.addOneAssumeCapacity().* = AnnotationData { .continuing_multiline = ContinuingMultilineAnnotationData {
                            .style = annotation.style,
                            .severity = diagnostic.severity,
                            .vertical_bar_index = i,
                        }};
                        continuing_end_index = i + 1;

                        if (connecting_annotation) |b| {
                            if (b.vertical_bar_index.? == i) {
                                // Add connecting multiline annotation data
                                const end_location = switch (b.data) {
                                    .start => unreachable,
                                    .end => |data| data.location,
                                    .both => unreachable,
                                };

                                (try final_data.addOne(allocator)).* = AnnotationData { .connecting_multiline = ConnectingMultilineAnnotationData {
                                    .style = b.annotation.style,
                                    .severity = diagnostic.severity,
                                    .end_location = end_location,
                                    .vertical_bar_index = b.vertical_bar_index.?,
                                }};
                                active_continuing_annotations.unset(b.vertical_bar_index.?);
                            }
                }
                    }
                }
            }

            // Add continuing multiline data for annotations starting on this line
            i = 0;

            while (i < additional_continuing_annotations.items.len) : (i += 1) {
                const annotation = additional_continuing_annotations.items[i];

                final_data.addOneAssumeCapacity().* = AnnotationData { .continuing_multiline = ContinuingMultilineAnnotationData {
                    .style = annotation.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = continuing_end_index + i,
                }};
            }

            // Add additional continuing annotation for annotation connecting on this line
            i = 0;

            while (i < starts_ends.len) : (i += 1) {
                const vertical_offset = vertical_offsets[i];

                if (vertical_offset.connection < current_vertical_offset) {
                    continue;
                }

                if (vertical_offset.connection > current_vertical_offset) {
                    continue_next_line = true;
                    continue;
                }

                if (vertical_offset.connection == current_vertical_offset) {
                    const start_end = starts_ends[i];

                    if (start_end.data != .start) {
                        continue;
                    }

                    (try additional_continuing_annotations.addOne(allocator)).* = start_end.annotation;

                    if (connecting_annotation) |b| {
                        if (b.vertical_bar_index.? == start_end.vertical_bar_index.?) {
                            // Add connecting multiline annotation data
                            const end_location = switch (b.data) {
                                .start => |data| data.location,
                                .end => unreachable,
                                .both => unreachable,
                            };

                            (try final_data.addOne(allocator)).* = AnnotationData { .connecting_multiline = ConnectingMultilineAnnotationData {
                                .style = b.annotation.style,
                                .severity = diagnostic.severity,
                                .end_location = end_location,
                                .vertical_bar_index = b.vertical_bar_index.?,
                            }};
                        }
                    }

                    break;
                }
            }
        }

        if (current_vertical_offset == 0) {
            // Add start and end data
            const line_data_new_start_index: usize = final_data.items.len;
            var i: usize = 0;

            const AnnotationDataCompare = struct {
                pub fn inner(context: LineColumn, lhs: AnnotationData) std.math.Order {
                    const a_start = switch (lhs) {
                        .start => |data| data.location,
                        .end => |data| data.location,
                        .connecting_singleline => |data| LineColumn.init(data.line_index, data.start_column_index),
                        else => unreachable,
                    };
                    const b_start = context;

                    if (a_start.line_index == b_start.line_index) {
                        return std.math.order(a_start.column_index, b_start.column_index);
                    } else {
                        return std.math.order(a_start.line_index, b_start.line_index);
                    }
                }
            };

            while (i < starts_ends.len) : (i += 1) {
                const start_end = starts_ends[i];
                const vertical_offset = vertical_offsets[i];

                if (vertical_offset.connection > current_vertical_offset or vertical_offset.label > current_vertical_offset) {
                    continue_next_line = true;
                }

                switch (start_end.data) {
                    .start => |data| (try final_data.insert(allocator, line_data_new_start_index + std.sort.lowerBound(AnnotationData, final_data.items[line_data_new_start_index..], data.location, AnnotationDataCompare.inner),
                        AnnotationData { .start = StartAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.location,
                        }})),
                    .end => |data| (try final_data.insert(allocator, line_data_new_start_index + std.sort.lowerBound(AnnotationData, final_data.items[line_data_new_start_index..], data.location, AnnotationDataCompare.inner),
                        AnnotationData { .end = EndAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.location,
                        }})),
                    .both => |data| {
                        (try final_data.insert(allocator, line_data_new_start_index + std.sort.lowerBound(AnnotationData, final_data.items[line_data_new_start_index..], data.start.location, AnnotationDataCompare.inner),
                            AnnotationData { .start = StartAnnotationData {
                                .style = start_end.annotation.style,
                                .severity = diagnostic.severity,
                                .location = data.start.location,
                            }}));
                        (try final_data.insert(allocator, line_data_new_start_index + std.sort.upperBound(AnnotationData, final_data.items[line_data_new_start_index..], data.start.location, AnnotationDataCompare.inner),
                            AnnotationData { .connecting_singleline = ConnectingSinglelineAnnotationData {
                                .style = start_end.annotation.style, .as_multiline = false,
                                .severity = diagnostic.severity,
                                .line_index = data.start.location.line_index,
                                .start_column_index = data.start.location.column_index, .end_column_index = data.end.location.column_index,
                            }}));
                        (try final_data.insert(allocator, line_data_new_start_index + std.sort.upperBound(AnnotationData, final_data.items[line_data_new_start_index..], data.end.location, AnnotationDataCompare.inner),
                            AnnotationData { .end = EndAnnotationData {
                                .style = start_end.annotation.style,
                                .severity = diagnostic.severity,
                                .location = data.end.location,
                            }}));
                    },
                }
            }
        } else {
            // Add hanging data
            var i: usize = 0;

            while (i < starts_ends.len) : (i += 1) {
                const start_end = starts_ends[i];
                const vertical_offset = vertical_offsets[i];

                if (vertical_offset.connection < current_vertical_offset and vertical_offset.label <= current_vertical_offset) {
                    continue;
                } else if (vertical_offset.connection > current_vertical_offset) {
                    continue_next_line = true;
                }

                switch (start_end.data) {
                    .start => |data| (try final_data.addOne(allocator)).* =
                        AnnotationData { .hanging = HangingAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.location,
                        }},
                    .end => |data| (try final_data.addOne(allocator)).* =
                        AnnotationData { .hanging = HangingAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.location,
                        }},
                    .both => |data| (try final_data.addOne(allocator)).* =
                        AnnotationData { .hanging = HangingAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.start.location,
                        }},
                }
            }
        }

        {
            // Add label data
            var i: usize = 0;
            var found = false;

            while (i < starts_ends.len) : (i += 1) {
                const start_end = starts_ends[i];
                const vertical_offset = vertical_offsets[i];

                if (vertical_offset.label < current_vertical_offset or start_end.annotation.label.len == 0) {
                    continue;
                } else if (vertical_offset.label > current_vertical_offset) {
                    continue_next_line = true;
                    continue;
                }

                const location = switch (start_end.data) {
                    .start => continue,
                    .end => |data| if (vertical_offset.label == 0) LineColumn.init(data.location.line_index, data.location.column_index + 2) else data.location,
                    .both => |data| if (vertical_offset.label == 0) LineColumn.init(data.end.location.line_index, data.end.location.column_index + 2) else data.start.location,
                };

                var label = std.mem.trim(u8, start_end.annotation.label, &.{'\n'});
                const first_line_end = std.mem.indexOfScalar(u8, label, '\n');

                if (first_line_end) |end| {
                    rest_label = RestLabel {
                        .style = start_end.annotation.style,
                        .severity = diagnostic.severity,
                        .location = location,
                        .label = label[end + 1..],
                    };
                    label = label[0..end];
                    continue_next_line = true;
                }

                (try final_data.addOne(allocator)).* = AnnotationData { .label = .{
                    .style = start_end.annotation.style,
                    .severity = diagnostic.severity,
                    .location = location,
                    .label = label,
                }};

                if (first_line_end == null) {
                    rest_label = null;
                }

                found = true;
                break;
            }

            if (!found) {
                if (rest_label) |*data| {
                    var label = data.label;
                    const line_end = std.mem.indexOfScalar(u8, label, '\n');

                    if (line_end) |end| {
                        data.label = label[end + 1..];
                        label = label[0..end];
                        continue_next_line = true;
                    }

                    (try final_data.addOne(allocator)).* = AnnotationData { .label = .{
                        .style = data.style,
                        .severity = data.severity,
                        .location = data.location,
                        .label = label,
                    }};

                    if (line_end == null) {
                        rest_label = null;
                    }
                }
            }
        }

        (try final_data.addOne(allocator)).* = AnnotationData.newline;

        if (!continue_next_line) {
            break;
        }
    }

    return final_data;
}
