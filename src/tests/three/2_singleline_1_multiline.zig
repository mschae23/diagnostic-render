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
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/1/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 179)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(7, 16)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(316, 334)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/1/labelled]: Test message
    \\  --> src/path/to/file.something:4:12
    \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
    \\   |          --------- annotation 2
    \\ 2 |       if n < 0 {
    \\ 3 |           panic!("{} is negative!", n);
    \\ 4 |       } else if n == 0 {
    \\   |  ____________^
    \\ 5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\ 6 | |     } else if n == 1 {
    \\   | |_____^ annotation 1
    \\ 7 |           return 1;
    \\  ...
    \\13 |       for _i in 1..n {
    \\14 |           sum = last + curr;
    \\   |           ------------------ annotation 3
    \\15 |           last = curr;
    \\
    );
}

test "1, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 179)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(7, 16)).withLabel("annotation 2\nsecond line"),
            Annotation.secondary(0, Span.init(316, 334)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/1/labelled_multiline]: Test message
    \\  --> src/path/to/file.something:4:12
    \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
    \\   |          --------- annotation 2
    \\   |                    second line
    \\ 2 |       if n < 0 {
    \\ 3 |           panic!("{} is negative!", n);
    \\ 4 |       } else if n == 0 {
    \\   |  ____________^
    \\ 5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\ 6 | |     } else if n == 1 {
    \\   | |_____^ annotation 1
    \\   |         fourth line
    \\ 7 |           return 1;
    \\  ...
    \\13 |       for _i in 1..n {
    \\14 |           sum = last + curr;
    \\   |           ------------------ annotation 3
    \\   |                              sixth line
    \\15 |           last = curr;
    \\
    );
}

test "1, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/1/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 179)),
            Annotation.secondary(0, Span.init(7, 16)),
            Annotation.secondary(0, Span.init(316, 334)),
        })
    },
    \\error[test/three/2_singleline_1_multiline/1/unlabelled]: Test message
    \\  --> src/path/to/file.something:4:12
    \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
    \\   |          ---------
    \\ 2 |       if n < 0 {
    \\ 3 |           panic!("{} is negative!", n);
    \\ 4 |       } else if n == 0 {
    \\   |  ____________^
    \\ 5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\ 6 | |     } else if n == 1 {
    \\   | |_____^
    \\ 7 |           return 1;
    \\  ...
    \\13 |       for _i in 1..n {
    \\14 |           sum = last + curr;
    \\   |           ------------------
    \\15 |           last = curr;
    \\
    );
}

test "2, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/2/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 179)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(188, 194)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/2/labelled]: Test message
    \\ --> src/path/to/file.something:4:12
    \\3 |           panic!("{} is negative!", n);
    \\4 |       } else if n == 0 {
    \\  |         ---- ^
    \\  |  _______|____|
    \\  | |       |
    \\  | |       annotation 2
    \\5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\6 | |     } else if n == 1 {
    \\  | |_____^         ------ annotation 3
    \\  |       |
    \\  |       annotation 1
    \\7 |           return 1;
    \\
    );
}

test "2, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 179)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 2\nsecond line"),
            Annotation.secondary(0, Span.init(188, 194)).withLabel("annotation 3\nfourth line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/2/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:4:12
    \\3 |           panic!("{} is negative!", n);
    \\4 |       } else if n == 0 {
    \\  |         ---- ^
    \\  |  _______|____|
    \\  | |       |
    \\  | |       annotation 2
    \\  | |       second line
    \\5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\6 | |     } else if n == 1 {
    \\  | |_____^         ------ annotation 3
    \\  |       |                fourth line
    \\  |       annotation 1
    \\  |       sixth line
    \\7 |           return 1;
    \\
    );
}

test "2, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/2/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 179)),
            Annotation.secondary(0, Span.init(93, 97)),
            Annotation.secondary(0, Span.init(188, 194)),
        })
    },
    \\error[test/three/2_singleline_1_multiline/2/unlabelled]: Test message
    \\ --> src/path/to/file.something:4:12
    \\3 |           panic!("{} is negative!", n);
    \\4 |       } else if n == 0 {
    \\  |         ---- ^
    \\  |  ____________|
    \\5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\6 | |     } else if n == 1 {
    \\  | |_____^         ------
    \\7 |           return 1;
    \\
    );
}

