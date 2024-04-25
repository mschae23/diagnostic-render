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

    test "zerosize, labelled" {
        // TODO Reproducable bug
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/singleline/size0/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(4, 4)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/singleline/size0/labelled]: Test message
        \\ --> src/path/to/file.something:1:5
        \\1 | pub fn fibonacci(n: i32) -> u64 {
        \\  |    ^^annotation 1
        \\2 |     if n < 0 {
        \\
        );
    }
};

pub const multiline = struct {
    test "start to start, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/1-1/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 35)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/mutliline/1-1/labelled]: Test message
        \\ --> src/path/to/file.something:1:1
        \\1 |   pub fn fibonacci(n: i32) -> u64 {
        \\  |  _^
        \\2 | |     if n < 0 {
        \\  | |_^ annotation 1
        \\3 |           panic!("{} is negative!", n);
        \\
        );
    }

    test "start to start, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/1-1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 35)).withLabel("annotation 1\nsecond line"),
            })
        },
        \\error[test/one/mutliline/1-1/labelled_multiline]: Test message
        \\ --> src/path/to/file.something:1:1
        \\1 |   pub fn fibonacci(n: i32) -> u64 {
        \\  |  _^
        \\2 | |     if n < 0 {
        \\  | |_^ annotation 1
        \\  |     second line
        \\3 |           panic!("{} is negative!", n);
        \\
        );
    }

    test "start to start, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/1-1/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 35)),
            })
        },
        \\error[test/one/mutliline/1-1/unlabelled]: Test message
        \\ --> src/path/to/file.something:1:1
        \\1 |   pub fn fibonacci(n: i32) -> u64 {
        \\  |  _^
        \\2 | |     if n < 0 {
        \\  | |_^
        \\3 |           panic!("{} is negative!", n);
        \\
        );
    }

    test "start to middle, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/1-2/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 111)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/mutliline/1-2/labelled]: Test message
        \\ --> src/path/to/file.something:1:1
        \\1 |   pub fn fibonacci(n: i32) -> u64 {
        \\  |  _^
        \\2 | |     if n < 0 {
        \\ ...|
        \\4 | |     } else if n == 0 {
        \\5 | |         panic!("zero is not a right argument to fibonacci()!");
        \\  | |_^ annotation 1
        \\6 |       } else if n == 1 {
        \\
        );
    }

    test "start to middle, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/1-2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 111)).withLabel("annotation 1\nsecond line"),
            })
        },
        \\error[test/one/mutliline/1-2/labelled_multiline]: Test message
        \\ --> src/path/to/file.something:1:1
        \\1 |   pub fn fibonacci(n: i32) -> u64 {
        \\  |  _^
        \\2 | |     if n < 0 {
        \\ ...|
        \\4 | |     } else if n == 0 {
        \\5 | |         panic!("zero is not a right argument to fibonacci()!");
        \\  | |_^ annotation 1
        \\  |     second line
        \\6 |       } else if n == 1 {
        \\
        );
    }

    test "start to middle, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/1-2/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 111)),
            })
        },
        \\error[test/one/mutliline/1-2/unlabelled]: Test message
        \\ --> src/path/to/file.something:1:1
        \\1 |   pub fn fibonacci(n: i32) -> u64 {
        \\  |  _^
        \\2 | |     if n < 0 {
        \\ ...|
        \\4 | |     } else if n == 0 {
        \\5 | |         panic!("zero is not a right argument to fibonacci()!");
        \\  | |_^
        \\6 |       } else if n == 1 {
        \\
        );
    }

    test "start to end, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/1-3/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 391)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/mutliline/1-3/labelled]: Test message
        \\  --> src/path/to/file.something:1:1
        \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
        \\   |  _^
        \\ 2 | |     if n < 0 {
        \\  ...|
        \\18 | |     sum
        \\19 | | }
        \\   | |_^ annotation 1
        \\
        );
    }

    test "start to end, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/1-3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 391)).withLabel("annotation 1\nsecond line"),
            })
        },
        \\error[test/one/mutliline/1-3/labelled_multiline]: Test message
        \\  --> src/path/to/file.something:1:1
        \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
        \\   |  _^
        \\ 2 | |     if n < 0 {
        \\  ...|
        \\18 | |     sum
        \\19 | | }
        \\   | |_^ annotation 1
        \\   |     second line
        \\
        );
    }

    test "start to end, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/1-3/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(0, 391)),
            })
        },
        \\error[test/one/mutliline/1-3/unlabelled]: Test message
        \\  --> src/path/to/file.something:1:1
        \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
        \\   |  _^
        \\ 2 | |     if n < 0 {
        \\  ...|
        \\18 | |     sum
        \\19 | | }
        \\   | |_^
        \\
        );
    }

    test "middle to middle 1, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/2-2.1/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(226, 226 + 82)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/mutliline/2-2.1/labelled]: Test message
        \\  --> src/path/to/file.something:10:5
        \\ 9 |
        \\10 |       let mut sum = 0;
        \\   |  _____^
        \\11 | |     let mut last = 0;
        \\12 | |     let mut curr = 1;
        \\13 | |     for _i in 1..n {
        \\   | |____________________^ annotation 1
        \\14 |           sum = last + curr;
        \\
        );
    }

    test "middle to middle 1, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/2-2.1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(226, 226 + 82)).withLabel("annotation 1\nsecond line"),
            })
        },
        \\error[test/one/mutliline/2-2.1/labelled_multiline]: Test message
        \\  --> src/path/to/file.something:10:5
        \\ 9 |
        \\10 |       let mut sum = 0;
        \\   |  _____^
        \\11 | |     let mut last = 0;
        \\12 | |     let mut curr = 1;
        \\13 | |     for _i in 1..n {
        \\   | |____________________^ annotation 1
        \\   |                        second line
        \\14 |           sum = last + curr;
        \\
        );
    }

    test "middle to middle 1, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/2-2.1/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(226, 226 + 82)),
            })
        },
        \\error[test/one/mutliline/2-2.1/unlabelled]: Test message
        \\  --> src/path/to/file.something:10:5
        \\ 9 |
        \\10 |       let mut sum = 0;
        \\   |  _____^
        \\11 | |     let mut last = 0;
        \\12 | |     let mut curr = 1;
        \\13 | |     for _i in 1..n {
        \\   | |____________________^
        \\14 |           sum = last + curr;
        \\
        );
    }

    test "middle to middle 2, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/2-2.2/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(226, 226 + 100)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/mutliline/2-2.2/labelled]: Test message
        \\  --> src/path/to/file.something:10:5
        \\ 9 |
        \\10 |       let mut sum = 0;
        \\   |  _____^
        \\11 | |     let mut last = 0;
        \\  ...|
        \\13 | |     for _i in 1..n {
        \\14 | |         sum = last + curr;
        \\   | |__________________^ annotation 1
        \\15 |           last = curr;
        \\
        );
    }

    test "middle to middle 2, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/2-2.2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(226, 226 + 100)).withLabel("annotation 1\nsecond line"),
            })
        },
        \\error[test/one/mutliline/2-2.2/labelled_multiline]: Test message
        \\  --> src/path/to/file.something:10:5
        \\ 9 |
        \\10 |       let mut sum = 0;
        \\   |  _____^
        \\11 | |     let mut last = 0;
        \\  ...|
        \\13 | |     for _i in 1..n {
        \\14 | |         sum = last + curr;
        \\   | |__________________^ annotation 1
        \\   |                      second line
        \\15 |           last = curr;
        \\
        );
    }

    test "middle to middle 2, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/2-2.2/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(226, 226 + 100)),
            })
        },
        \\error[test/one/mutliline/2-2.2/unlabelled]: Test message
        \\  --> src/path/to/file.something:10:5
        \\ 9 |
        \\10 |       let mut sum = 0;
        \\   |  _____^
        \\11 | |     let mut last = 0;
        \\  ...|
        \\13 | |     for _i in 1..n {
        \\14 | |         sum = last + curr;
        \\   | |__________________^
        \\15 |           last = curr;
        \\
        );
    }

    test "middle to end, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/2-3/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(226, 391)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/mutliline/2-3/labelled]: Test message
        \\  --> src/path/to/file.something:10:5
        \\ 9 |
        \\10 |       let mut sum = 0;
        \\   |  _____^
        \\11 | |     let mut last = 0;
        \\  ...|
        \\18 | |     sum
        \\19 | | }
        \\   | |_^ annotation 1
        \\
        );
    }

    test "middle to end, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/2-3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(226, 391)).withLabel("annotation 1\nsecond line"),
            })
        },
        \\error[test/one/mutliline/2-3/labelled_multiline]: Test message
        \\  --> src/path/to/file.something:10:5
        \\ 9 |
        \\10 |       let mut sum = 0;
        \\   |  _____^
        \\11 | |     let mut last = 0;
        \\  ...|
        \\18 | |     sum
        \\19 | | }
        \\   | |_^ annotation 1
        \\   |     second line
        \\
        );
    }

    test "middle to end, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/2-3/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(226, 391)),
            })
        },
        \\error[test/one/mutliline/2-3/unlabelled]: Test message
        \\  --> src/path/to/file.something:10:5
        \\ 9 |
        \\10 |       let mut sum = 0;
        \\   |  _____^
        \\11 | |     let mut last = 0;
        \\  ...|
        \\18 | |     sum
        \\19 | | }
        \\   | |_^
        \\
        );
    }

    test "end to end, labelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/3-3/labelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(386, 391)).withLabel("annotation 1"),
            })
        },
        \\error[test/one/mutliline/3-3/labelled]: Test message
        \\  --> src/path/to/file.something:18:5
        \\17 |       }
        \\18 |       sum
        \\   |  _____^
        \\19 | | }
        \\   | |_^ annotation 1
        \\
        );
    }

    test "end to end, labelled multiline" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/3-3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(386, 391)).withLabel("annotation 1\nsecond line\nthird line\n"),
            })
        },
        \\error[test/one/mutliline/3-3/labelled_multiline]: Test message
        \\  --> src/path/to/file.something:18:5
        \\17 |       }
        \\18 |       sum
        \\   |  _____^
        \\19 | | }
        \\   | |_^ annotation 1
        \\   |     second line
        \\   |     third line
        \\
        );
    }

    test "end to end, unlabelled" {
        try runTest("src/path/to/file.something", fibonacci_input, &.{
            Diagnostic.err().withName("test/one/mutliline/3-3/unlabelled").withMessage("Test message").withAnnotations(&.{
                Annotation.primary(0, Span.init(386, 391)),
            })
        },
        \\error[test/one/mutliline/3-3/unlabelled]: Test message
        \\  --> src/path/to/file.something:18:5
        \\17 |       }
        \\18 |       sum
        \\   |  _____^
        \\19 | | }
        \\   | |_^
        \\
        );
    }
};
