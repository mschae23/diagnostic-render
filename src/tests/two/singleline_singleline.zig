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
        Diagnostic.err().withName("test/two/singleline_singleline/1/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(38, 40)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_singleline/1/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\  | ^^^ annotation 1
    \\2 |     if n < 0 {
    \\  |     -- annotation 2
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "1, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(38, 40)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_singleline/1/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\  | ^^^ annotation 1
    \\  |     second line
    \\2 |     if n < 0 {
    \\  |     -- annotation 2
    \\  |        fourth line
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "1, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/1/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)),
            Annotation.secondary(0, Span.init(38, 40)),
        })
    },
    \\error[test/two/singleline_singleline/1/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\  | ^^^
    \\2 |     if n < 0 {
    \\  |     --
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "2, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/2/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(226, 242)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_singleline/2/labelled]: Test message
    \\  --> src/path/to/file.something:1:1
    \\ 1 | pub fn fibonacci(n: i32) -> u64 {
    \\   | ^^^ annotation 1
    \\ 2 |     if n < 0 {
    \\  ...
    \\ 9 |
    \\10 |     let mut sum = 0;
    \\   |     ---------------- annotation 2
    \\11 |     let mut last = 0;
    \\
    );
}

test "2, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(226, 242)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_singleline/2/labelled_multiline]: Test message
    \\  --> src/path/to/file.something:1:1
    \\ 1 | pub fn fibonacci(n: i32) -> u64 {
    \\   | ^^^ annotation 1
    \\   |     second line
    \\ 2 |     if n < 0 {
    \\  ...
    \\ 9 |
    \\10 |     let mut sum = 0;
    \\   |     ---------------- annotation 2
    \\   |                      fourth line
    \\11 |     let mut last = 0;
    \\
    );
}

test "2, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/2/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)),
            Annotation.secondary(0, Span.init(226, 242)),
        })
    },
    \\error[test/two/singleline_singleline/2/unlabelled]: Test message
    \\  --> src/path/to/file.something:1:1
    \\ 1 | pub fn fibonacci(n: i32) -> u64 {
    \\   | ^^^
    \\ 2 |     if n < 0 {
    \\  ...
    \\ 9 |
    \\10 |     let mut sum = 0;
    \\   |     ----------------
    \\11 |     let mut last = 0;
    \\
    );
}

test "3, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/3/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 40)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(390, 391)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_singleline/3/labelled]: Test message
    \\  --> src/path/to/file.something:2:5
    \\ 1 | pub fn fibonacci(n: i32) -> u64 {
    \\ 2 |     if n < 0 {
    \\   |     ^^ annotation 1
    \\ 3 |         panic!("{} is negative!", n);
    \\  ...
    \\18 |     sum
    \\19 | }
    \\   | - annotation 2
    \\
    );
}

test "3, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 40)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(390, 391)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_singleline/3/labelled_multiline]: Test message
    \\  --> src/path/to/file.something:2:5
    \\ 1 | pub fn fibonacci(n: i32) -> u64 {
    \\ 2 |     if n < 0 {
    \\   |     ^^ annotation 1
    \\   |        second line
    \\ 3 |         panic!("{} is negative!", n);
    \\  ...
    \\18 |     sum
    \\19 | }
    \\   | - annotation 2
    \\   |   fourth line
    \\
    );
}

test "3, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/3/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 40)),
            Annotation.secondary(0, Span.init(390, 391)),
        })
    },
    \\error[test/two/singleline_singleline/3/unlabelled]: Test message
    \\  --> src/path/to/file.something:2:5
    \\ 1 | pub fn fibonacci(n: i32) -> u64 {
    \\ 2 |     if n < 0 {
    \\   |     ^^
    \\ 3 |         panic!("{} is negative!", n);
    \\  ...
    \\18 |     sum
    \\19 | }
    \\   | -
    \\
    );
}

