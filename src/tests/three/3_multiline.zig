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
        Diagnostic.err().withName("test/three/3_multiline/1/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 48)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(98, 179)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(291, 381)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_multiline/1/labelled]: Test message
    \\  --> src/path/to/file.something:1:1
    \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
    \\   |  _^
    \\ 2 | |     if n < 0 {
    \\   | |______________^ annotation 1
    \\ 3 |           panic!("{} is negative!", n);
    \\ 4 |       } else if n == 0 {
    \\   |  ____________-
    \\ 5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\ 6 | |     } else if n == 1 {
    \\   | |_____- annotation 2
    \\ 7 |           return 1;
    \\  ...
    \\12 |       let mut curr = 1;
    \\13 |       for _i in 1..n {
    \\   |  _____-
    \\14 | |         sum = last + curr;
    \\  ...|
    \\16 | |         curr = sum;
    \\17 | |     }
    \\   | |_____- annotation 3
    \\18 |       sum
    \\
    );
}

test "1, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/1/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 48)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(98, 179)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(291, 381)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/3_multiline/1/labelled_multiline]: Test message
    \\  --> src/path/to/file.something:1:1
    \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
    \\   |  _^
    \\ 2 | |     if n < 0 {
    \\   | |______________^ annotation 1
    \\   |                  second line
    \\ 3 |           panic!("{} is negative!", n);
    \\ 4 |       } else if n == 0 {
    \\   |  ____________-
    \\ 5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\ 6 | |     } else if n == 1 {
    \\   | |_____- annotation 2
    \\   |         fourth line
    \\ 7 |           return 1;
    \\  ...
    \\12 |       let mut curr = 1;
    \\13 |       for _i in 1..n {
    \\   |  _____-
    \\14 | |         sum = last + curr;
    \\  ...|
    \\16 | |         curr = sum;
    \\17 | |     }
    \\   | |_____- annotation 3
    \\   |         sixth line
    \\18 |       sum
    \\
    );
}

test "1, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/1/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 48)),
            Annotation.secondary(0, Span.init(98, 179)),
            Annotation.secondary(0, Span.init(291, 381)),
        })
    },
    \\error[test/three/3_multiline/1/unlabelled]: Test message
    \\  --> src/path/to/file.something:1:1
    \\ 1 |   pub fn fibonacci(n: i32) -> u64 {
    \\   |  _^
    \\ 2 | |     if n < 0 {
    \\   | |______________^
    \\ 3 |           panic!("{} is negative!", n);
    \\ 4 |       } else if n == 0 {
    \\   |  ____________-
    \\ 5 | |         panic!("zero is not a right argument to fibonacci()!");
    \\ 6 | |     } else if n == 1 {
    \\   | |_____-
    \\ 7 |           return 1;
    \\  ...
    \\12 |       let mut curr = 1;
    \\13 |       for _i in 1..n {
    \\   |  _____-
    \\14 | |         sum = last + curr;
    \\  ...|
    \\16 | |         curr = sum;
    \\17 | |     }
    \\   | |_____-
    \\18 |       sum
    \\
    );
}

test "2, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/2/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 179)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(32, 220)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(57, 109)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_multiline/2/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\  | | | |______________________- annotation 3
    \\5 | | |           panic!("zero is not a right argument to fibonacci()!");
    \\6 | | |       } else if n == 1 {
    \\  | | |_______^ annotation 1
    \\7 | |             return 1;
    \\8 | |         }
    \\  | |_________- annotation 2
    \\9 |
    \\
    );
}

test "2, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 179)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(32, 220)).withLabel("annotation 2\nsixth line"),
            Annotation.secondary(0, Span.init(57, 109)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/3_multiline/2/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\  | | | |______________________- annotation 3
    \\  | | |                          second line
    \\5 | | |           panic!("zero is not a right argument to fibonacci()!");
    \\6 | | |       } else if n == 1 {
    \\  | | |_______^ annotation 1
    \\  | |           fourth line
    \\7 | |             return 1;
    \\8 | |         }
    \\  | |_________- annotation 2
    \\  |             sixth line
    \\9 |
    \\
    );
}

test "2, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/2/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 179)),
            Annotation.secondary(0, Span.init(32, 220)),
            Annotation.secondary(0, Span.init(57, 109)),
        })
    },
    \\error[test/three/3_multiline/2/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\  | | | |______________________-
    \\5 | | |           panic!("zero is not a right argument to fibonacci()!");
    \\6 | | |       } else if n == 1 {
    \\  | | |_______^
    \\7 | |             return 1;
    \\8 | |         }
    \\  | |_________-
    \\9 |
    \\
    );
}

test "3, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/3/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(32, 220)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(57, 173)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_multiline/3/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\  | | |_|_____^ annotation 1
    \\5 | |   |         panic!("zero is not a right argument to fibonacci()!");
    \\  | |   |_______________________________________________________________- annotation 3
    \\6 | |         } else if n == 1 {
    \\7 | |             return 1;
    \\8 | |         }
    \\  | |_________- annotation 2
    \\9 |
    \\
    );
}

