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
const Annotation = diag.Annotation(usize);
const Diagnostic = diag.Diagnostic(usize);
const Span = diag.Span;
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
            diag.Annotation(usize).primary(0, diag.Span.init(13, 45 + 35 + 1)).with_label("Annotation")
        })
    };

    const output = std.io.getStdErr();
    try output.writer().writeByte('\n');

    var renderer = render.DiagnosticRenderer(usize).init(std.testing.allocator, output.writer().any(), std.io.tty.detectConfig(output), files, .{});
    try renderer.render(&diagnostics);
}

test {
    std.testing.refAllDeclsRecursive(@This());
    std.testing.refAllDeclsRecursive(@import("./calculate.zig"));
}
