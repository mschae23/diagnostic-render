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
        Diagnostic.err().withName("test/three/3_singleline/1/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(38, 40)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(57, 63)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_singleline/1/labelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\  | ^^^ annotation 1
    \\2 |     if n < 0 {
    \\  |     -- annotation 2
    \\3 |         panic!("{} is negative!", n);
    \\  |         ------ annotation 3
    \\4 |     } else if n == 0 {
    \\
    );
}

test "1, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/1/labelled_mutliline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)).withLabel("annotation 1\nsecond line"),
            Annotation.secondary(0, Span.init(38, 40)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(57, 63)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/3_singleline/1/labelled_mutliline]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\  | ^^^ annotation 1
    \\  |     second line
    \\2 |     if n < 0 {
    \\  |     -- annotation 2
    \\  |        fourth line
    \\3 |         panic!("{} is negative!", n);
    \\  |         ------ annotation 3
    \\  |                sixth line
    \\4 |     } else if n == 0 {
    \\
    );
}

test "1, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/1/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(0, 3)),
            Annotation.secondary(0, Span.init(38, 40)),
            Annotation.secondary(0, Span.init(57, 63)),
        })
    },
    \\error[test/three/3_singleline/1/unlabelled]: Test message
    \\ --> src/path/to/file.something:1:1
    \\1 | pub fn fibonacci(n: i32) -> u64 {
    \\  | ^^^
    \\2 |     if n < 0 {
    \\  |     --
    \\3 |         panic!("{} is negative!", n);
    \\  |         ------
    \\4 |     } else if n == 0 {
    \\
    );
}

test "2, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/2/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(205, 214)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(0, 3)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(390, 391)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_singleline/2/labelled]: Test message
    \\  --> src/path/to/file.something:7:9
    \\ 1 | pub fn fibonacci(n: i32) -> u64 {
    \\   | --- annotation 2
    \\ 2 |     if n < 0 {
    \\  ...
    \\ 6 |     } else if n == 1 {
    \\ 7 |         return 1;
    \\   |         ^^^^^^^^^ annotation 1
    \\ 8 |     }
    \\  ...
    \\18 |     sum
    \\19 | }
    \\   | - annotation 3
    \\
    );
}

test "2, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/2/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(205, 214)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(0, 3)).withLabel("annotation 2\nsecond line"),
            Annotation.secondary(0, Span.init(390, 391)).withLabel("annotation 3\nsixth line"),
        })
    },
    \\error[test/three/3_singleline/2/labelled_multiline]: Test message
    \\  --> src/path/to/file.something:7:9
    \\ 1 | pub fn fibonacci(n: i32) -> u64 {
    \\   | --- annotation 2
    \\   |     second line
    \\ 2 |     if n < 0 {
    \\  ...
    \\ 6 |     } else if n == 1 {
    \\ 7 |         return 1;
    \\   |         ^^^^^^^^^ annotation 1
    \\   |                   fourth line
    \\ 8 |     }
    \\  ...
    \\18 |     sum
    \\19 | }
    \\   | - annotation 3
    \\   |   sixth line
    \\
    );
}

test "2, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/2/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(205, 214)),
            Annotation.secondary(0, Span.init(0, 3)),
            Annotation.secondary(0, Span.init(390, 391)),
        })
    },
    \\error[test/three/3_singleline/2/unlabelled]: Test message
    \\  --> src/path/to/file.something:7:9
    \\ 1 | pub fn fibonacci(n: i32) -> u64 {
    \\   | ---
    \\ 2 |     if n < 0 {
    \\  ...
    \\ 6 |     } else if n == 1 {
    \\ 7 |         return 1;
    \\   |         ^^^^^^^^^
    \\ 8 |     }
    \\  ...
    \\18 |     sum
    \\19 | }
    \\   | -
    \\
    );
}

test "3, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/3/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(118, 124)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(134, 137)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_singleline/3/labelled]: Test message
    \\ --> src/path/to/file.something:5:9
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |         ^^^^^^          ---                     ----------- annotation 3
    \\  |         |               |
    \\  |         |               annotation 2
    \\  |         annotation 1
    \\6 |     } else if n == 1 {
    \\
    );
}