test "3, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(32, 220)).withLabel("annotation 2\nsixth line"),
            Annotation.secondary(0, Span.init(57, 173)).withLabel("annotation 3\nfourth line"),
        })
    },
    \\error[test/three/3_multiline/3/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\  | | |_|_____^ annotation 1
    \\  | |   |       second line
    \\5 | |   |         panic!("zero is not a right argument to fibonacci()!");
    \\  | |   |_______________________________________________________________- annotation 3
    \\  | |                                                                     fourth line
    \\6 | |         } else if n == 1 {
    \\7 | |             return 1;
    \\8 | |         }
    \\  | |_________- annotation 2
    \\  |             sixth line
    \\9 |
    \\
    );
}

test "3, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/3/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)),
            Annotation.secondary(0, Span.init(32, 220)),
            Annotation.secondary(0, Span.init(57, 173)),
        })
    },
    \\error[test/three/3_multiline/3/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\  | | |_|_____^
    \\5 | |   |         panic!("zero is not a right argument to fibonacci()!");
    \\  | |   |_______________________________________________________________-
    \\6 | |         } else if n == 1 {
    \\7 | |             return 1;
    \\8 | |         }
    \\  | |_________-
    \\9 |
    \\
    );
}

test "4, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/4/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(32, 173)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(57, 220)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_multiline/4/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\  | | |_|_____^ annotation 1
    \\5 | |   |         panic!("zero is not a right argument to fibonacci()!");
    \\  | |___|_______________________________________________________________- annotation 2
    \\6 |     |     } else if n == 1 {
    \\7 |     |         return 1;
    \\8 |     |     }
    \\  |     |_____- annotation 3
    \\9 |
    \\
    );
}

test "4, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/4/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(32, 173)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(57, 220)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/3_multiline/4/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\  | | |_|_____^ annotation 1
    \\  | |   |       second line
    \\5 | |   |         panic!("zero is not a right argument to fibonacci()!");
    \\  | |___|_______________________________________________________________- annotation 2
    \\  |     |                                                                 fourth line
    \\6 |     |     } else if n == 1 {
    \\7 |     |         return 1;
    \\8 |     |     }
    \\  |     |_____- annotation 3
    \\  |             sixth line
    \\9 |
    \\
    );
}

test "4, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/4/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 92)),
            Annotation.secondary(0, Span.init(32, 173)),
            Annotation.secondary(0, Span.init(57, 220)),
        })
    },
    \\error[test/three/3_multiline/4/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\  | | |_|_____^
    \\5 | |   |         panic!("zero is not a right argument to fibonacci()!");
    \\  | |___|_______________________________________________________________-
    \\6 |     |     } else if n == 1 {
    \\7 |     |         return 1;
    \\8 |     |     }
    \\  |     |_____-
    \\9 |
    \\
    );
}

test "5, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/5/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 179)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(32, 173)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(57, 220)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_multiline/5/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | |_|_|_______________________________________________________________- annotation 2
    \\6 |   | |     } else if n == 1 {
    \\  |   |_|_____^ annotation 1
    \\7 |     |         return 1;
    \\8 |     |     }
    \\  |     |_____- annotation 3
    \\9 |
    \\
    );
}

test "5, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/5/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 179)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(32, 173)).withLabel("annotation 2\nsecond line"),
            Annotation.secondary(0, Span.init(57, 220)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/3_multiline/5/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | |_|_|_______________________________________________________________- annotation 2
    \\  |   | |                                                                 second line
    \\6 |   | |     } else if n == 1 {
    \\  |   |_|_____^ annotation 1
    \\  |     |       fourth line
    \\7 |     |         return 1;
    \\8 |     |     }
    \\  |     |_____- annotation 3
    \\  |             sixth line
    \\9 |
    \\
    );
}

test "5, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/5/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 179)),
            Annotation.secondary(0, Span.init(32, 173)),
            Annotation.secondary(0, Span.init(57, 220)),
        })
    },
    \\error[test/three/3_multiline/5/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | |_|_|_______________________________________________________________-
    \\6 |   | |     } else if n == 1 {
    \\  |   |_|_____^
    \\7 |     |         return 1;
    \\8 |     |     }
    \\  |     |_____-
    \\9 |
    \\
    );
}

test "6, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/6/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 154)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(32, 124)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(57, 173)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_multiline/6/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | | | |              -                             ^                  -
    \\  | | | |______________|_____________________________|__________________|
    \\  | | |________________|_____________________________|                  annotation 3
    \\  | |__________________|                             annotation 1
    \\  |                    annotation 2
    \\6 |           } else if n == 1 {
    \\
    );
}

