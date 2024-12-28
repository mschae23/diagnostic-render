const std = @import("std");
const diagnosticrender = @import("diagnostic-render");
const file = diagnosticrender.file;
const io = diagnosticrender.io;
const diag = diagnosticrender.diagnostic;
const Annotation = diag.Annotation(usize);
const Diagnostic = diag.Diagnostic(usize);
const Note = diag.Note;
const Span = diag.Span;
const ColorConfig = diagnosticrender.ColorConfig;
const render = diagnosticrender.render;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var fbs = std.io.fixedBufferStream(
        \\pub fn tést(&mut self, arg: i32) -> bool {
        \\    return self.counter + arg > 7;
        \\}
    );

    var file_hashmap = std.AutoHashMap(usize, file.FileData).init(allocator);
    try file_hashmap.put(0, file.FileData {
        .name = "src/test.rs",
        .reader = fbs.reader().any(),
        .seeker = io.anySeekableStream(@TypeOf(fbs), *@TypeOf(fbs), &&fbs),
    });
    defer file_hashmap.deinit();

    var files = try file.Files(usize).init(allocator, &file_hashmap);
    defer files.deinit();

    const diagnostics = .{
        Diagnostic.err().withName("thing/test").withMessage("Test").withAnnotations(&.{
            Annotation.primary(0, diag.Span.init(43, 45 + 35 + 1)).withLabel("label 1"),
            Annotation.secondary(0, diag.Span.init(4, 33)).withLabel("label 2")
        }),
        Diagnostic.err().withName("thing/test2").withMessage("Test 2").withAnnotations(&.{
            Annotation.primary(0, diag.Span.init(7, 13)).withLabel("label 1"),
            Annotation.secondary(0, diag.Span.init(38, 42)).withLabel("label 2")
        })
    };

    const output_file = std.io.getStdOut();
    try output_file.writer().writeByte('\n');

    var renderer = render.DiagnosticRenderer(usize).init(allocator, output_file.writer().any(), std.io.tty.detectConfig(output_file), &files, .{});
    try renderer.render(&diagnostics);
}