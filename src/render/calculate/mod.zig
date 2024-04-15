const std = @import("std");
const io = @import("../../io.zig");
const file = @import("../../file.zig");
const LineColumn = file.LineColumn;
const diag = @import("../../diagnostic.zig");
const Diagnostic = diag.Diagnostic;
const Annotation = diag.Annotation;

const calculate_data = @import("./data.zig");
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
    };
}

pub const VerticalOffset = struct {
    connection: usize,
    label: usize,
};

pub fn calculate(comptime FileId: type, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId), files: *file.Files(FileId),
    file_id: FileId, line_index: usize, tab_length: usize,
    continuing_annotations: *const std.ArrayListUnmanaged(*const Annotation(FileId)),
    active_annotations: *const std.ArrayListUnmanaged(*const Annotation(FileId))) anyerror!std.ArrayListUnmanaged(std.ArrayListUnmanaged(AnnotationData)) {
    var starts_ends = try std.ArrayListUnmanaged(StartEnd(FileId)).initCapacity(allocator, active_annotations.items.len);
    defer starts_ends.deinit(allocator);

    {
        var i: usize = 0;

        while (i < active_annotations.items.len) : (i += 1) {
            const annotation = active_annotations.items[i];
            const start = try files.lineColumn(file_id, annotation.range.start, .inclusive, tab_length) orelse unreachable;
            const end = try files.lineColumn(file_id, annotation.range.end, .exclusive, tab_length) orelse unreachable;

             // Either start or end has to match line_index
             var start_part: ?StartAnnotationData = null;
             var end_part: ?EndAnnotationData = null;

             if (start.line_index == line_index) {
                start_part = StartAnnotationData {
                    .style = annotation.style,
                    .severity = diagnostic.severity,
                    .location = start,
                };
             }

             if (end.line_index == line_index) {
                end_part = EndAnnotationData {
                    .style = annotation.style,
                    .severity = diagnostic.severity,
                    .location = end,
                };
             }

             var start_end: StartEnd(FileId) = undefined;

             if (start_part != null and end_part != null) {
                start_end = StartEnd(FileId) {
                    .annotation = annotation,
                    .data = StartEndAnnotationData { .both = BothAnnotationData {
                        .start = start_part.?,
                        .end = end_part.?,
                    }},
                };
             } else if (start_part) |start_data| {
                start_end = StartEnd(FileId) {
                    .annotation = annotation,
                    .data = StartEndAnnotationData { .start = start_data },
                };
             } else if (end_part) |end_data| {
                 start_end = StartEnd(FileId) {
                    .annotation = annotation,
                    .data = StartEndAnnotationData { .end = end_data },
                };
             } else {
                std.debug.panic("Annotation neither starts nor ends in this line, despite previous check", .{});
             }

            // Insert sorted by line index (ascending) first, then by column index (ascending).
            // For the "both" variant, the start column index is used.
            starts_ends.insertAssumeCapacity(std.sort.upperBound(StartEnd(FileId), start_end, starts_ends.items, {}, struct {
                pub fn inner(_: void, a: StartEnd(FileId), b: StartEnd(FileId)) bool {
                    const a_start = switch (a.data) {
                        .start => |data| data.location,
                        .end => |data| data.location,
                        .both => |data| data.start.location,
                    };
                    const b_start = switch (b.data) {
                        .start => |data| data.location,
                        .end => |data| data.location,
                        .both => |data| data.start.location,
                    };

                    if (a_start.line_index == b_start.line_index) {
                        return a_start.column_index < b_start.column_index;
                    } else {
                        return a_start.line_index < b_start.line_index;
                    }
                }
             }.inner), start_end);
        }
    }

    var vertical_offsets = try calculateVerticalOffsets(FileId, allocator, starts_ends.items);
    defer vertical_offsets.deinit(allocator);

    return try calculateFinalData(FileId, allocator, diagnostic, files, file_id, line_index, tab_length, &starts_ends, &vertical_offsets, continuing_annotations);
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
        var i: usize = starts_ends.len;

        while (i > 0) {
            i -= 1;

            const start_end = starts_ends[i];
            const annotation = start_end.annotation;
            _ = annotation;

            switch (start_end.data) {
                .start => |data| {
                    _ = data;
                },
                .end => |data| {
                    _ = data;

                    if (next_connection_offset == 0) {
                        // Special case for when this is the ending annotation for the rightmost continuing vertical bar,
                        // but there is another annotation before it.
                        // In this case, all vertical offsets need to be incremented by 1.

                        if (i > 0) {
                            // Another special case: if there are any other annotations before this rightmost ending
                            // annotation, use vertical offset 1 at minimum.
                            next_connection_offset = 1;
                            next_label_offset = 2;
                        }
                    }

                    vertical_offsets.items[i].connection = next_connection_offset;
                    vertical_offsets.items[i].label = next_label_offset;
                    next_connection_offset += 1;
                    next_label_offset += 1;

                    if (next_label_offset == 1) {
                        next_label_offset = 2;
                    }
                },
                .both => |data| {
                    _ = data;
                },
            }
        }
    }

    // Process all other kinds of annotations (single-line and starting).
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
    //    | |          label 3
    //
    // However, if they start *after* one of the ending annotations ends, they cause all preceding ending
    // annotations to get an additional vertical offset for their label:
    //
    // 23 | | | pub fn test(&mut self, arg: i32) -> bool {
    //    | | |        ^                       ^         ^
    //    | | |________|_______________________|_________|
    //    | |__________|                       |         label 1
    //    |  __________|_______________________|
    //    | |          |                       label 2
    //    | |          label 3
    //
    // With multiple starting annotations:
    //
    // 23 | | | pub fn test(&mut self, arg: i32) -> bool {
    //    | | |        ^               ^       ^         ^
    //    | | |________|_______________|_______|_________|
    //    | |__________|               |       |         label 1
    //    |  __________|_______________|_______|
    //    | |  ________|_______________|       label 2
    //    | | |        |               label 3
    //    | | |        label 4
    //
    // However, this just works in a normal way again for preceding single-line annotations:
    //
    // 23 | | pub fn test(&mut self, arg: i32) -> bool {
    //    | |        ^^^^                    ^         ^
    //    | |________|_______________________|_________|
    //    |  ________|_______________________|         label 1
    //    | |        |                       label 2
    //    | |        label 3

    {
        var ending_label_offset: usize = 0;

        var i: usize = starts_ends.len;

        while (i > 0) {
            i -= 1;

            const start_end = starts_ends[i];
            const annotation = start_end.annotation;

            switch (start_end.data) {
                .start => |data| {
                    _ = data;

                    if (next_connection_offset == 0) {
                        // Special case for when there is a rightmost starting annotation,
                        // but there is another annotation before it.
                        // In this case, all vertical offsets need to be incremented by 1.

                        if (i > 0) {
                            // Another special case: if there are any other annotations before this rightmost ending
                            // annotation, use vertical offset 1 at minimum.
                            next_connection_offset = 1;
                            next_label_offset = 2;
                        }
                    }

                    vertical_offsets.items[i].connection = next_connection_offset;
                    vertical_offsets.items[i].label = 0;
                    next_connection_offset += 1;
                    next_label_offset += 1;
                    ending_label_offset += 1;

                    if (next_label_offset == 1) {
                        next_label_offset = 2;
                    }

                    if (ending_label_offset == 1) {
                        ending_label_offset = 2;
                    }
                },
                .end => |data| {
                    _ = data;

                    if (ending_label_offset != 0 and vertical_offsets.items[i].label == 0) {
                        vertical_offsets.items[i].label = ending_label_offset + 1;
                    } else {
                        vertical_offsets.items[i].label += ending_label_offset;
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
                                next_label_offset = 2;
                                break;
                            }
                        }
                    }

                    vertical_offsets.items[i].connection = next_connection_offset;
                    vertical_offsets.items[i].label = next_label_offset;
                    next_connection_offset += 1;
                    next_label_offset += 1;

                    if (next_label_offset == 1) {
                        next_label_offset = 2;
                    }
                },
            }
        }
    }

    return vertical_offsets;
}

