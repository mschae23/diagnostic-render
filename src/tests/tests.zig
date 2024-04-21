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
const Note = diag.Note;
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

    var files = try file.Files(usize).init(std.testing.allocator, &file_hashmap);
    defer files.deinit();

    const diagnostics = .{
        Diagnostic.err().with_name("thing/test").with_message("Test").with_annotations(&.{
            Annotation.primary(0, diag.Span.init(43, 45 + 35 + 1)).with_label("label 1"),
            Annotation.secondary(0, diag.Span.init(4, 33)).with_label("label 2")
        }),
        Diagnostic.err().with_name("thing/test2").with_message("Test 2").with_annotations(&.{
            Annotation.primary(0, diag.Span.init(7, 13)).with_label("label 1"),
            Annotation.secondary(0, diag.Span.init(38, 42)).with_label("label 2")
        })
    };

    const output_file = std.io.getStdErr();
    try output_file.writer().writeByte('\n');

    var renderer = render.DiagnosticRenderer(usize).init(std.testing.allocator, output_file.writer().any(), std.io.tty.detectConfig(output_file), &files, .{});
    try renderer.render(&diagnostics);
}

pub const output = struct {
    fn runTest(path: [:0]const u8, input: []const u8, diagnostics: []const Diagnostic, expected: []const u8) !void {
        var fbs = std.io.fixedBufferStream(input);

        var file_hashmap = std.AutoHashMap(usize, file.FileData).init(std.testing.allocator);
        try file_hashmap.put(0, file.FileData {
            .name = path,
            .reader = fbs.reader().any(),
            .seeker = io.anySeekableStream(@TypeOf(fbs), *@TypeOf(fbs), &&fbs),
        });
        defer file_hashmap.deinit();

        var files = try file.Files(usize).init(std.testing.allocator, &file_hashmap);
        defer files.deinit();

        var actual = try std.ArrayListUnmanaged(u8).initCapacity(std.testing.allocator, 0);
        defer actual.deinit(std.testing.allocator);

        var renderer = render.DiagnosticRenderer(usize).init(std.testing.allocator, actual.writer(std.testing.allocator).any(), .no_color, &files, .{});
        try renderer.render(diagnostics);

        try std.testing.expectEqualStrings(expected, actual.items);
    }

    test "header 1" {
        try runTest("src/path/to/file.something", "unused source", &.{
            Diagnostic.err().with_name("test/diagnostic_1").with_message("Test message")
        }, "error[test/diagnostic_1]: Test message\n");
    }

    test "footer 1" {
        try runTest("src/path/to/file.something", "unused source", &.{
            Diagnostic.warning().with_name("test/diagnostic_2").with_message("Test message").with_notes(&.{
                Note.note("This is a test note.\nYes.")
            })
        },
        \\warning[test/diagnostic_2]: Test message
        \\ = note: This is a test note.
        \\         Yes.
        );
    }

    test "fibonacci" {
        const input =
            \\pub fn fibonacci(n: i32) -> u64 {
            \\    if n < 0 {
            \\        panic!("{} is negative!", n);
            \\    } else if n == 0 {
            \\        panic!("zero is not a right argument to fibonacci()!");
            \\    } else if n == 1 {
            \\        return 1;
            \\    }
            \\
            \\    let mut sum = 0;
            \\    let mut last = 0;
            \\    let mut curr = 1;
            \\    for _i in 1..n {
            \\        sum = last + curr;
            \\        last = curr;
            \\        curr = sum;
            \\    }
            \\    sum
            \\}
            ;

        var annotations = std.ArrayList(Annotation).init(std.testing.allocator);
        defer annotations.deinit();
        var diagnostic = Diagnostic.note().with_name("info/fibonacci").with_message("A fibonacci function");

        {
            const Scope = struct {
                start_byte_index: usize,
                close_char: u8,
            };

            var opened = std.ArrayList(Scope).init(std.testing.allocator);
            defer opened.deinit();

            var i: usize = 0;

            while (i < input.len) : (i += try std.unicode.utf8ByteSequenceLength(input[i])) {
                const c = input[i];

                switch (c) {
                    '(' => (try opened.addOne()).* = .{ .start_byte_index = i, .close_char = ')', },
                    '[' => (try opened.addOne()).* = .{ .start_byte_index = i, .close_char = ']', },
                    '{' => (try opened.addOne()).* = .{ .start_byte_index = i, .close_char = '}', },
                    '"' => if (opened.items.len == 0 or opened.getLast().close_char != '"') {
                        (try opened.addOne()).* = .{ .start_byte_index = i, .close_char = '"', };
                    } else {
                        const scope = opened.pop();

                        if (scope.close_char != '"') {
                            return error.WrongScope;
                        }

                        const range = Span.init(scope.start_byte_index, i + 1);
                        const label = "this is a string";
                        (try annotations.addOne()).* = Annotation.primary(0, range).with_label(label);
                    },
                    ')', ']', '}' => {
                        const scope = opened.pop();
                        if (c == scope.close_char) {
                            const range = Span.init(scope.start_byte_index, i + 1);
                            const label = switch (c) {
                                ')' => "this is a pair of parentheses",
                                ']' => "this is a pair of brackets",
                                '}' => "this is a pair of braces",
                                else => unreachable,
                            };
                            (try annotations.addOne()).* = Annotation.primary(0, range).with_label(label);
                        } else {
                            return error.WrongScope;
                        }
                    },
                    else => {},
                }
            }

            (try annotations.addOne()).* = Annotation.primary(0, Span.init(0, input.len)).with_label("this is the whole program");
            diagnostic = diagnostic.with_annotations(annotations.items);
        }

        // TODO This test already works relatively well, however, it highlights an issue where if there are multiple
        //      ending (or presumably also singleline) annotations at the same column, only the label of one of them
        //      will be displayed.

        try runTest("src/fibonacci.rs", input, &.{diagnostic},
        \\note[info/fibonacci]: A fibonacci function
        \\  --> src/fibonacci.rs:1:1
        \\ 1 |       pub fn fibonacci(n: i32) -> u64 {
        \\   |  _____^               ^^^^^^^^        ^
        \\   | |  ___________________|_______________|
        \\   | | |                   |
        \\   | | |                   this is a pair of parentheses
        \\ 2 | | |       if n < 0 {
        \\   | | |  ______________^
        \\ 3 | | | |         panic!("{} is negative!", n);
        \\   | | | |               ^^^^^^^^^^^^^^^^^^^^^^
        \\   | | | |               |||
        \\   | | | |               ||this is a pair of braces
        \\   | | | |               |this is a string
        \\   | | | |               this is a pair of parentheses
        \\ 4 | | | |     } else if n == 0 {
        \\   | | | |_____^                ^
        \\   | | |  _____|________________|
        \\   | | | |     |
        \\   | | | |     this is a pair of braces
        \\ 5 | | | |         panic!("zero is not a right argument to fibonacci()!");
        \\   | | | |               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        \\   | | | |               ||                                         |
        \\   | | | |               ||                                         this is a pair of parentheses
        \\   | | | |               |this is a string
        \\   | | | |               this is a pair of parentheses
        \\ 6 | | | |     } else if n == 1 {
        \\   | | | |_____^                ^
        \\   | | |  _____|________________|
        \\   | | | |     |
        \\   | | | |     this is a pair of braces
        \\ 7 | | | |         return 1;
        \\ 8 | | | |     }
        \\   | | | |_____^ this is a pair of braces
        \\ 9 | | |
        \\  ...| |
        \\12 | | |       let mut curr = 1;
        \\13 | | |       for _i in 1..n {
        \\   | | |  ____________________^
        \\14 | | | |         sum = last + curr;
        \\16 | | | |         curr = sum;
        \\17 | | | |     }
        \\   | | | |_____^ this is a pair of braces
        \\18 | | |       sum
        \\19 | | |   }
        \\   | | |   ^
        \\   | | |___|
        \\   | |_____|
        \\   |       this is the whole program
        \\
        );
    }
};

test {
    std.testing.refAllDeclsRecursive(@This());
    std.testing.refAllDeclsRecursive(@import("./calculate.zig"));
}
