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
    active_annotations: *const std.ArrayListUnmanaged(*const Annotation(FileId))) anyerror!void {
    _ = continuing_annotations;

    var starts_ends = try std.ArrayListUnmanaged(StartEnd).initCapacity(allocator, active_annotations.items.len);
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

             var start_end: StartEnd = undefined;

             if (start_part != null and end_part != null) {
                start_end = StartEnd {
                    .annotation = annotation,
                    .data = StartEndAnnotationData.both(BothAnnotationData {
                        .start = start_part.?,
                        .end = end_part.?,
                    }),
                };
             } else if (start_part) |start_data| {
                start_end = StartEnd {
                    .annotation = annotation,
                    .data = StartEndAnnotationData.start(start_data),
                };
             } else if (end_part) |end_data| {
                 start_end = StartEnd {
                    .annotation = annotation,
                    .data = StartEndAnnotationData.end(end_data),
                };
             } else {
                std.debug.panic("Annotation neither starts nor ends in this line, despite previous check", .{});
             }

            // Insert sorted by line index (ascending) first, then by column index (ascending).
            // For the "both" variant, the start column index is used.
            starts_ends.insertAssumeCapacity(std.sort.upperBound(StartEnd(FileId), start_end, starts_ends.items, void, struct {
                pub fn inner(_: void, a: StartEnd, b: StartEnd) bool {
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
}