test "3, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/3/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 197)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(180, 184)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/3/labelled]: Test message
    \\ --> src/path/to/file.something:4:12
    \\3 |           panic!("{} is negative!", n);
    \\4 |       } else if n == 0 {
    \\  |  ____________^  ------ annotation 2
    \\5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\6 | |     } else if n == 1 {
    \\  | |       ----           ^
    \\  | |_______|______________|
    \\  |         |              annotation 1
    \\  |         annotation 3
    \\7 |           return 1;
    \\
    );
}

test "3, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 197)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 2\nsecond line"),
            Annotation.secondary(0, Span.init(180, 184)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/3/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:4:12
    \\3 |           panic!("{} is negative!", n);
    \\4 |       } else if n == 0 {
    \\  |  ____________^  ------ annotation 2
    \\  | |                      second line
    \\5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\6 | |     } else if n == 1 {
    \\  | |       ----           ^
    \\  | |_______|______________|
    \\  |         |              annotation 1
    \\  |         |              fourth line
    \\  |         annotation 3
    \\  |         sixth line
    \\7 |           return 1;
    \\
    );
}

test "3, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/3/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 197)),
            Annotation.secondary(0, Span.init(101, 107)),
            Annotation.secondary(0, Span.init(180, 184)),
        })
    },
    \\error[test/three/2_singleline_1_multiline/3/unlabelled]: Test message
    \\ --> src/path/to/file.something:4:12
    \\3 |           panic!("{} is negative!", n);
    \\4 |       } else if n == 0 {
    \\  |  ____________^  ------
    \\5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\6 | |     } else if n == 1 {
    \\  | |       ----           ^
    \\  | |______________________|
    \\7 |           return 1;
    \\
    );
}

test "4, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/4/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 197)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/4/labelled]: Test message
    \\ --> src/path/to/file.something:4:12
    \\3 |           panic!("{} is negative!", n);
    \\4 |       } else if n == 0 {
    \\  |         ---- ^  ------ annotation 3
    \\  |  _______|____|
    \\  | |       |
    \\  | |       annotation 2
    \\5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\6 | |     } else if n == 1 {
    \\  | |______________________^ annotation 1
    \\7 |           return 1;
    \\
    );
}

test "4, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/4/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 197)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/4/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:4:12
    \\3 |           panic!("{} is negative!", n);
    \\4 |       } else if n == 0 {
    \\  |         ---- ^  ------ annotation 3
    \\  |  _______|____|         second line
    \\  | |       |
    \\  | |       annotation 2
    \\  | |       fourth line
    \\5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\6 | |     } else if n == 1 {
    \\  | |______________________^ annotation 1
    \\  |                          sixth line
    \\7 |           return 1;
    \\
    );
}

test "4, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/4/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 197)),
            Annotation.secondary(0, Span.init(93, 97)),
            Annotation.secondary(0, Span.init(101, 107)),
        })
    },
    \\error[test/three/2_singleline_1_multiline/4/unlabelled]: Test message
    \\ --> src/path/to/file.something:4:12
    \\3 |           panic!("{} is negative!", n);
    \\4 |       } else if n == 0 {
    \\  |         ---- ^  ------
    \\  |  ____________|
    \\5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\6 | |     } else if n == 1 {
    \\  | |______________________^
    \\7 |           return 1;
    \\
    );
}

