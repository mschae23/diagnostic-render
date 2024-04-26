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
        Diagnostic.err().withName("test/two/singleline_multiline/1/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(38, 86)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_multiline/1/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |   ^^^ annotation 1
    \\2 |       if n < 0 {
    \\  |  _____-
    \\3 | |         panic!("{} is negative!", n);
    \\  | |_____________________________________- annotation 2
    \\4 |       } else if n == 0 {
    \\
    );
}

test "1, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(38, 86)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_multiline/1/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |   ^^^ annotation 1
    \\  |       second line
    \\2 |       if n < 0 {
    \\  |  _____-
    \\3 | |         panic!("{} is negative!", n);
    \\  | |_____________________________________- annotation 2
    \\  |                                         fourth line
    \\4 |       } else if n == 0 {
    \\
    );
}

test "1, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/1/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)),
            Annotation.secondary(0, Span.init(38, 86)),
        })
    },
    \\error[test/two/singleline_multiline/1/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |   ^^^
    \\2 |       if n < 0 {
    \\  |  _____-
    \\3 | |         panic!("{} is negative!", n);
    \\  | |_____________________________________-
    \\4 |       } else if n == 0 {
    \\
    );
}

test "2, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/2/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(7, 48)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_multiline/2/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |   ^^^    -
    \\  |  _|______|
    \\  | | |
    \\  | | annotation 1
    \\2 | |     if n < 0 {
    \\  | |______________- annotation 2
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "2, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(7, 48)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_multiline/2/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |   ^^^    -
    \\  |  _|______|
    \\  | | |
    \\  | | annotation 1
    \\  | | second line
    \\2 | |     if n < 0 {
    \\  | |______________- annotation 2
    \\  |                  fourth line
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "2, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/2/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)),
            Annotation.secondary(0, Span.init(7, 48)),
        })
    },
    \\error[test/two/singleline_multiline/2/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |   ^^^    -
    \\  |  ________|
    \\2 | |     if n < 0 {
    \\  | |______________-
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "3, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/3/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 16)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(0, 48)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_multiline/3/labelled]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-      ^^^^^^^^^ annotation 1
    \\2 | |     if n < 0 {
    \\  | |______________- annotation 2
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "3, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 16)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(0, 48)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_multiline/3/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-      ^^^^^^^^^ annotation 1
    \\  | |                  second line
    \\2 | |     if n < 0 {
    \\  | |______________- annotation 2
    \\  |                  fourth line
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "3, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/3/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 16)),
            Annotation.secondary(0, Span.init(0, 48)),
        })
    },
    \\error[test/two/singleline_multiline/3/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _-      ^^^^^^^^^
    \\2 | |     if n < 0 {
    \\  | |______________-
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "4, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/4/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 16)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(10, 48)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_multiline/4/labelled]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |          ^^^-^^^^^
    \\  |  ________|__|
    \\  | |        |
    \\  | |        annotation 1
    \\2 | |     if n < 0 {
    \\  | |______________- annotation 2
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "4, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/4/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 16)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(10, 48)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_multiline/4/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |          ^^^-^^^^^
    \\  |  ________|__|
    \\  | |        |
    \\  | |        annotation 1
    \\  | |        second line
    \\2 | |     if n < 0 {
    \\  | |______________- annotation 2
    \\  |                  fourth line
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "4, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/4/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 16)),
            Annotation.secondary(0, Span.init(10, 48)),
        })
    },
    \\error[test/two/singleline_multiline/4/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |          ^^^-^^^^^
    \\  |  ___________|
    \\2 | |     if n < 0 {
    \\  | |______________-
    \\3 |           panic!("{} is negative!", n);
    \\
    );
}

test "5, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/5/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(251, 254)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(226, 226 + 82)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_multiline/5/labelled]: Test message
    \\  --> src/path/to/file.something:11:9
    \\ 9 |
    \\10 |       let mut sum = 0;
    \\   |  _____-
    \\11 | |     let mut last = 0;
    \\   | |         ^^^ annotation 1
    \\12 | |     let mut curr = 1;
    \\13 | |     for _i in 1..n {
    \\   | |____________________- annotation 2
    \\14 |           sum = last + curr;
    \\
    );
}

test "5, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/5/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(251, 254)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(226, 226 + 82)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_multiline/5/labelled_multiline]: Test message
    \\  --> src/path/to/file.something:11:9
    \\ 9 |
    \\10 |       let mut sum = 0;
    \\   |  _____-
    \\11 | |     let mut last = 0;
    \\   | |         ^^^ annotation 1
    \\   | |             second line
    \\12 | |     let mut curr = 1;
    \\13 | |     for _i in 1..n {
    \\   | |____________________- annotation 2
    \\   |                        fourth line
    \\14 |           sum = last + curr;
    \\
    );
}

test "5, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/5/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(251, 254)),
            Annotation.secondary(0, Span.init(226, 226 + 82)),
        })
    },
    \\error[test/two/singleline_multiline/5/unlabelled]: Test message
    \\  --> src/path/to/file.something:11:9
    \\ 9 |
    \\10 |       let mut sum = 0;
    \\   |  _____-
    \\11 | |     let mut last = 0;
    \\   | |         ^^^
    \\12 | |     let mut curr = 1;
    \\13 | |     for _i in 1..n {
    \\   | |____________________-
    \\14 |           sum = last + curr;
    \\
    );
}

test "6, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/6/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(251, 254)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(226, 355)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_multiline/6/labelled]: Test message
    \\  --> src/path/to/file.something:11:9
    \\ 9 |
    \\10 |       let mut sum = 0;
    \\   |  _____-
    \\11 | |     let mut last = 0;
    \\   | |         ^^^ annotation 1
    \\12 | |     let mut curr = 1;
    \\  ...|
    \\14 | |         sum = last + curr;
    \\15 | |         last = curr;
    \\   | |____________________- annotation 2
    \\16 |           curr = sum;
    \\
    );
}

test "6, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/6/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(251, 254)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(226, 355)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_multiline/6/labelled_multiline]: Test message
    \\  --> src/path/to/file.something:11:9
    \\ 9 |
    \\10 |       let mut sum = 0;
    \\   |  _____-
    \\11 | |     let mut last = 0;
    \\   | |         ^^^ annotation 1
    \\   | |             second line
    \\12 | |     let mut curr = 1;
    \\  ...|
    \\14 | |         sum = last + curr;
    \\15 | |         last = curr;
    \\   | |____________________- annotation 2
    \\   |                        fourth line
    \\16 |           curr = sum;
    \\
    );
}

test "6, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_multiline/6/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(251, 254)),
            Annotation.secondary(0, Span.init(226, 355)),
        })
    },
    \\error[test/two/singleline_multiline/6/unlabelled]: Test message
    \\  --> src/path/to/file.something:11:9
    \\ 9 |
    \\10 |       let mut sum = 0;
    \\   |  _____-
    \\11 | |     let mut last = 0;
    \\   | |         ^^^
    \\12 | |     let mut curr = 1;
    \\  ...|
    \\14 | |         sum = last + curr;
    \\15 | |         last = curr;
    \\   | |____________________-
    \\16 |           curr = sum;
    \\
    );
}