test "6, labelled multiline" {
    // TODO Would it look better to assign the vertical offset directly above the label offset for the connecting line here?
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/6/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 154)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(32, 124)).withLabel("annotation 2\nsixth line"),
            Annotation.secondary(0, Span.init(57, 173)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/3_multiline/6/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | | | |              -                             ^                  -
    \\  | | | |______________|_____________________________|__________________|
    \\  | | |________________|_____________________________|                  annotation 3
    \\  | |__________________|                             |                  second line
    \\  |                    |                             annotation 1
    \\  |                    |                             fourth line
    \\  |                    annotation 2
    \\  |                    sixth line
    \\6 |           } else if n == 1 {
    \\
    // // Alternative:
    // \\error[test/three/3_multiline/6/labelled_multiline]: Test message
    // \\ --> src/path/to/file.something:2:5
    // \\1 |       pub fn fibonacci(n: i32) -> u64 {
    // \\  |  _____________________________________-
    // \\2 | |         if n < 0 {
    // \\  | |  _______^
    // \\3 | | |           panic!("{} is negative!", n);
    // \\  | | |  _________-
    // \\4 | | | |     } else if n == 0 {
    // \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    // \\  | | | |              -                             ^                  -
    // \\  | | | |______________|_____________________________|__________________|
    // \\  | | |                |                             |                  annotation 3
    // \\  | | |________________|_____________________________|                  second line
    // \\  | |                  |                             annotation 1
    // \\  | |__________________|                             fourth line
    // \\  |                    annotation 2
    // \\  |                    sixth line
    // \\6 |           } else if n == 1 {
    // \\
    );
}

test "6, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/6/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 154)),
            Annotation.secondary(0, Span.init(32, 124)),
            Annotation.secondary(0, Span.init(57, 173)),
        })
    },
    \\error[test/three/3_multiline/6/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | | | |              -                             ^                  -
    \\  | | | |______________|_____________________________|__________________|
    \\  | | |________________|_____________________________|
    \\  | |__________________|
    \\6 |           } else if n == 1 {
    \\
    );
}

test "7, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/7/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 154)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(32, 173)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(57, 124)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_multiline/7/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | | | |______________-                             ^                  -
    \\  | | |________________|_____________________________|                  |
    \\  | |__________________|_____________________________|__________________|
    \\  |                    |                             |                  annotation 2
    \\  |                    |                             annotation 1
    \\  |                    annotation 3
    \\6 |           } else if n == 1 {
    \\
    );
}

test "7, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/7/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 154)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(32, 173)).withLabel("annotation 2\nsecond line"),
            Annotation.secondary(0, Span.init(57, 124)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/3_multiline/7/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | | | |______________-                             ^                  -
    \\  | | |________________|_____________________________|                  |
    \\  | |__________________|_____________________________|__________________|
    \\  |                    |                             |                  annotation 2
    \\  |                    |                             |                  second line
    \\  |                    |                             annotation 1
    \\  |                    |                             fourth line
    \\  |                    annotation 3
    \\  |                    sixth line
    \\6 |           } else if n == 1 {
    \\
    );
}

test "7, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/7/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 154)),
            Annotation.secondary(0, Span.init(32, 173)),
            Annotation.secondary(0, Span.init(57, 124)),
        })
    },
    \\error[test/three/3_multiline/7/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | | | |______________-                             ^                  -
    \\  | | |______________________________________________|                  |
    \\  | |___________________________________________________________________|
    \\6 |           } else if n == 1 {
    \\
    );
}

test "8, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/8/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 220)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(32, 173)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(57, 124)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_multiline/8/labelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | | | |______________-                                                -
    \\  | |_|________________|________________________________________________|
    \\  |   |                |                                                annotation 2
    \\  |   |                annotation 3
    \\6 |   |       } else if n == 1 {
    \\7 |   |           return 1;
    \\8 |   |       }
    \\  |   |_______^ annotation 1
    \\9 |
    \\
    );
}

test "8, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/8/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 220)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(32, 173)).withLabel("annotation 2\nsecond line"),
            Annotation.secondary(0, Span.init(57, 124)).withLabel("annotation 3\nfourth line"),
        })
    },
    \\error[test/three/3_multiline/8/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | | | |______________-                                                -
    \\  | |_|________________|________________________________________________|
    \\  |   |                |                                                annotation 2
    \\  |   |                |                                                second line
    \\  |   |                annotation 3
    \\  |   |                fourth line
    \\6 |   |       } else if n == 1 {
    \\7 |   |           return 1;
    \\8 |   |       }
    \\  |   |_______^ annotation 1
    \\  |             sixth line
    \\9 |
    \\
    );
}

test "8, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_multiline/8/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(38, 220)),
            Annotation.secondary(0, Span.init(32, 173)),
            Annotation.secondary(0, Span.init(57, 124)),
        })
    },
    \\error[test/three/3_multiline/8/unlabelled]: Test message
    \\ --> src/path/to/file.something:2:5
    \\1 |       pub fn fibonacci(n: i32) -> u64 {
    \\  |  _____________________________________-
    \\2 | |         if n < 0 {
    \\  | |  _______^
    \\3 | | |           panic!("{} is negative!", n);
    \\  | | |  _________-
    \\4 | | | |     } else if n == 0 {
    \\5 | | | |         panic!("zero is not a right argument to fibonacci()!");
    \\  | | | |______________-                                                -
    \\  | |_|_________________________________________________________________|
    \\6 |   |       } else if n == 1 {
    \\7 |   |           return 1;
    \\8 |   |       }
    \\  |   |_______^
    \\9 |
    \\
    );
}
