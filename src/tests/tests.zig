const std = @import("std");
const io = @import("../io.zig");
const file = @import("../file.zig");
const LineColumn = file.LineColumn;
const diag = @import("../diagnostic.zig");
const Annotation = diag.Annotation(usize);
const Diagnostic = diag.Diagnostic(usize);
const Span = diag.Span;
const ColorConfig = @import("../ColorConfig.zig");
const render = @import("../render/mod.zig");

const calculate = @import("../render/calculate/mod.zig");
const ContinuingMultilineAnnotationData = calculate.ContinuingMultilineAnnotationData;
const ConnectingMultilineAnnotationData = calculate.ConnectingMultilineAnnotationData;
const StartAnnotationData = calculate.StartAnnotationData;
const ConnectingSinglelineAnnotationData = calculate.ConnectingSinglelineAnnotationData;
const EndAnnotationData = calculate.EndAnnotationData;
const HangingAnnotationData = calculate.HangingAnnotationData;
const LabelAnnotationData = calculate.LabelAnnotationData;
const BothAnnotationData = calculate.BothAnnotationData;
const StartEndAnnotationData = calculate.StartEndAnnotationData;
const AnnotationData = calculate.AnnotationData;
const StartEnd = calculate.StartEnd(usize);
const VerticalOffset = calculate.VerticalOffset;

test "Development" {
    var fbs = std.io.fixedBufferStream(
        \\pub fn tést(&mut self, arg: i32) -> bool {
        \\    return self.counter + arg > 7;
        \\}
    );

    var file_hashmap = std.AutoHashMap(usize, file.FileData).init(std.testing.allocator);
    try file_hashmap.put(0, file.FileData {
        .name = "src/test.rs",
        .reader = fbs.reader().any(),
        .seeker = io.anySeekableStream(@TypeOf(fbs), *@TypeOf(fbs), &&fbs),
    });
    defer file_hashmap.deinit();

    const files = try file.Files(usize).init(std.testing.allocator, &file_hashmap);

    const diagnostics = .{
        diag.Diagnostic(usize).err().with_name("thing/test").with_message("Test").with_annotations(&.{
            diag.Annotation(usize).primary(0, diag.Span.init(12, 44 + 35 + 2)).with_label("Annotation")
        })
    };

    const output = std.io.getStdErr();
    try output.writer().writeByte('\n');

    var renderer = render.DiagnosticRenderer(usize).init(std.testing.allocator, output.writer().any(), std.io.tty.detectConfig(output), files, .{});
    try renderer.render(&diagnostics);
}

fn runTest(input: []const u8, diagnostic: *const Diagnostic, line_index: usize, continuing_annotations: []const *const Annotation, active_annotations: []const *const Annotation, expected: []const AnnotationData) !void {
    var fbs = std.io.fixedBufferStream(input);

    var file_hashmap = std.AutoHashMap(usize, file.FileData).init(std.testing.allocator);
    try file_hashmap.put(0, file.FileData {
        .name = "/tmp/test",
        .reader = fbs.reader().any(),
        .seeker = io.anySeekableStream(@TypeOf(fbs), *@TypeOf(fbs), &&fbs),
    });
    defer file_hashmap.deinit();

    var files = try file.Files(usize).init(std.testing.allocator, &file_hashmap);
    defer files.deinit();

    var actual = try calculate.calculate(usize, std.testing.allocator, diagnostic, &files, 0, line_index, 4, continuing_annotations, active_annotations);
    defer actual.deinit(std.testing.allocator);

    try std.testing.expectEqualSlices(AnnotationData, expected, actual.items);
}