test "3, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/3/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(118, 124)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(134, 137)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/3_singleline/3/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:5:9
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |         ^^^^^^          ---                     ----------- annotation 3
    \\  |         |               |                                   second line
    \\  |         |               annotation 2
    \\  |         |               fourth line
    \\  |         annotation 1
    \\  |         sixth line
    \\6 |     } else if n == 1 {
    \\
    );
}

test "3, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/3/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(118, 124)),
            Annotation.secondary(0, Span.init(134, 137)),
            Annotation.secondary(0, Span.init(158, 169)),
        })
    },
    \\error[test/three/3_singleline/3/unlabelled]: Test message
    \\ --> src/path/to/file.something:5:9
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |         ^^^^^^          ---                     -----------
    \\6 |     } else if n == 1 {
    \\
    );
}

test "4, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/4/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(118, 124)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(134, 167)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_singleline/4/labelled]: Test message
    \\ --> src/path/to/file.something:5:9
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |         ^^^^^^          -----------------------------------
    \\  |         |               |                       |
    \\  |         |               |                       annotation 3
    \\  |         |               annotation 2
    \\  |         annotation 1
    \\6 |     } else if n == 1 {
    \\
    );
}

test "4, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/4/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(118, 124)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(134, 167)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/3_singleline/4/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:5:9
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |         ^^^^^^          -----------------------------------
    \\  |         |               |                       |
    \\  |         |               |                       annotation 3
    \\  |         |               |                       second line
    \\  |         |               annotation 2
    \\  |         |               fourth line
    \\  |         annotation 1
    \\  |         sixth line
    \\6 |     } else if n == 1 {
    \\
    );
}

test "4, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/4/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(118, 124)),
            Annotation.secondary(0, Span.init(134, 167)),
            Annotation.secondary(0, Span.init(158, 169)),
        })
    },
    \\error[test/three/3_singleline/4/unlabelled]: Test message
    \\ --> src/path/to/file.something:5:9
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |         ^^^^^^          -----------------------------------
    \\6 |     } else if n == 1 {
    \\
    );
}

test "5, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/5/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(134, 154)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(118, 124)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_singleline/5/labelled]: Test message
    \\ --> src/path/to/file.something:5:25
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |         ------          ^^^^^^^^^^^^^^^^^^^^    ----------- annotation 3
    \\  |         |               |
    \\  |         |               annotation 1
    \\  |         annotation 2
    \\6 |     } else if n == 1 {
    \\
    );
}

test "5, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/5/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(134, 154)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(118, 124)).withLabel("annotation 2\nsixth line"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/3_singleline/5/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:5:25
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |         ------          ^^^^^^^^^^^^^^^^^^^^    ----------- annotation 3
    \\  |         |               |                                   second line
    \\  |         |               annotation 1
    \\  |         |               fourth line
    \\  |         annotation 2
    \\  |         sixth line
    \\6 |     } else if n == 1 {
    \\
    );
}

test "5, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/5/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(134, 154)),
            Annotation.secondary(0, Span.init(118, 124)),
            Annotation.secondary(0, Span.init(158, 169)),
        })
    },
    \\error[test/three/3_singleline/5/unlabelled]: Test message
    \\ --> src/path/to/file.something:5:25
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |         ------          ^^^^^^^^^^^^^^^^^^^^    -----------
    \\6 |     } else if n == 1 {
    \\
    );
}

test "6, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/6/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(134, 137)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(126, 154)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_singleline/6/labelled]: Test message
    \\ --> src/path/to/file.something:5:25
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |                 --------^^^-----------------    ----------- annotation 3
    \\  |                 |       |
    \\  |                 |       annotation 1
    \\  |                 annotation 2
    \\6 |     } else if n == 1 {
    \\
    );
}

test "6, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/6/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(134, 137)).withLabel("annotation 1\nfourth line"),
            Annotation.secondary(0, Span.init(126, 154)).withLabel("annotation 2\nsixth line"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/3_singleline/6/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:5:25
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |                 --------^^^-----------------    ----------- annotation 3
    \\  |                 |       |                                   second line
    \\  |                 |       annotation 1
    \\  |                 |       fourth line
    \\  |                 annotation 2
    \\  |                 sixth line
    \\6 |     } else if n == 1 {
    \\
    );
}

