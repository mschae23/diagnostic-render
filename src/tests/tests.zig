const std = @import("std");
const io = @import("../io.zig");
const file = @import("../file.zig");
const diag = @import("../diagnostic.zig");
const ColorConfig = @import("../ColorConfig.zig");
const render = @import("../render/mod.zig");

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
            diag.Annotation(usize).primary(0, diag.Span.init(13, 22)).with_label("Annotation")
        })
    };

    const output = std.io.getStdErr();
    try output.writer().writeByte('\n');

    var renderer = render.DiagnosticRenderer(usize).init(std.testing.allocator, output.writer().any(), std.io.tty.detectConfig(output), files, .{});
    try renderer.render(&diagnostics);
}
