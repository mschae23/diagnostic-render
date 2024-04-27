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

test "1, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/1/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 86)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(0, 3)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_singleline/1/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |   --- annotation 2
    \\2 |       if n < 0 {
    \\  |  _____^
    \\3 | |         panic!("{} is negative!", n);
    \\  | |_____________________________________^ annotation 1
    \\4 |       } else if n == 0 {
    \\
    );
}

test "1, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 86)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(0, 3)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_singleline/1/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |   --- annotation 2
    \\  |       fourth line
    \\2 |       if n < 0 {
    \\  |  _____^
    \\3 | |         panic!("{} is negative!", n);
    \\  | |_____________________________________^ annotation 1
    \\  |                                         second line
    \\4 |       } else if n == 0 {
    \\
    );
}

test "1, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/1/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 86)),
            Annotation.secondary(0, Span.init(0, 3)),
        })
    },
    \\error[test/two/multiline_singleline/1/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |   ---
    \\2 |       if n < 0 {
    \\  |  _____^
    \\3 | |         panic!("{} is negative!", n);
    \\  | |_____________________________________^
    \\4 |       } else if n == 0 {
    \\
    );
}

test "2, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/2/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(0, 40)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_singleline/2/labelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |______- ^^^^^ annotation 1
    \\  |        |
    \\  |        annotation 2
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "2, labelled 2" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/2/labelled2").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(0, 40)),
        })
    },
    \\error[test/two/multiline_singleline/2/labelled2]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |______- ^^^^^ annotation 1
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "2, labelled 3" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/2/labelled3").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)),
            Annotation.secondary(0, Span.init(0, 40)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_singleline/2/labelled3]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |______- ^^^^^
    \\  |        |
    \\  |        annotation 2
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "2, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(0, 40)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_singleline/2/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |______- ^^^^^ annotation 1
    \\  |        |       second line
    \\  |        annotation 2
    \\  |        fourth line
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "2, labelled multiline 2" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/2/labelled_multiline2").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1\nsecond line\nthird line"),
            Annotation.secondary(0, Span.init(0, 40)).withLabel("annotation 2\nfifth line"),
        })
    },
    \\error[test/two/multiline_singleline/2/labelled_multiline2]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |______- ^^^^^ annotation 1
    \\  |        |       second line
    \\  |        |       third line
    \\  |        annotation 2
    \\  |        fifth line
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "2, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/2/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)),
            Annotation.secondary(0, Span.init(0, 40)),
        })
    },
    \\error[test/two/multiline_singleline/2/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |______- ^^^^^
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "3, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/3/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(0, 48)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_singleline/3/labelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |        ^^^^^ -
    \\  | |________|_____|
    \\  |          |     annotation 2
    \\  |          annotation 1
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "3, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(0, 48)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_singleline/3/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |        ^^^^^ -
    \\  | |________|_____|
    \\  |          |     annotation 2
    \\  |          |     fourth line
    \\  |          annotation 1
    \\  |          second line
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "3, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/3/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)),
            Annotation.secondary(0, Span.init(0, 48)),
        })
    },
    \\error[test/two/multiline_singleline/3/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |        ^^^^^ -
    \\  | |______________|
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "4, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/4/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(0, 44)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_singleline/4/labelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |        ^^-^^
    \\  | |________|_|
    \\  |          | annotation 2
    \\  |          annotation 1
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "4, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/4/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(0, 44)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_singleline/4/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |        ^^-^^
    \\  | |________|_|
    \\  |          | annotation 2
    \\  |          | fourth line
    \\  |          annotation 1
    \\  |          second line
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "4, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_singleline/4/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)),
            Annotation.secondary(0, Span.init(0, 44)),
        })
    },
    \\error[test/two/multiline_singleline/4/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-
    \\2 | |     if n < 0 {
    \\  | |        ^^-^^
    \\  | |__________|
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}