pub const singleline = struct {
    test "1" {
        const input = "test file contents";

        const annotation = Annotation.primary(0, Span.init(5, 9)).with_label("test label");
        const diagnostic = Diagnostic.err().with_annotations(&.{annotation});

        // 1 | test file contents
        //   |      ^^^^ test label

        try runTest(input, &diagnostic, 0, &.{}, &.{&annotation}, &.{
            AnnotationData { .start = .{
                .style = annotation.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 5),
            }},
            AnnotationData { .connecting_singleline = .{
                .style = annotation.style, .as_multiline = false,
                .severity = diagnostic.severity,
                .line_index = 0,
                .start_column_index = 5, .end_column_index = 9,
            }},
            AnnotationData { .end = .{
                .style = annotation.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 9),
            }},
            AnnotationData { .label = .{
                .style = annotation.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 5),
                .label = "test label",
            }},
            AnnotationData.newline,
        });
    }

    test "separate lines 1" {
        const input =
            \\let main = 23;
            \\something += 3.0;
            \\print(example_source);
        ++ "\n";

        const annotation1 = Annotation.primary(0, Span.init(3, 13)).with_label("expected type annotation here");
        const annotation2 = Annotation.secondary(0, Span.init(28, 31)).with_label("due to this");
        const diagnostic = Diagnostic.err().with_annotations(&.{annotation1, annotation2});

        // 1 | let main = 23;
        //   |    ^^^^^^^^^^ expected type annotation here
        // 2 | something += 3.0;
        //   |              --- due to this

        try runTest(input, &diagnostic, 0, &.{}, &.{&annotation1}, &.{
            AnnotationData { .start = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 3),
            }},
            AnnotationData { .connecting_singleline = .{
                .style = annotation1.style, .as_multiline = false,
                .severity = diagnostic.severity,
                .line_index = 0,
                .start_column_index = 3, .end_column_index = 13,
            }},
            AnnotationData { .end = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 13),
            }},
            AnnotationData { .label = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 3),
                .label = "expected type annotation here",
            }},
            AnnotationData.newline,
        });
        try runTest(input, &diagnostic, 1, &.{}, &.{&annotation2}, &.{
            AnnotationData { .start = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(1, 13),
            }},
            AnnotationData { .connecting_singleline = .{
                .style = annotation2.style, .as_multiline = false,
                .severity = diagnostic.severity,
                .line_index = 1,
                .start_column_index = 13, .end_column_index = 16,
            }},
            AnnotationData { .end = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(1, 16),
            }},
            AnnotationData { .label = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(1, 13),
                .label = "due to this",
            }},
            AnnotationData.newline,
        });
    }

    test "same line 1" {
        const input =
            \\let main = 23;
            \\something += 3.0;
            \\print(example_source);
        ++ "\n";

        const annotation1 = Annotation.primary(0, Span.init(11, 13)).with_label("number");
        const annotation2 = Annotation.secondary(0, Span.init(4, 8)).with_label("identifier");
        const diagnostic = Diagnostic.err().with_annotations(&.{annotation1, annotation2});

        // 1 | let main = 23;
        //   |     ----   ^^ number
        //   |     |
        //   |     identifier

        try runTest(input, &diagnostic, 0, &.{}, &.{&annotation1, &annotation2}, &.{
            AnnotationData { .start = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 4),
            }},
            AnnotationData { .connecting_singleline = .{
                .style = annotation2.style, .as_multiline = false,
                .severity = diagnostic.severity,
                .line_index = 0,
                .start_column_index = 4, .end_column_index = 8,
            }},
            AnnotationData { .end = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 8),
            }},
            AnnotationData { .start = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 11),
            }},
            AnnotationData { .connecting_singleline = .{
                .style = annotation1.style, .as_multiline = false,
                .severity = diagnostic.severity,
                .line_index = 0,
                .start_column_index = 11, .end_column_index = 13,
            }},
            AnnotationData { .end = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 13),
            }},
            AnnotationData { .label = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 11),
                .label = "number",
            }},
            AnnotationData.newline,
            AnnotationData { .hanging = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 4),
            }},
            AnnotationData.newline,
            AnnotationData { .label = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 4),
                .label = "identifier",
            }},
            AnnotationData.newline,
        });
    }

    test "overlapping 1" {
        const input =
            \\let main = 23;
            \\something += 3.0;
            \\print(example_source);
        ++ "\n";

        const annotation1 = Annotation.primary(0, Span.init(4, 13)).with_label("something");
        const annotation2 = Annotation.secondary(0, Span.init(8, 11)).with_label("something else");
        const diagnostic = Diagnostic.err().with_annotations(&.{annotation1, annotation2});

        // 1 | let main = 23;
        //   |     ^^^^---^^
        //   |     |   |
        //   |     |   something else
        //   |     something

        try runTest(input, &diagnostic, 0, &.{}, &.{&annotation1, &annotation2}, &.{
            AnnotationData { .start = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 4),
            }},
            AnnotationData { .connecting_singleline = .{
                .style = annotation1.style, .as_multiline = false,
                .severity = diagnostic.severity,
                .line_index = 0,
                .start_column_index = 4, .end_column_index = 13,
            }},
            AnnotationData { .start = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 8),
            }},
            AnnotationData { .connecting_singleline = .{
                .style = annotation2.style, .as_multiline = false,
                .severity = diagnostic.severity,
                .line_index = 0,
                .start_column_index = 8, .end_column_index = 11,
            }},
            AnnotationData { .end = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 11),
            }},
            AnnotationData { .end = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 13),
            }},
            AnnotationData.newline,
            AnnotationData { .hanging = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 4),
            }},
            AnnotationData { .hanging = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 8),
            }},
            AnnotationData.newline,
            AnnotationData { .hanging = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 4),
            }},
            AnnotationData { .label = .{
                .style = annotation2.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 8),
                .label = "something else",
            }},
            AnnotationData.newline,
            AnnotationData { .label = .{
                .style = annotation1.style,
                .severity = diagnostic.severity,
                .location = LineColumn.init(0, 4),
                .label = "something",
            }},
            AnnotationData.newline,
        });
    }
};

test {
    std.testing.refAllDeclsRecursive(@This());
    std.testing.refAllDeclsRecursive(@import("./calculate.zig"));
}