test "4, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/4/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 40)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(41, 46)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_singleline/4/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^ ----- annotation 2
    \\  |     |
    \\  |     annotation 1
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "4, labelled_multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/4/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 40)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(41, 46)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_singleline/4/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^ ----- annotation 2
    \\  |     |        fourth line
    \\  |     annotation 1
    \\  |     second line
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "4, labelled_multiline 2" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/4/labelled_multiline2").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 40)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(41, 46)).withLabel("annotation 2\nfourth line\nfifth line"),
        })
    },
    \\error[test/two/singleline_singleline/4/labelled_multiline2]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^ ----- annotation 2
    \\  |     |        fourth line
    \\  |     |        fifth line
    \\  |     annotation 1
    \\  |     second line
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "4, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/4/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 40)),
            Annotation.secondary(0, Span.init(41, 46)),
        })
    },
    \\error[test/two/singleline_singleline/4/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^ -----
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "5, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/5/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(38, 40)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_singleline/5/labelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     -- ^^^^^ annotation 1
    \\  |     |
    \\  |     annotation 2
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "5, labelled_multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/5/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(38, 40)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_singleline/5/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     -- ^^^^^ annotation 1
    \\  |     |        second line
    \\  |     annotation 2
    \\  |     fourth line
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "5, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/5/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)),
            Annotation.secondary(0, Span.init(38, 40)),
        })
    },
    \\error[test/two/singleline_singleline/5/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     -- ^^^^^
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "6, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/6/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 42)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(41, 46)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_singleline/6/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^^-----
    \\  |     |  |
    \\  |     |  annotation 2
    \\  |     annotation 1
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "6, labelled_multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/6/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 42)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(41, 46)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_singleline/6/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^^-----
    \\  |     |  |
    \\  |     |  annotation 2
    \\  |     |  fourth line
    \\  |     annotation 1
    \\  |     second line
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "6, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/6/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 42)),
            Annotation.secondary(0, Span.init(41, 46)),
        })
    },
    \\error[test/two/singleline_singleline/6/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^^-----
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "7, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/7/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(38, 42)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_singleline/7/labelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ---^^^^^
    \\  |     |  |
    \\  |     |  annotation 1
    \\  |     annotation 2
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "7, labelled_multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/7/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(38, 42)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_singleline/7/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ---^^^^^
    \\  |     |  |
    \\  |     |  annotation 1
    \\  |     |  second line
    \\  |     annotation 2
    \\  |     fourth line
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "7, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/7/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 46)),
            Annotation.secondary(0, Span.init(38, 42)),
        })
    },
    \\error[test/two/singleline_singleline/7/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ---^^^^^
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "8, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/8/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 48)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(41, 46)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_singleline/8/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^^-----^^
    \\  |     |  |
    \\  |     |  annotation 2
    \\  |     annotation 1
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "8, labelled_multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/8/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 48)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(41, 46)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_singleline/8/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^^-----^^
    \\  |     |  |
    \\  |     |  annotation 2
    \\  |     |  fourth line
    \\  |     annotation 1
    \\  |     second line
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "8, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/8/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 48)),
            Annotation.secondary(0, Span.init(41, 46)),
        })
    },
    \\error[test/two/singleline_singleline/8/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ^^^-----^^
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "same, labelled" {
    // TODO Reproducable bug
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/8/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 48)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(38, 48)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/singleline_singleline/8/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ---------^
    \\  |     |
    \\  |     |
    \\  |     annotation 1
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "same, labelled_multiline" {
    // TODO Reproducable bug
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/8/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 48)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(38, 48)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/singleline_singleline/8/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ---------^
    \\  |     |
    \\  |     |
    \\  |     |
    \\  |     annotation 1
    \\  |     second line
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}

test "same, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/singleline_singleline/8/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 48)),
            Annotation.secondary(0, Span.init(38, 48)),
        })
    },
    \\error[test/two/singleline_singleline/8/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\2 |     if n < 0 {
    \\  |     ---------^
    \\3 |         panic!("{} is negative!", n);
    \\
    );
}
