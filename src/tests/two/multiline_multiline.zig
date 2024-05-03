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
        Diagnostic.err().withName("test/two/multiline_multiline/1/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 40)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(85, 109)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/1/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\  | |______^ annotation 1
    \\3 |           panic!("{} is negative!", n);
    \\  |  _____________________________________-
    \\4 | |     } else if n == 0 {
    \\  | |______________________- annotation 2
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "1, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 40)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(85, 109)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/1/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\  | |______^ annotation 1
    \\  |          second line
    \\3 |           panic!("{} is negative!", n);
    \\  |  _____________________________________-
    \\4 | |     } else if n == 0 {
    \\  | |______________________- annotation 2
    \\  |                          fourth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "1, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/1/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 40)),
            Annotation.secondary(0, Span.init(85, 109)),
        })
    },
    \\error[test/two/multiline_multiline/1/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\  | |______^
    \\3 |           panic!("{} is negative!", n);
    \\  |  _____________________________________-
    \\4 | |     } else if n == 0 {
    \\  | |______________________-
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "2, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/2/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 63)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(85, 109)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/2/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\3 | |         panic!("{} is negative!", n);
    \\  | |______________^                      -
    \\  |  ______________|______________________|
    \\  | |              |
    \\  | |              annotation 1
    \\4 | |     } else if n == 0 {
    \\  | |______________________- annotation 2
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "2, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 63)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(85, 109)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/2/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\3 | |         panic!("{} is negative!", n);
    \\  | |______________^                      -
    \\  |  ______________|______________________|
    \\  | |              |
    \\  | |              annotation 1
    \\  | |              second line
    \\4 | |     } else if n == 0 {
    \\  | |______________________- annotation 2
    \\  |                          fourth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "2, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/2/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 63)),
            Annotation.secondary(0, Span.init(85, 109)),
        })
    },
    \\error[test/two/multiline_multiline/2/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\3 | |         panic!("{} is negative!", n);
    \\  | |______________^                      -
    \\  |  _____________________________________|
    \\4 | |     } else if n == 0 {
    \\  | |______________________-
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "3, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/3/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 86)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(63, 109)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/3/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\3 | |         panic!("{} is negative!", n);
    \\  | |               -                     ^
    \\  | |_______________|_____________________|
    \\  |  _______________|                     annotation 1
    \\4 | |     } else if n == 0 {
    \\  | |______________________- annotation 2
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "3, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 86)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(63, 109)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/3/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\3 | |         panic!("{} is negative!", n);
    \\  | |               -                     ^
    \\  | |_______________|_____________________|
    \\  |  _______________|                     annotation 1
    \\  | |                                     second line
    \\4 | |     } else if n == 0 {
    \\  | |______________________- annotation 2
    \\  |                          fourth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "3, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/3/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 86)),
            Annotation.secondary(0, Span.init(63, 109)),
        })
    },
    \\error[test/two/multiline_multiline/3/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\3 | |         panic!("{} is negative!", n);
    \\  | |               -                     ^
    \\  | |_______________|_____________________|
    \\  |  _______________|
    \\4 | |     } else if n == 0 {
    \\  | |______________________-
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "4, labelled" {
    // TODO This can be optimized to use only up to 2 vertical offsets, but at least it looks fine

    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/4/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 63)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(62, 109)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/4/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\3 | |         panic!("{} is negative!", n);
    \\  | |______________-
    \\  |  ______________|
    \\  | |              |
    \\  | |              annotation 1
    \\4 | |     } else if n == 0 {
    \\  | |______________________- annotation 2
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "4, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/4/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 63)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(62, 109)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/4/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\3 | |         panic!("{} is negative!", n);
    \\  | |______________-
    \\  |  ______________|
    \\  | |              |
    \\  | |              annotation 1
    \\  | |              second line
    \\4 | |     } else if n == 0 {
    \\  | |______________________- annotation 2
    \\  |                          fourth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "4, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/4/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 63)),
            Annotation.secondary(0, Span.init(62, 109)),
        })
    },
    \\error[test/two/multiline_multiline/4/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\  |  _^
    \\2 | |     if n < 0 {
    \\3 | |         panic!("{} is negative!", n);
    \\  | |______________-
    \\  |  ______________|
    \\4 | |     } else if n == 0 {
    \\  | |______________________-
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "5, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/5/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 86)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(7, 63)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/5/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^      -
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |______________-                      ^
    \\  | |________________|______________________|
    \\  |                  |                      annotation 1
    \\  |                  annotation 2
    \\4 |         } else if n == 0 {
    \\
    );
}