pub fn calculateFinalData(comptime FileId: type, allocator: std.mem.Allocator, diagnostic: *const Diagnostic(FileId), files: *file.Files(FileId),
    file_id: FileId, line_index: usize, tab_length: usize,
    starts_ends: *std.ArrayListUnmanaged(StartEnd(FileId)), vertical_offsets: *std.ArrayListUnmanaged(VerticalOffset),
    continuing_annotations: *const std.ArrayListUnmanaged(*const Annotation(FileId))) anyerror!std.ArrayListUnmanaged(std.ArrayListUnmanaged(AnnotationData)) {
    _ = tab_length;

    var final_data = try std.ArrayListUnmanaged(std.ArrayListUnmanaged(AnnotationData)).initCapacity(allocator, 1);

    errdefer {
        for (final_data.items) |*item| {
            item.deinit(allocator);
        }

        final_data.deinit(allocator);
    }

    // How many elements from the start of continuing_annotations to take.
    // Exclusive, the index referred to is not included.
    var continuing_end_index: usize = 0;

    {
        var i: usize = 0;

        while (i < continuing_annotations.items.len) : (i += 1) {
            const start_line_index = try files.lineIndex(file_id, continuing_annotations.items[i].range.start, .inclusive) orelse unreachable;

            // Once we reach a continuing annotation that started on this line,
            // all the ones after it in the vector should start later too, so we can stop here.
            // Keep updating i as the last index to use for the continuing vertical bars on the first line
            // as long as annotations are still from before this line.
            if (start_line_index < line_index) {
                continuing_end_index = i + 1;
            } else if (start_line_index >= line_index) {
                break;
            }
        }
    }

    var current_vertical_offset: usize = 0;
    var continue_next_line: bool = false;
    // starts_ends is usually iterated on in reverse, so this value is used to see how many annotations can already be skipped
    // because they were displayed on previous lines. This is an exclusive end index.
    var annotation_end_index: usize = starts_ends.items.len;

    var additional_continuing_annotations = try std.ArrayListUnmanaged(*const Annotation(FileId)).initCapacity(allocator, 0);
    defer additional_continuing_annotations.deinit(allocator);

    while (true) : (current_vertical_offset += 1) {
        continue_next_line = false;

        var line_data: std.ArrayListUnmanaged(AnnotationData) = try std.ArrayListUnmanaged(AnnotationData).initCapacity(allocator, 0);
        errdefer line_data.deinit(allocator);

        {
            // Add continuing multiline data for annotations starting on previous lines
            try line_data.ensureTotalCapacity(allocator, line_data.items.len + continuing_end_index + additional_continuing_annotations.items.len);
            var i: usize = 0;

            while (i < continuing_end_index) : (i += 1) {
                const annotation = continuing_annotations.items[i];

                line_data.addOneAssumeCapacity().* = AnnotationData { .continuing_multiline = ContinuingMultilineAnnotationData {
                    .style = annotation.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = i,
                }};
            }

            // Add continuing multiline data for annotations starting on this line
            i = 0;

            while (i < additional_continuing_annotations.items.len) : (i += 1) {
                const annotation = starts_ends.items[i].annotation;

                line_data.addOneAssumeCapacity().* = AnnotationData { .continuing_multiline = ContinuingMultilineAnnotationData {
                    .style = annotation.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = continuing_end_index + i,
                }};
            }
        }

        var next_connection_offset_annotation_index: usize = 0;

        {
            // Add connecting multiline data
            var i: usize = annotation_end_index;

            while (i > 0) {
                i -= 1;
                const vertical_offset = vertical_offsets.items[i];

                if (vertical_offset.connection < current_vertical_offset and vertical_offset.label < current_vertical_offset) {
                    annotation_end_index = i;
                    continue;
                }

                if (vertical_offset.connection > current_vertical_offset) {
                    continue_next_line = true;
                    next_connection_offset_annotation_index = i;
                    break;
                }

                if (vertical_offset.connection == current_vertical_offset) {
                    const start_end = starts_ends.items[i];

                    const end_location = switch (start_end.data) {
                        .start => |data| data.location,
                        .end => |data| data.location,
                        .both => continue,
                    };

                    (try line_data.addOne(allocator)).* = AnnotationData { .connecting_multiline = ConnectingMultilineAnnotationData {
                        .style = start_end.annotation.style,
                        .severity = diagnostic.severity,
                        .end_location = end_location,
                        .vertical_bar_index = continuing_end_index + additional_continuing_annotations.items.len,
                    }};

                    break;
                }
            }
        }

        if (current_vertical_offset == 0) {
            // Add start and end data
            const line_data_new_start_index: usize = line_data.items.len;
            var i: usize = 0;

            const CompareAnnotationData = struct {
                pub fn inner(_: void, a: LineColumn, b: AnnotationData) bool {
                    const a_start = a;
                    const b_start = switch (b) {
                        .start => |data| data.location,
                        .end => |data| data.location,
                        .connecting_singleline => |data| LineColumn.init(data.line_index, data.start_column_index),
                        else => unreachable,
                    };

                    if (a_start.line_index == b_start.line_index) {
                        return a_start.column_index < b_start.column_index;
                    } else {
                        return a_start.line_index < b_start.line_index;
                    }
                }
            };

            while (i < starts_ends.items.len) : (i += 1) {
                const start_end = starts_ends.items[i];

                switch (start_end.data) {
                    .start => |data| (try line_data.insert(allocator, line_data_new_start_index + std.sort.upperBound(AnnotationData, data.location, line_data.items[line_data_new_start_index..], {}, CompareAnnotationData.inner),
                        AnnotationData { .start = StartAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.location,
                        }})),
                    .end => |data| (try line_data.insert(allocator, line_data_new_start_index + std.sort.upperBound(AnnotationData, data.location, line_data.items[line_data_new_start_index..], {}, CompareAnnotationData.inner),
                        AnnotationData { .end = EndAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.location,
                        }})),
                    .both => |data| {
                        (try line_data.insert(allocator, line_data_new_start_index + std.sort.upperBound(AnnotationData, data.start.location, line_data.items[line_data_new_start_index..], {}, CompareAnnotationData.inner),
                            AnnotationData { .start = StartAnnotationData {
                                .style = start_end.annotation.style,
                                .severity = diagnostic.severity,
                                .location = data.start.location,
                            }}));
                        (try line_data.insert(allocator, line_data_new_start_index + std.sort.upperBound(AnnotationData, data.start.location, line_data.items[line_data_new_start_index..], {}, CompareAnnotationData.inner),
                            AnnotationData { .connecting_singleline = ConnectingSinglelineAnnotationData {
                                .style = start_end.annotation.style, .as_multiline = false,
                                .severity = diagnostic.severity,
                                .line_index = data.start.location.line_index,
                                .start_column_index = data.start.location.column_index, .end_column_index = data.end.location.column_index,
                            }}));
                        (try line_data.insert(allocator, line_data_new_start_index + std.sort.upperBound(AnnotationData, data.end.location, line_data.items[line_data_new_start_index..], {}, CompareAnnotationData.inner),
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

            while (i < starts_ends.items.len) : (i += 1) {
                const start_end = starts_ends.items[i];
                const vertical_offset = vertical_offsets.items[i];

                if (vertical_offset.connection <= current_vertical_offset and vertical_offset.label <= current_vertical_offset) {
                    continue;
                }

                switch (start_end.data) {
                    .start => |data| (try line_data.addOne(allocator)).* =
                        AnnotationData { .hanging = HangingAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.location,
                        }},
                    .end => |data| (try line_data.addOne(allocator)).* =
                        AnnotationData { .hanging = HangingAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.location,
                        }},
                    .both => |data| (try line_data.addOne(allocator)).* =
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

            while (i < starts_ends.items.len) : (i += 1) {
                const start_end = starts_ends.items[i];
                const vertical_offset = vertical_offsets.items[i];

                if (vertical_offset.label < current_vertical_offset or start_end.annotation.label.len == 0) {
                    continue;
                } else if (vertical_offset.label > current_vertical_offset) {
                    continue_next_line = true;
                    continue;
                }

                switch (start_end.data) {
                    .start => continue,
                    .end => |data| (try line_data.addOne(allocator)).* =
                        AnnotationData { .label = LabelAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.location,
                            .label = start_end.annotation.label,
                        }},
                    .both => |data| (try line_data.addOne(allocator)).* =
                        AnnotationData { .label = LabelAnnotationData {
                            .style = start_end.annotation.style,
                            .severity = diagnostic.severity,
                            .location = data.start.location,
                            .label = start_end.annotation.label,
                        }},
                }

                break;
            }
        }

        // errdefer at the top of this block is allowed to trigger on this try, but not after it
        (try final_data.addOne(allocator)).* = line_data;

        if (!continue_next_line) {
            break;
        }
    }

    return final_data;
}