test "6, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/6/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(134, 137)),
            Annotation.secondary(0, Span.init(126, 154)),
            Annotation.secondary(0, Span.init(158, 169)),
        })
    },
    \\error[test/three/3_singleline/6/unlabelled]: Test message
    \\ --> src/path/to/file.something:5:25
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |                 --------^^^-----------------    -----------
    \\6 |     } else if n == 1 {
    \\
    );
}

test "7, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/7/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(126, 154)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(134, 137)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_singleline/7/labelled]: Test message
    \\ --> src/path/to/file.something:5:17
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |                 ^^^^^^^^---^^^^^^^^^^^^^^^^^    ----------- annotation 3
    \\  |                 |       |
    \\  |                 |       annotation 2
    \\  |                 annotation 1
    \\6 |     } else if n == 1 {
    \\
    );
}

test "7, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/7/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(126, 154)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(134, 137)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(158, 169)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/3_singleline/7/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:5:17
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |                 ^^^^^^^^---^^^^^^^^^^^^^^^^^    ----------- annotation 3
    \\  |                 |       |                                   second line
    \\  |                 |       annotation 2
    \\  |                 |       fourth line
    \\  |                 annotation 1
    \\  |                 sixth line
    \\6 |     } else if n == 1 {
    \\
    );
}

test "7, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/7/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(126, 154)),
            Annotation.secondary(0, Span.init(134, 137)),
            Annotation.secondary(0, Span.init(158, 169)),
        })
    },
    \\error[test/three/3_singleline/7/unlabelled]: Test message
    \\ --> src/path/to/file.something:5:17
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |                 ^^^^^^^^---^^^^^^^^^^^^^^^^^    -----------
    \\6 |     } else if n == 1 {
    \\
    );
}

test "8, labelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/8/labelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(126, 154)).withLabel("annotation 1"),
            Annotation.secondary(0, Span.init(134, 137)).withLabel("annotation 2"),
            Annotation.secondary(0, Span.init(146, 169)).withLabel("annotation 3"),
        })
    },
    \\error[test/three/3_singleline/8/labelled]: Test message
    \\ --> src/path/to/file.something:5:17
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |                 ^^^^^^^^---^^^^^^^^^-------^---------------
    \\  |                 |       |           |
    \\  |                 |       |           annotation 3
    \\  |                 |       annotation 2
    \\  |                 annotation 1
    \\6 |     } else if n == 1 {
    \\
    );
}

test "8, labelled multiline" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/8/labelled_multiline").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(126, 154)).withLabel("annotation 1\nsixth line"),
            Annotation.secondary(0, Span.init(134, 137)).withLabel("annotation 2\nfourth line"),
            Annotation.secondary(0, Span.init(146, 169)).withLabel("annotation 3\nsecond line"),
        })
    },
    \\error[test/three/3_singleline/8/labelled_multiline]: Test message
    \\ --> src/path/to/file.something:5:17
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |                 ^^^^^^^^---^^^^^^^^^-------^---------------
    \\  |                 |       |           |
    \\  |                 |       |           annotation 3
    \\  |                 |       |           second line
    \\  |                 |       annotation 2
    \\  |                 |       fourth line
    \\  |                 annotation 1
    \\  |                 sixth line
    \\6 |     } else if n == 1 {
    \\
    );
}

test "8, unlabelled" {
    try runTest("src/path/to/file.something", fibonacci_input, &.{
        Diagnostic.err().withName("test/three/3_singleline/8/unlabelled").withMessage("Test message").withAnnotations(&.{
            Annotation.primary(0, Span.init(126, 154)),
            Annotation.secondary(0, Span.init(134, 137)),
            Annotation.secondary(0, Span.init(146, 169)),
        })
    },
    \\error[test/three/3_singleline/8/unlabelled]: Test message
    \\ --> src/path/to/file.something:5:17
    \\4 |     } else if n == 0 {
    \\5 |         panic!("zero is not a right argument to fibonacci()!");
    \\  |                 ^^^^^^^^---^^^^^^^^^-------^---------------
    \\6 |     } else if n == 1 {
    \\
    );
}