test "5, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/5/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 86)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(7, 63)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/5/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^      -
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |______________-                      ^
    \\  | |________________|______________________|
    \\  |                  |                      annotation 1
    \\  |                  |                      second line
    \\  |                  annotation 2
    \\  |                  fourth line
    \\4 |         } else if n == 0 {
    \\
    );
}

test "5, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/5/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 86)),
            Annotation.secondary(0, Span.init(7, 63)),
        })
    },
    \\error[test/two/multiline_multiline/5/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^      -
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |______________-                      ^
    \\  | |_______________________________________|
    \\4 |         } else if n == 0 {
    \\
    );
}

test "6, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/6/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 63)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(7, 86)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/6/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^      -
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |              ^                      -
    \\  | | |______________|______________________|
    \\  | |________________|                      annotation 2
    \\  |                  annotation 1
    \\4 |         } else if n == 0 {
    \\
    );
}

test "6, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/6/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 63)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(7, 86)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/6/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^      -
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |              ^                      -
    \\  | | |______________|______________________|
    \\  | |________________|                      annotation 2
    \\  |                  |                      fourth line
    \\  |                  annotation 1
    \\  |                  second line
    \\4 |         } else if n == 0 {
    \\
    );
}

test "6, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/6/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 63)),
            Annotation.secondary(0, Span.init(7, 86)),
        })
    },
    \\error[test/two/multiline_multiline/6/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^      -
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |              ^                      -
    \\  | | |______________|______________________|
    \\  | |________________|
    \\4 |         } else if n == 0 {
    \\
    );
}

test "7, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/7/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 86)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(0, 63)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/7/labelled]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___-      ^
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |              -                      ^
    \\  | | |______________|______________________|
    \\  | |________________|                      annotation 1
    \\  |                  annotation 2
    \\4 |         } else if n == 0 {
    \\
    );
}

test "7, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/7/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 86)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(0, 63)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/7/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___-      ^
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |              -                      ^
    \\  | | |______________|______________________|
    \\  | |________________|                      annotation 1
    \\  |                  |                      second line
    \\  |                  annotation 2
    \\  |                  fourth line
    \\4 |         } else if n == 0 {
    \\
    );
}

test "7, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/7/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 86)),
            Annotation.secondary(0, Span.init(0, 63)),
        })
    },
    \\error[test/two/multiline_multiline/7/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___-      ^
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |              -                      ^
    \\  | | |______________|______________________|
    \\  | |________________|
    \\4 |         } else if n == 0 {
    \\
    );
}

test "8, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/8/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 63)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(0, 86)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/8/labelled]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___-      ^
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |______________^                      -
    \\  | |________________|______________________|
    \\  |                  |                      annotation 2
    \\  |                  annotation 1
    \\4 |         } else if n == 0 {
    \\
    );
}

test "8, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/8/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 63)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(0, 86)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/8/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___-      ^
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |______________^                      -
    \\  | |________________|______________________|
    \\  |                  |                      annotation 2
    \\  |                  |                      fourth line
    \\  |                  annotation 1
    \\  |                  second line
    \\4 |         } else if n == 0 {
    \\
    );
}