test "5, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/5/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 99)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/5/labelled]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |       ---- ^  ------ annotation 3
    \\  | |_______|____|
    \\  |         |    annotation 1
    \\  |         annotation 2
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "5, labelled multiline 1" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/5/labelled_multiline/1").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 99)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 2\nsixth line"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/5/labelled_multiline/1]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |       ---- ^  ------ annotation 3
    \\  | |_______|____|         second line
    \\  |         |    annotation 1
    \\  |         |    fourth line
    \\  |         annotation 2
    \\  |         sixth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "5, labelled multiline 2" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/5/labelled_multiline/2").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 99)).withLabel("annotation 1\nfifth line\nsixth line"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 2\neighth line\nninth line"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3\nsecond line\nthird line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/5/labelled_multiline/2]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |       ---- ^  ------ annotation 3
    \\  | |_______|____|         second line
    \\  |         |    |         third line
    \\  |         |    annotation 1
    \\  |         |    fifth line
    \\  |         |    sixth line
    \\  |         annotation 2
    \\  |         eighth line
    \\  |         ninth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "5, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/5/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 99)),
            Annotation.secondary(0, Span.init(93, 97)),
            Annotation.secondary(0, Span.init(101, 107)),
        })
    },
    \\error[test/three/2_singleline_1_multiline/5/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |       ---- ^  ------
    \\  | |____________|
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "6, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/6/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 92)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(98, 100)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/6/labelled]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |_____^      -- ------ annotation 3
    \\  |       |      |
    \\  |       |      annotation 2
    \\  |       annotation 1
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "6, labelled multiline 1" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/6/labelled_multiline/1").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 92)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(98, 100)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/6/labelled_multiline/1]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |_____^      -- ------ annotation 3
    \\  |       |      |         second line
    \\  |       |      annotation 2
    \\  |       |      fourth line
    \\  |       annotation 1
    \\  |       sixth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "6, labelled multiline 2" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/6/labelled_multiline/2").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 92)).withLabel("annotation 1\neighth line\nninth line"),
            Annotation.secondary(0, Span.init(98, 100)).withLabel("annotation 2\nfifth line\nsixth line"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3\nsecond line\nthird line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/6/labelled_multiline/2]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |_____^      -- ------ annotation 3
    \\  |       |      |         second line
    \\  |       |      |         third line
    \\  |       |      annotation 2
    \\  |       |      fifth line
    \\  |       |      sixth line
    \\  |       annotation 1
    \\  |       eighth line
    \\  |       ninth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "6, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/6/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 92)),
            Annotation.secondary(0, Span.init(98, 100)),
            Annotation.secondary(0, Span.init(101, 107)),
        })
    },
    \\error[test/three/2_singleline_1_multiline/6/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |_____^      -- ------
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "7, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/7/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 108)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(98, 100)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/7/labelled]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |       ---- --       ^
    \\  | |_______|____|________|
    \\  |         |    |        annotation 1
    \\  |         |    annotation 2
    \\  |         annotation 3
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "7, labelled multiline 1" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/7/labelled_multiline/1").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 108)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(98, 100)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/7/labelled_multiline/1]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |       ---- --       ^
    \\  | |_______|____|________|
    \\  |         |    |        annotation 1
    \\  |         |    |        second line
    \\  |         |    annotation 2
    \\  |         |    fourth line
    \\  |         annotation 3
    \\  |         sixth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "7, labelled multiline 2" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/7/labelled_multiline/2").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 108)).withLabel("annotation 1\nsecond line\nthird line"),
            Annotation.secondary(0, Span.init(98, 100)).withLabel("annotation 2\nfifth line\nsixth line"),
            Annotation.secondary(0, Span.init(93, 97)).withLabel("annotation 3\neighth line\nninth line"),
        })
    },
    \\error[test/three/2_singleline_1_multiline/7/labelled_multiline/2]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |       ---- --       ^
    \\  | |_______|____|________|
    \\  |         |    |        annotation 1
    \\  |         |    |        second line
    \\  |         |    |        third line
    \\  |         |    annotation 2
    \\  |         |    fifth line
    \\  |         |    sixth line
    \\  |         annotation 3
    \\  |         eighth line
    \\  |         ninth line
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "7, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_singleline_1_multiline/7/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(47, 108)),
            Annotation.secondary(0, Span.init(98, 100)),
            Annotation.secondary(0, Span.init(93, 97)),
        })
    },
    \\error[test/three/2_singleline_1_multiline/7/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:14
    \\1 |   pub fn fibonacci(n: i32) -> u64 {
    \\2 |       if n < 0 {
    \\  |  ______________^
    \\3 | |         panic!("{} is negative!", n);
    \\4 | |     } else if n == 0 {
    \\  | |       ---- --       ^
    \\  | |_____________________|
    \\5 |           panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

// TODO more tests
