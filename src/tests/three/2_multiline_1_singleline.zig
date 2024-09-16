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
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/1/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 179)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(7, 48)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(316, 334)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/1/labelled]: Test message
    \\  --> src/path/to/file.something:4:12
    \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
    \\   |  ________-
    \\ 2 | |     if n < 0 {
    \\   | |______________- annotation 2
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
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 179)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(7, 48)).withLabel("annotation 2\nsecond line"),
            Annotation.secondary(0, Span.init(316, 334)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/1/labelled_multiline]: Test message
    \\  --> src/path/to/file.something:4:12
    \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
    \\   |  ________-
    \\ 2 | |     if n < 0 {
    \\   | |______________- annotation 2
    \\   |                  second line
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
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/1/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(98, 179)),
            Annotation.secondary(0, Span.init(7, 48)),
            Annotation.secondary(0, Span.init(316, 334)),
        })
    },
    \\error[test/three/2_multiline_1_singleline/1/unlabelled]: Test message
    \\  --> src/path/to/file.something:4:12
    \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
    \\   |  ________-
    \\ 2 | |     if n < 0 {
    \\   | |______________-
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
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/2/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(32, 391)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(47, 92)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(57, 63)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/2/labelled]: Test message
    \\  --> src/path/to/file.something:1:33
    \\ 1 |     pub fn fibonacci(n: i32) -> u64 {
    \\   |  ___________________________________^
    \\ 2 | |       if n < 0 {
    \\   | |  ______________-
    \\ 3 | | |         panic!("{} is negative!", n);
    \\   | | |         ------ annotation 3
    \\ 4 | | |     } else if n == 0 {
    \\   | | |_____- annotation 2
    \\ 5 | |           panic!("zero is not a right argument to fibonacci()!");
    \\  ...|
    \\18 | |       sum
    \\19 | |   }
    \\   | |___^ annotation 1
    \\
    );
}

test "2, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(32, 391)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(47, 92)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(57, 63)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/2/labelled_multiline]: Test message
    \\  --> src/path/to/file.something:1:33
    \\ 1 |     pub fn fibonacci(n: i32) -> u64 {
    \\   |  ___________________________________^
    \\ 2 | |       if n < 0 {
    \\   | |  ______________-
    \\ 3 | | |         panic!("{} is negative!", n);
    \\   | | |         ------ annotation 3
    \\   | | |                second line
    \\ 4 | | |     } else if n == 0 {
    \\   | | |_____- annotation 2
    \\   | |         fourth line
    \\ 5 | |           panic!("zero is not a right argument to fibonacci()!");
    \\  ...|
    \\18 | |       sum
    \\19 | |   }
    \\   | |___^ annotation 1
    \\   |       sixth line
    \\
    );
}

test "2, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/2/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(32, 391)),
            Annotation.secondary(0, Span.init(47, 92)),
            Annotation.secondary(0, Span.init(57, 63)),
        })
    },
    \\error[test/three/2_multiline_1_singleline/2/unlabelled]: Test message
    \\  --> src/path/to/file.something:1:33
    \\ 1 |     pub fn fibonacci(n: i32) -> u64 {
    \\   |  ___________________________________^
    \\ 2 | |       if n < 0 {
    \\   | |  ______________-
    \\ 3 | | |         panic!("{} is negative!", n);
    \\   | | |         ------
    \\ 4 | | |     } else if n == 0 {
    \\   | | |_____-
    \\ 5 | |           panic!("zero is not a right argument to fibonacci()!");
    \\  ...|
    \\18 | |       sum
    \\19 | |   }
    \\   | |___^
    \\
    );
}

test "3, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/3/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 220)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(47, 92)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(41, 46)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/3/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  ----- -
    \\  | |  ________|_____|
    \\  | | |        |
    \\  | | |        annotation 3
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |_____- annotation 2
    \\5 | |           panic!("zero is not a right argument to fibonacci()!");
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^ annotation 1
    \\9 |
    \\
    );
}

test "3, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 220)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(47, 92)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(41, 46)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/3/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  ----- -
    \\  | |  ________|_____|
    \\  | | |        |
    \\  | | |        annotation 3
    \\  | | |        second line
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |_____- annotation 2
    \\  | |         fourth line
    \\5 | |           panic!("zero is not a right argument to fibonacci()!");
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^ annotation 1
    \\  |           sixth line
    \\9 |
    \\
    );
}

test "3, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/3/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 220)),
            Annotation.secondary(0, Span.init(47, 92)),
            Annotation.secondary(0, Span.init(41, 46)),
        })
    },
    \\error[test/three/2_multiline_1_singleline/3/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  ----- -
    \\  | |  ______________|
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |_____-
    \\5 | |           panic!("zero is not a right argument to fibonacci()!");
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^
    \\9 |
    \\
    );
}

test "4, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/4/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 220)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(47, 92)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(38, 40)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/4/labelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |         -- ^     -
    \\  |  _______|__|     |
    \\  | |  _____|________|
    \\  | | |     |
    \\  | | |     annotation 3
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |_____- annotation 2
    \\5 | |           panic!("zero is not a right argument to fibonacci()!");
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^ annotation 1
    \\9 |
    \\
    );
}

