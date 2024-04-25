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
const Annotation = diag.Annotation(usize);
const Diagnostic = diag.Diagnostic(usize);
const Note = diag.Note;
const Span = diag.Span;
const ColorConfig = @import("../../ColorConfig.zig");
const render = @import("../../render/mod.zig");
const runTest = @import("../tests.zig").output.runTest;
const fibonacci_input = @import("../tests.zig").output.fibonacci_input;

pub const singleline = struct {
    test "1, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/1/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/singleline/1/labelled]: Test message
        \\ --> src/path/to/file.something:1:1
        \\1 | pub fn fibonacci(n: i32) -> u64 {
        \\  | ^^^ annotation 1
        \\2 |     if n < 0 {
        \\
        );
    }

    test "1, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1\nsecond line"),
            })
        },
        \\error[test/one/singleline/1/labelled_multiline]: Test message
        \\ --> src/path/to/file.something:1:1
        \\1 | pub fn fibonacci(n: i32) -> u64 {
        \\  | ^^^ annotation 1
        \\  |     second line
        \\2 |     if n < 0 {
        \\
        );
    }

    test "1, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/1/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 3)),
            })
        },
        \\error[test/one/singleline/1/unlabelled]: Test message
        \\ --> src/path/to/file.something:1:1
        \\1 | pub fn fibonacci(n: i32) -> u64 {
        \\  | ^^^
        \\2 |     if n < 0 {
        \\
        );
    }

    test "2, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/2/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(38, 48)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/singleline/2/labelled]: Test message
        \\ --> src/path/to/file.something:2:5
        \\1 | pub fn fibonacci(n: i32) -> u64 {
        \\2 |     if n < 0 {
        \\  |     ^^^^^^^^^^ annotation 1
        \\3 |         panic!("{} is negative!", n);
        \\
        );
    }

    test "2, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(38, 48)).withLabel("annotation 1\nsecond line"),
            })
        },
        \\error[test/one/singleline/2/labelled_multiline]: Test message
        \\ --> src/path/to/file.something:2:5
        \\1 | pub fn fibonacci(n: i32) -> u64 {
        \\2 |     if n < 0 {
        \\  |     ^^^^^^^^^^ annotation 1
        \\  |                second line
        \\3 |         panic!("{} is negative!", n);
        \\
        );
    }

    test "2, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/2/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(38, 48)),
            })
        },
        \\error[test/one/singleline/2/unlabelled]: Test message
        \\ --> src/path/to/file.something:2:5
        \\1 | pub fn fibonacci(n: i32) -> u64 {
        \\2 |     if n < 0 {
        \\  |     ^^^^^^^^^^
        \\3 |         panic!("{} is negative!", n);
        \\
        );
    }

    test "3, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/3/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(390, 391)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/singleline/3/labelled]: Test message
        \\  --> src/path/to/file.something:19:1
        \\18 |     sum
        \\19 | }
        \\   | ^ annotation 1
        \\
        );
    }

    test "3, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(390, 391)).withLabel("annotation 1\nsecond line"),
            })
        },
        \\error[test/one/singleline/3/labelled_multiline]: Test message
        \\  --> src/path/to/file.something:19:1
        \\18 |     sum
        \\19 | }
        \\   | ^ annotation 1
        \\   |   second line
        \\
        );
    }

    test "3, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/3/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(390, 391)),
            })
        },
        \\error[test/one/singleline/3/unlabelled]: Test message
        \\  --> src/path/to/file.something:19:1
        \\18 |     sum
        \\19 | }
        \\   | ^
        \\
        );
    }
};