test "8, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/8/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(7, 63)),
            Annotation.secondary(0, Span.init(0, 86)),
        })
    },
    \\error[test/two/multiline_multiline/8/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:8
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___-      ^
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |______________^                      -
    \\  | |_______________________________________|
    \\4 |         } else if n == 0 {
    \\
    );
}

test "9, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/9/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 220)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(7, 86)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/9/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^      -
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |_____________________________________- annotation 2
    \\4 | |       } else if n == 0 {
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^ annotation 1
    \\9 |
    \\
    );
}

test "9, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/9/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 220)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(7, 86)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/9/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^      -
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |_____________________________________- annotation 2
    \\  | |                                         fourth line
    \\4 | |       } else if n == 0 {
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^ annotation 1
    \\  |           second line
    \\9 |
    \\
    );
}

test "9, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/9/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 220)),
            Annotation.secondary(0, Span.init(7, 86)),
        })
    },
    \\error[test/two/multiline_multiline/9/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^      -
    \\  | |  ________|
    \\2 | | |     if n < 0 {
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |_____________________________________-
    \\4 | |       } else if n == 0 {
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^
    \\9 |
    \\
    );
}

test "10, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/10/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 220)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(38, 86)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/10/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^
    \\2 | |       if n < 0 {
    \\  | |  _____-
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |_____________________________________- annotation 2
    \\4 | |       } else if n == 0 {
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^ annotation 1
    \\9 |
    \\
    );
}

test "10, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/10/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 220)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(38, 86)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/10/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^
    \\2 | |       if n < 0 {
    \\  | |  _____-
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |_____________________________________- annotation 2
    \\  | |                                         fourth line
    \\4 | |       } else if n == 0 {
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^ annotation 1
    \\  |           second line
    \\9 |
    \\
    );
}

test "10, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/10/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 220)),
            Annotation.secondary(0, Span.init(38, 86)),
        })
    },
    \\error[test/two/multiline_multiline/10/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^
    \\2 | |       if n < 0 {
    \\  | |  _____-
    \\3 | | |         panic!("{} is negative!", n);
    \\  | | |_____________________________________-
    \\4 | |       } else if n == 0 {
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^
    \\9 |
    \\
    );
}

test "11, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/11/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 86)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(38, 220)).withLabel("annotation 2"),
        })
    },
    \\error[test/two/multiline_multiline/11/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^
    \\2 | |       if n < 0 {
    \\  | |  _____-
    \\3 | | |         panic!("{} is negative!", n);
    \\  | |_|_____________________________________^ annotation 1
    \\4 |   |     } else if n == 0 {
    \\ ...  |
    \\7 |   |         return 1;
    \\8 |   |     }
    \\  |   |_____- annotation 2
    \\9 |
    \\
    );
}

test "11, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/11/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 86)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(38, 220)).withLabel("annotation 2\nfourth line"),
        })
    },
    \\error[test/two/multiline_multiline/11/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^
    \\2 | |       if n < 0 {
    \\  | |  _____-
    \\3 | | |         panic!("{} is negative!", n);
    \\  | |_|_____________________________________^ annotation 1
    \\  |   |                                       second line
    \\4 |   |     } else if n == 0 {
    \\ ...  |
    \\7 |   |         return 1;
    \\8 |   |     }
    \\  |   |_____- annotation 2
    \\  |           fourth line
    \\9 |
    \\
    );
}

test "11, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/two/multiline_multiline/11/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 86)),
            Annotation.secondary(0, Span.init(38, 220)),
        })
    },
    \\error[test/two/multiline_multiline/11/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\  |  ___^
    \\2 | |       if n < 0 {
    \\  | |  _____-
    \\3 | | |         panic!("{} is negative!", n);
    \\  | |_|_____________________________________^
    \\4 |   |     } else if n == 0 {
    \\ ...  |
    \\7 |   |         return 1;
    \\8 |   |     }
    \\  |   |_____-
    \\9 |
    \\
    );
}