test "4, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/4/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 220)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(47, 92)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(38, 40)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/4/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |         -- ^     -
    \\  |  _______|__|     |
    \\  | |  _____|________|
    \\  | | |     |
    \\  | | |     annotation 3
    \\  | | |     second line
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |_____- annotation 2
    \\  | |         fourth line
    \\5 | |           panic!("zero is not a right argument to fibonacci()!");
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^ annotation 1
    \\  |           sixth line
    \\9 |
    \\
    );
}

test "4, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/4/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(41, 220)),
            Annotation.secondary(0, Span.init(47, 92)),
            Annotation.secondary(0, Span.init(38, 40)),
        })
    },
    \\error[test/three/2_multiline_1_singleline/4/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:8
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |         -- ^     -
    \\  |  __________|     |
    \\  | |  ______________|
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |_____-
    \\5 | |           panic!("zero is not a right argument to fibonacci()!");
    \\ ...|
    \\7 | |           return 1;
    \\8 | |       }
    \\  | |_______^
    \\9 |
    \\
    );
}

test "5, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/5/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(41, 220)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(47, 48)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/5/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  -     - annotation 3
    \\  | |  ________|
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | |_|_____^ annotation 1
    \\5 |   |         panic!("zero is not a right argument to fibonacci()!");
    \\ ...  |
    \\7 |   |         return 1;
    \\8 |   |     }
    \\  |   |_____- annotation 2
    \\9 |
    \\
    );
}

test "5, labelled multiline 1" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/5/labelled_multiline/1").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(41, 220)).withLabel("annotation 2\nsixth line"),
            Annotation.secondary(0, Span.init(47, 48)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/5/labelled_multiline/1]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  -     - annotation 3
    \\  | |  ________|       second line
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | |_|_____^ annotation 1
    \\  |   |       fourth line
    \\5 |   |         panic!("zero is not a right argument to fibonacci()!");
    \\ ...  |
    \\7 |   |         return 1;
    \\8 |   |     }
    \\  |   |_____- annotation 2
    \\  |           sixth line
    \\9 |
    \\
    );
}

test "5, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/5/labelled_multiline/2").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1\nfifth line\nsixth line"),
            Annotation.secondary(0, Span.init(41, 220)).withLabel("annotation 2\neighth line\nninth line"),
            Annotation.secondary(0, Span.init(47, 48)).withLabel("annotation 3\nsecond line\nthird line"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/5/labelled_multiline/2]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  -     - annotation 3
    \\  | |  ________|       second line
    \\  | | |                third line
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | |_|_____^ annotation 1
    \\  |   |       fifth line
    \\  |   |       sixth line
    \\5 |   |         panic!("zero is not a right argument to fibonacci()!");
    \\ ...  |
    \\7 |   |         return 1;
    \\8 |   |     }
    \\  |   |_____- annotation 2
    \\  |           eighth line
    \\  |           ninth line
    \\9 |
    \\
    );
}

test "5, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/5/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)),
            Annotation.secondary(0, Span.init(41, 220)),
            Annotation.secondary(0, Span.init(47, 48)),
        })
    },
    \\error[test/three/2_multiline_1_singleline/5/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  -     -
    \\  | |  ________|
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | |_|_____^
    \\5 |   |         panic!("zero is not a right argument to fibonacci()!");
    \\ ...  |
    \\7 |   |         return 1;
    \\8 |   |     }
    \\  |   |_____-
    \\9 |
    \\
    );
}

test "6, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/6/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(41, 100)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/6/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  -
    \\  | |  ________|
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |     ^       - ------ annotation 3
    \\  | | |_____|_______|
    \\  | |_______|       annotation 2
    \\  |         annotation 1
    \\5 |             panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "6, labelled multiline 1" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/6/labelled_multiline/1").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(41, 100)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/6/labelled_multiline/1]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  -
    \\  | |  ________|
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |     ^       - ------ annotation 3
    \\  | | |_____|_______|        second line
    \\  | |_______|       annotation 2
    \\  |         |       fourth line
    \\  |         annotation 1
    \\  |         sixth line
    \\5 |             panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "6, labelled multiline 2" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/6/labelled_multiline/2").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1\neighth line\nninth line"),
            Annotation.secondary(0, Span.init(41, 100)).withLabel("annotation 2\nfifth line\nsixth line"),
            Annotation.secondary(0, Span.init(101, 107)).withLabel("annotation 3\nsecond line\nthird line"),
        })
    },
    \\error[test/three/2_multiline_1_singleline/6/labelled_multiline/2]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  -
    \\  | |  ________|
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |     ^       - ------ annotation 3
    \\  | | |_____|_______|        second line
    \\  | |_______|       |        third line
    \\  |         |       annotation 2
    \\  |         |       fifth line
    \\  |         |       sixth line
    \\  |         annotation 1
    \\  |         eighth line
    \\  |         ninth line
    \\5 |             panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}

test "6, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/2_multiline_1_singleline/6/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)),
            Annotation.secondary(0, Span.init(41, 100)),
            Annotation.secondary(0, Span.init(101, 107)),
        })
    },
    \\error[test/three/2_multiline_1_singleline/6/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |     pub fn fibonacci(n: i32) -> u64 {
    \\2 |         if n < 0 {
    \\  |  _______^  -
    \\  | |  ________|
    \\3 | | |         panic!("{} is negative!", n);
    \\4 | | |     } else if n == 0 {
    \\  | | |     ^       - ------
    \\  | | |_____|_______|
    \\  | |_______|
    \\5 |             panic!("zero is not a right argument to fibonacci()!");
    \\
    );
}
