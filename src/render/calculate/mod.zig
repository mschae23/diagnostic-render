const std = @import("std");
const io = @import("../../io.zig");
const file = @import("../../file.zig");
const diag = @import("../../diagnostic.zig");
const Diagnostic = diag.Diagnostic;
const Annotation = diag.Annotation;

const calculate_data = @import("./data.zig");
const ContinuingMultilineAnnotationData = calculate_data.ContinuingMultilineAnnotationData;
const ConnectingMultilineAnnotationData = calculate_data.ConnectingMultilineAnnotationData;
const StartAnnotationData = calculate_data.StartAnnotationData;
const ConnectingSinglelineAnnotationData = calculate_data.ConnectingSinglelineAnnotationData;
const EndAnnotationData = calculate_data.EndAnnotationData;
const HangingAnnotationData = calculate_data.HangingAnnotationData;
const LabelAnnotationData = calculate_data.LabelAnnotationData;
const BothAnnotationData = calculate_data.BothAnnotationData;
const StartEndAnnotationData = calculate_data.StartEndAnnotationData;
const AnnotationData = calculate_data.AnnotationData;

fn StartEnd(comptime FileId: type) type {
    return struct {
        annotation: *const Annotation(FileId),
        data: StartEndAnnotationData,
    };
}

const VerticalOffset = struct {
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
            const start = try files.lineColumn(file_id, annotation.range.start, tab_length) orelse unreachable;
            const end = try files.lineColumn(file_id, annotation.range.end, tab_length) orelse unreachable;

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

    var vertical_offsets = try calculateVerticalOffsets(FileId, allocator, &starts_ends);
    defer vertical_offsets.deinit(allocator);

    return try calculateFinalData(FileId, allocator, diagnostic, files, file_id, line_index, tab_length, &starts_ends, &vertical_offsets, continuing_annotations);
}

pub fn calculateVerticalOffsets(comptime FileId: type, allocator: std.mem.Allocator, starts_ends: *std.ArrayListUnmanaged(StartEnd(FileId))) std.mem.Allocator.Error!std.ArrayListUnmanaged(VerticalOffset) {
    var vertical_offsets = try std.ArrayListUnmanaged(VerticalOffset).initCapacity(allocator, starts_ends.items.len);
    errdefer vertical_offsets.deinit(allocator);

    vertical_offsets.items.len = starts_ends.items.len;
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
        var i: usize = starts_ends.items.len;

        while (i > 0) {
            i -= 1;

            const start_end = starts_ends.items[i];
            const annotation = start_end.annotation;
            _ = annotation;

            switch (start_end.data) {
                .start => |data| {
                    _ = data;
                },
                .end => |data| {
                    if (next_connection_offset == 0) {
                        // Special case for when this is the ending annotation for the rightmost continuing vertical bar,
                        // but there is another annotation before it.
                        // In this case, all vertical offsets need to be incremented by 1.
                        //
                        // Iterate through starts_ends again (same order, in reverse).
                        // The last one has to be skipped, as that is definitely this one
                        // and will make the condition always match.

                        var j = starts_ends.items.len - 1; // should be len, but we have to skip the last element

                        if (j > 0) {
                            // Another special case: if there are any other annotations before this rightmost ending
                            // annotation, use vertiacl offset 1 at minimum.
                            next_connection_offset = 1;
                            next_label_offset = 2;
                        }

                        while (j > 0) {
                            j -= 1;

                            const start = switch (starts_ends.items[j].data) {
                                // If one of these starts before this ending annotation,
                                // increase vertical_offset by 1 for all annotations
                                .start => |data2| data2.location.column_index,
                                .end => |data2| data2.location.column_index,
                                .both => |data2| data2.start.location.column_index,
                            };

                            if (start <= data.location.column_index) {
                                next_connection_offset += 1;
                                next_label_offset += 1;
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

        var i: usize = starts_ends.items.len;

        while (i > 0) {
            i -= 1;

            const start_end = starts_ends.items[i];
            const annotation = start_end.annotation;

            switch (start_end.data) {
                .start => |data| {
                    if (next_connection_offset == 0) {
                        // Special case for when there is a rightmost starting annotation,
                        // but another one ends after that one starts.
                        // In this case, all vertical offsets need to be incremented by 1.
                        //
                        // Iterate through starts_ends again (same order, in reverse).
                        // The last one has to be skipped, as that is definitely this one
                        // and will make the condition always match.

                        var j = starts_ends.items.len - 1; // should be len, but we have to skip the last element

                        while (j > 0) {
                            j -= 1;

                            const end = switch (starts_ends.items[j].data) {
                                // If one of these ends after the rightmost starting annotation,
                                // set vertical_offset to 1 for all annotations
                                .start => |data2| data2.location.column_index,
                                .end => |data2| data2.location.column_index,
                                .both => |data2| data2.end.location.column_index,
                            };

                            if (end >= data.location.column_index) {
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
                    vertical_offsets.items[i].label += ending_label_offset;
                },
                .both => |data| {
                    if (annotation.label.len == 0) {
                        // A single-line annotation without a label doesn't take space.

                        if (i == starts_ends.items.len - 1) {
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

                        var j = starts_ends.items.len - 1; // should be len, but we have to skip the last element

                        while (j > 0) {
                            j -= 1;

                            const end = switch (starts_ends.items[j].data) {
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
    _ = diagnostic;
    _ = files;
    _ = file_id;
    _ = line_index;
    _ = tab_length;
    _ = starts_ends;
    _ = vertical_offsets;
    _ = continuing_annotations;

    const final_data = try std.ArrayListUnmanaged(std.ArrayListUnmanaged(AnnotationData)).initCapacity(allocator, 1);
    return final_data;
}
