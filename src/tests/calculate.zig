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
const io = @import("../io.zig");
const file = @import("../file.zig");
const LineColumn = file.LineColumn;
const diag = @import("../diagnostic.zig");
const Annotation = diag.Annotation(usize);
const Diagnostic = diag.Diagnostic(usize);
const Span = diag.Span;

const calculate = @import("../render/calculate/mod.zig");
const LocatedAnnotation = calculate.LocatedAnnotation;
const ContinuingMultilineAnnotationData = calculate.ContinuingMultilineAnnotationData;
const ConnectingMultilineAnnotationData = calculate.ConnectingMultilineAnnotationData;
const StartAnnotationData = calculate.StartAnnotationData;
const ConnectingSinglelineAnnotationData = calculate.ConnectingSinglelineAnnotationData;
const EndAnnotationData = calculate.EndAnnotationData;
const HangingAnnotationData = calculate.HangingAnnotationData;
const LabelAnnotationData = calculate.LabelAnnotationData;
const BothAnnotationData = calculate.BothAnnotationData;
const StartEndAnnotationData = calculate.StartEndAnnotationData;
const AnnotationData = calculate.AnnotationData;
const StartEnd = calculate.StartEnd(usize);
const VerticalOffset = calculate.VerticalOffset;

pub const vertical_offsets = struct {
    fn runTest(starts_ends: []const StartEnd, expected: []const VerticalOffset) !void {
        var actual = try calculate.calculateVerticalOffsets(usize, std.testing.allocator, starts_ends);
        defer actual.deinit(std.testing.allocator);

        try std.testing.expectEqualSlices(VerticalOffset, expected, actual.items);
    }

    pub const singleline = struct {
        test "1" {
            const annotation1 = Annotation.primary(0, Span.init(3, 12)).withLabel("expected type annotation here");
            const annotation2 = Annotation.secondary(0, Span.init(28, 21)).withLabel("due to this");

            // 1 | let main = 23;
            //   |    ^^^^^^^^^^ expected type annotation here
            // 2 | something += 3.0;
            //   |              --- due to this

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .both = .{
                        .start = StartAnnotationData {
                            .style = annotation1.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 3),
                        },
                        .end = EndAnnotationData {
                            .style = annotation1.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 12),
                        },
                    }},
                    .vertical_bar_index = null,
                },
            }, &.{VerticalOffset { .connection = 0, .label = 0, }});
            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .both = .{
                        .start = StartAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(1, 13),
                        },
                        .end = EndAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(1, 16),
                        },
                    }},
                    .vertical_bar_index = null,
                },
            }, &.{VerticalOffset { .connection = 0, .label = 0, }});
        }

        test "2" {
            const annotation1 = Annotation.primary(0, Span.init(11, 13)).withLabel("number");
            const annotation2 = Annotation.secondary(0, Span.init(4, 8)).withLabel("identifier");

            // 1 | let main = 23;
            //   |     ----   ^^ number
            //   |     |
            //   |     identifier

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .both = .{
                        .start = StartAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 4),
                        },
                        .end = EndAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 8),
                        },
                    }},
                    .vertical_bar_index = null,
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .both = .{
                        .start = StartAnnotationData {
                            .style = annotation1.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 11),
                        },
                        .end = EndAnnotationData {
                            .style = annotation1.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 13),
                        },
                    }},
                    .vertical_bar_index = null,
                },
            }, &.{
                VerticalOffset { .connection = 1, .label = 2, },
                VerticalOffset { .connection = 0, .label = 0, },
            });
        }

        test "overlapping 1" {
            const annotation1 = Annotation.primary(0, Span.init(4, 13)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(8, 11)).withLabel("something else");

            // 1 | let main = 23;
            //   |     ^^^^---^^
            //   |     |   |
            //   |     |   something else
            //   |     something

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .both = .{
                        .start = StartAnnotationData {
                            .style = annotation1.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 4),
                        },
                        .end = EndAnnotationData {
                            .style = annotation1.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 13),
                        },
                    }},
                    .vertical_bar_index = null,
                },
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .both = .{
                        .start = StartAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 8),
                        },
                        .end = EndAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 11),
                        },
                    }},
                    .vertical_bar_index = null,
                },
            }, &.{
                VerticalOffset { .connection = 2, .label = 3, },
                VerticalOffset { .connection = 1, .label = 2, },
            });
        }
    };

    pub const ending = struct {
        test "1" {
            const annotation1 = Annotation.primary(0, Span.init(0, 19)).withLabel("something");

            // 2 | | something += 3.0;
            //   | |_____^ something

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .end = .{
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 4),
                    }},
                    .vertical_bar_index = 0,
                },
            }, &.{
                VerticalOffset { .connection = 0, .label = 0, },
            });
        }

        test "2" {
            const annotation1 = Annotation.primary(0, Span.init(0, 28)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 19)).withLabel("something else");

            // 1 |     let main = 23;    // Vertical offsets for annotations on this line are not tested by this test
            //   |  ___^   -
            //   | |  _____|
            // 2 | | | something += 3.0;
            //   | | |_____-        ^
            //   | |_______|________|
            //   |         |        something
            //   |         something else

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .end = .{
                        .style = annotation2.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 4),
                    }},
                    .vertical_bar_index = 1,
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .end = .{
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 13),
                    }},
                    .vertical_bar_index = 0,
                },
            }, &.{
                VerticalOffset { .connection = 0, .label = 3, },
                VerticalOffset { .connection = 1, .label = 2, },
            });
        }

        test "2 no label" {
            const annotation1 = Annotation.primary(0, Span.init(0, 28)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 19));

            // 1 |     let main = 23;    // Vertical offsets for annotations on this line are not tested by this test
            //   |  ___^   -
            //   | |  _____|
            // 2 | | | something += 3.0;
            //   | | |_____-        ^
            //   | |________________|
            //   |                  something

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .end = .{
                        .style = annotation2.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 4),
                    }},
                    .vertical_bar_index = 1,
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .end = .{
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 13),
                    }},
                    .vertical_bar_index = 0,
                },
            }, &.{
                VerticalOffset { .connection = 0, .label = 0, },
                VerticalOffset { .connection = 1, .label = 2, },
            });
        }

        test "overlapping 1" {
            const annotation1 = Annotation.primary(0, Span.init(0, 19)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 28)).withLabel("something else");

            // 1 |     let main = 23;    // Vertical offsets for annotations on this line are not tested by this test
            //   |  ___^   -
            //   | |  _____|
            // 2 | | | something += 3.0;
            //   | | |     ^        -
            //   | | |_____|________|
            //   | |_______|        something else
            //   |         something

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .end = .{
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 4),
                    }},
                    .vertical_bar_index = 0,
                },
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .end = .{
                        .style = annotation2.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 13),
                    }},
                    .vertical_bar_index = 1,
                },
            }, &.{
                VerticalOffset { .connection = 2, .label = 3, },
                VerticalOffset { .connection = 1, .label = 2, },
            });
        }

        test "between 1" {
            const annotation1 = Annotation.primary(0, Span.init(0, 26)).withLabel("primary");
            const annotation2 = Annotation.secondary(0, Span.init(15, 24)).withLabel("secondary");
            const annotation3 = Annotation.secondary(0, Span.init(28, 31)).withLabel("secondary");

            // 1 |   let main = 23;    // Vertical offsets for annotations on this line are not tested by this test
            //   |  _^
            //   | |
            // 2 | | something += 3.0;
            //   | | --------- ^  --- secondary 1
            //   | |_|_________|
            //   |   |         primary
            //   |   secondary 2

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .both = .{
                        .start = StartAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(1, 0),
                        },
                        .end = EndAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(1, 9),
                        },
                    }},
                    .vertical_bar_index = null,
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .end = .{
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 11),
                    }},
                    .vertical_bar_index = 0,
                },
                StartEnd {
                    .annotation = &annotation3,
                    .data = StartEndAnnotationData { .both = .{
                        .start = StartAnnotationData {
                            .style = annotation3.style,
                            .severity = .@"error",
                            .location = LineColumn.init(1, 13),
                        },
                        .end = EndAnnotationData {
                            .style = annotation3.style,
                            .severity = .@"error",
                            .location = LineColumn.init(1, 16),
                        },
                    }},
                    .vertical_bar_index = null,
                },
            }, &.{
                VerticalOffset { .connection = 2, .label = 3, },
                VerticalOffset { .connection = 1, .label = 2, },
                VerticalOffset { .connection = 0, .label = 0, },
            });
        }
    };

    pub const starting = struct {
        test "simple 1" {
            const annotation1 = Annotation.primary(0, Span.init(4, 28)).withLabel("something");

            // 1 |   let main = 23;
            //   |  _____^
            // 2 | | ...

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .start = .{
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(0, 4),
                    }},
                    .vertical_bar_index = 0,
                },
            }, &.{
                VerticalOffset { .connection = 0, .label = 0, },
            });
        }

        test "1" {
            const annotation1 = Annotation.primary(0, Span.init(11, 28)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 8)).withLabel("something else");

            // 1 |   let main = 23;
            //   |       ----   ^
            //   |  _____|______|
            //   | |     |
            //   | |     something else
            // 2 | | ...

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .both = .{
                        .start = StartAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 4),
                        },
                        .end = EndAnnotationData {
                            .style = annotation2.style,
                            .severity = .@"error",
                            .location = LineColumn.init(0, 8),
                        },
                    }},
                    .vertical_bar_index = null,
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .start = .{
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(0, 11),
                    }},
                    .vertical_bar_index = 0,
                },
            }, &.{
                VerticalOffset { .connection = 2, .label = 3, },
                VerticalOffset { .connection = 1, .label = 0, },
            });
        }

        test "with ending 1" {
            const annotation1 = Annotation.primary(0, Span.init(28, 38)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(11, 24)).withLabel("something else");

            // 1 |   let main = 23; // This line is not tested by this test
            //   |  ____________-
            // 2 | | something += 3.0;
            //   | |_________-    ^
            //   |  _________|____|
            //   | |         |
            //   | |         something else
            // 3 | | ...

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .end = .{
                        .style = annotation2.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 9),
                    }},
                    .vertical_bar_index = 0,
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .start = .{
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 13),
                    }},
                    .vertical_bar_index = 0,
                },
            }, &.{
                VerticalOffset { .connection = 0, .label = 3, },
                VerticalOffset { .connection = 1, .label = 0, },
            });
        }
    };
};

pub const final = struct {
    fn runTest(input: []const u8, diagnostic: *const Diagnostic, line_index: usize, continuing_annotations: []const ?*const Annotation, active_annotations: []const LocatedAnnotation(usize), expected: []const AnnotationData) !void {
        var fbs = std.io.fixedBufferStream(input);

        var file_hashmap = std.AutoHashMap(usize, file.FileData).init(std.testing.allocator);
        try file_hashmap.put(0, file.FileData {
            .name = "/tmp/test",
            .reader = fbs.reader().any(),
            .seeker = io.anySeekableStream(@TypeOf(fbs), *@TypeOf(fbs), &&fbs),
        });
        defer file_hashmap.deinit();

        var files = try file.Files(usize).init(std.testing.allocator, &file_hashmap);
        defer files.deinit();

        var actual = try calculate.calculate(usize, std.testing.allocator, diagnostic, line_index, continuing_annotations, active_annotations);
        defer actual.deinit(std.testing.allocator);

        try std.testing.expectEqualSlices(AnnotationData, expected, actual.items);
    }

    pub const singleline = struct {
        test "1" {
            const input = "test file contents";

            const annotation = Annotation.primary(0, Span.init(5, 9)).withLabel("test label");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation});

            // 1 | test file contents
            //   |      ^^^^ test label

            try runTest(input, &diagnostic, 0, &.{}, &.{.{ .annotation = &annotation, .vertical_bar_index = null, .start_location = LineColumn.init(0, 5), .end_location = LineColumn.init(0, 8), }}, &.{
                AnnotationData { .start = .{
                    .style = annotation.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 5),
                }},
                AnnotationData { .connecting_singleline = .{
                    .style = annotation.style, .as_multiline = false,
                    .severity = diagnostic.severity,
                    .line_index = 0,
                    .start_column_index = 5, .end_column_index = 8,
                }},
                AnnotationData { .end = .{
                    .style = annotation.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 8),
                }},
                AnnotationData { .label = .{
                    .style = annotation.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 10),
                    .label = "test label",
                }},
                AnnotationData.newline,
            });
        }

        test "separate lines 1" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(3, 13)).withLabel("expected type annotation here");
            const annotation2 = Annotation.secondary(0, Span.init(28, 31)).withLabel("due to this");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1, annotation2});

            // 1 | let main = 23;
            //   |    ^^^^^^^^^^ expected type annotation here
            // 2 | something += 3.0;
            //   |              --- due to this

            try runTest(input, &diagnostic, 0, &.{}, &.{.{ .annotation = &annotation1, .vertical_bar_index = null, .start_location = LineColumn.init(0, 3), .end_location = LineColumn.init(0, 12), }}, &.{
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 3),
                }},
                AnnotationData { .connecting_singleline = .{
                    .style = annotation1.style, .as_multiline = false,
                    .severity = diagnostic.severity,
                    .line_index = 0,
                    .start_column_index = 3, .end_column_index = 12,
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 12),
                }},
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 14),
                    .label = "expected type annotation here",
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{}, &.{.{ .annotation = &annotation2, .vertical_bar_index = null, .start_location = LineColumn.init(1, 13), .end_location = LineColumn.init(1, 15), }}, &.{
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData { .connecting_singleline = .{
                    .style = annotation2.style, .as_multiline = false,
                    .severity = diagnostic.severity,
                    .line_index = 1,
                    .start_column_index = 13, .end_column_index = 15,
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 15),
                }},
                AnnotationData { .label = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 17),
                    .label = "due to this",
                }},
                AnnotationData.newline,
            });
        }

        test "same line 1" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(11, 13)).withLabel("number");
            const annotation2 = Annotation.secondary(0, Span.init(4, 8)).withLabel("identifier");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1, annotation2});

            // 1 | let main = 23;
            //   |     ----   ^^ number
            //   |     |
            //   |     identifier

            try runTest(input, &diagnostic, 0, &.{}, &.{.{ .annotation = &annotation1, .vertical_bar_index = null, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(0, 12), }, .{ .annotation = &annotation2, .vertical_bar_index = null, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(0, 7), }}, &.{
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData { .connecting_singleline = .{
                    .style = annotation2.style, .as_multiline = false,
                    .severity = diagnostic.severity,
                    .line_index = 0,
                    .start_column_index = 4, .end_column_index = 7,
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 7),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 11),
                }},
                AnnotationData { .connecting_singleline = .{
                    .style = annotation1.style, .as_multiline = false,
                    .severity = diagnostic.severity,
                    .line_index = 0,
                    .start_column_index = 11, .end_column_index = 12,
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 12),
                }},
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 14),
                    .label = "number",
                }},
                AnnotationData.newline,
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
                AnnotationData { .label = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                    .label = "identifier",
                }},
                AnnotationData.newline,
            });
        }

        test "overlapping 1" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(4, 13)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(8, 11)).withLabel("something else");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1, annotation2});

            // 1 | let main = 23;
            //   |     ^^^^---^^
            //   |     |   |
            //   |     |   something else
            //   |     something

            try runTest(input, &diagnostic, 0, &.{}, &.{.{ .annotation = &annotation1, .vertical_bar_index = null, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(0, 12), }, .{ .annotation = &annotation2, .vertical_bar_index = null, .start_location = LineColumn.init(0, 8), .end_location = LineColumn.init(0, 10), }}, &.{
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData { .connecting_singleline = .{
                    .style = annotation1.style, .as_multiline = false,
                    .severity = diagnostic.severity,
                    .line_index = 0,
                    .start_column_index = 4, .end_column_index = 12,
                }},
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 8),
                }},
                AnnotationData { .connecting_singleline = .{
                    .style = annotation2.style, .as_multiline = false,
                    .severity = diagnostic.severity,
                    .line_index = 0,
                    .start_column_index = 8, .end_column_index = 10,
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 10),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 12),
                }},
                AnnotationData.newline,
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 8),
                }},
                AnnotationData.newline,
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData { .label = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 8),
                    .label = "something else",
                }},
                AnnotationData.newline,
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                    .label = "something",
                }},
                AnnotationData.newline,
            });
        }
    };

    pub const ending = struct {
        test "1" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(0, 19)).withLabel("something");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1});

            // 1 |   let main = 23;
            //   |  _^
            // 2 | | something += 3.0;
            //   | |____^

            try runTest(input, &diagnostic, 0, &.{null}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 3), }}, &.{
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 0),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation1}, &.{.{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 3), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 3),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 5),
                    .label = "something",
                }},
                AnnotationData.newline,
            });
        }

        test "2" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(0, 27)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 19)).withLabel("something else");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1});

            // 1 |     let main = 23;
            //   |  ___^   -
            //   | |  _____|
            // 2 | | | something += 3.0;
            //   | | |____-       ^
            //   | |______|_______|
            //   |        |       something
            //   |        something else

            try runTest(input, &diagnostic, 0, &.{null}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 11), }, .{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 3), }}, &.{
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(0, 4),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation1, &annotation2}, &.{.{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 3), }, .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 11), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(1, 3),
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 11),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 11),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 11),
                }},
                AnnotationData.newline,
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 11),
                    .label = "something",
                }},
                AnnotationData.newline,
                AnnotationData { .label = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                    .label = "something else",
                }},
                AnnotationData.newline,
            });
        }

        test "2 no label" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(0, 27));
            const annotation2 = Annotation.secondary(0, Span.init(4, 19));
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1});

            // 1 |     let main = 23;
            //   |  ___^   -
            //   | |  _____|
            // 2 | | | something += 3.0;
            //   | | |_____-      ^
            //   | |______________|

            try runTest(input, &diagnostic, 0, &.{null}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 11), }, .{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 3), }}, &.{
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(0, 4),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation1, &annotation2}, &.{.{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 3), }, .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 11), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(1, 3),
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 11),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 11),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 11),
                }},
                AnnotationData.newline,
            });
        }

        test "overlapping 1" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(0, 19)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 29)).withLabel("something else");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1});

            // 1 |     let main = 23;
            //   |  ___^   -
            //   | |  _____|
            // 2 | | | something += 3.0;
            //   | | |    ^         -
            //   | | |____|_________|
            //   | |______|         something else
            //   |        something else

            try runTest(input, &diagnostic, 0, &.{null, null}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 3), }, .{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(0, 4),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation1, &annotation2}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 3), }, .{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(1, 13),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 3),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .label = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                    .label = "something else",
                }},
                AnnotationData.newline,
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                    .label = "something",
                }},
                AnnotationData.newline,
            });
        }

        test "overlapping 1 no label" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(0, 19));
            const annotation2 = Annotation.secondary(0, Span.init(4, 29));
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1});

            // 1 |     let main = 23;
            //   |  ___^   -
            //   | |  _____|
            // 2 | | | something += 3.0;
            //   | | |     ^        -
            //   | | |_____|________|
            //   | |_______|

            try runTest(input, &diagnostic, 0, &.{null, null}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 3), }, .{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(0, 4),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation1, &annotation2}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(1, 3), }, .{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(1, 13),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 3),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 3),
                }},
                AnnotationData.newline,
            });
        }
    };

    pub const starting = struct {
        test "simple 1" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(4, 29)).withLabel("something");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1});

            // 1 |   let main = 23;
            //   |  _____^
            // 2 | | something += 3.0;
            //   | |______________^ something

            try runTest(input, &diagnostic, 0, &.{null}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 4),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation1}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 13),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 15),
                    .label = "something",
                }},
                AnnotationData.newline,
            });
        }

        test "1" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(11, 29)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 8)).withLabel("something else");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1, annotation2});

            // 1 |   let main = 23;
            //   |       ----   ^
            //   |  _____|______|
            //   | |     |
            //   | |     something else
            // 2 | | something += 3.0;
            //   | |______________^ something

            try runTest(input, &diagnostic, 0, &.{null}, &.{ .{ .annotation = &annotation2, .vertical_bar_index = null, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(0, 7), }, .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData { .connecting_singleline = .{
                    .style = annotation2.style, .as_multiline = false,
                    .severity = diagnostic.severity,
                    .line_index = 0,
                    .start_column_index = 4, .end_column_index = 7,
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 7),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 11),
                }},
                AnnotationData.newline,
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 11),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 11),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .label = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                    .label = "something else",
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation1}, &.{.{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 13),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 15),
                    .label = "something",
                }},
                AnnotationData.newline,
            });
        }

        test "1 no label" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(11, 29)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 8));
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1, annotation2});

            // 1 |   let main = 23;
            //   |       ----   ^
            //   |  ____________|
            // 2 | | something += 3.0;
            //   | |______________^ something

            try runTest(input, &diagnostic, 0, &.{null}, &.{ .{ .annotation = &annotation2, .vertical_bar_index = null, .start_location = LineColumn.init(0, 4), .end_location = LineColumn.init(0, 7), }, .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 4),
                }},
                AnnotationData { .connecting_singleline = .{
                    .style = annotation2.style, .as_multiline = false,
                    .severity = diagnostic.severity,
                    .line_index = 0,
                    .start_column_index = 4, .end_column_index = 7,
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 7),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 11),
                }},
                AnnotationData.newline,
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 11),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 11),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation1}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 13), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 13),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 15),
                    .label = "something",
                }},
                AnnotationData.newline,
            });
        }

        test "with ending 1" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(28, 38)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(11, 24)).withLabel("something else");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1, annotation2});

            // 1 |   let main = 23;
            //   |  ____________-
            // 2 | | something += 3.0;
            //   | |_________-    ^
            //   |  _________|____|
            //   | |         |
            //   | |         something else
            // 3 | | print(example_source);
            //   | |_____^ something

            try runTest(input, &diagnostic, 0, &.{null}, &.{ .{ .annotation = &annotation2, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 8), }}, &.{
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 11),
                }},
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 11),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation2}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(1, 13), .end_location = LineColumn.init(2, 4), }, .{ .annotation = &annotation2, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 8), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 8),
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 8),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 13),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 8),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 8),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .label = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 8),
                    .label = "something else",
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 2, &.{&annotation1}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(1, 13), .end_location = LineColumn.init(2, 4), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(2, 4),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 4),
                }},
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 6),
                    .label = "something",
                }},
                AnnotationData.newline,
            });
        }

        test "with ending 1 no label" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(28, 38));
            const annotation2 = Annotation.secondary(0, Span.init(11, 24));
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1, annotation2});

            // 1 |   let main = 23;
            //   |  ____________-
            // 2 | | something += 3.0;
            //   | |_________-    ^
            //   |  ______________|
            // 3 | | print(example_source);
            //   | |_____^

            try runTest(input, &diagnostic, 0, &.{null}, &.{ .{ .annotation = &annotation2, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 8), }}, &.{
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 11),
                }},
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 11),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation2}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(1, 13), .end_location = LineColumn.init(2, 4), }, .{ .annotation = &annotation2, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 8), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 8),
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 8),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(1, 13),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 2, &.{&annotation1}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 0, .start_location = LineColumn.init(1, 13), .end_location = LineColumn.init(2, 4), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(2, 4),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 4),
                }},
                AnnotationData.newline,
            });
        }

        test "with ending and full 1" {
            const input =
                \\let main = 23;
                \\something += 3.0;
                \\print(example_source);
            ++ "\n";

            const annotation1 = Annotation.primary(0, Span.init(28, 38)).withLabel("something");
            const annotation2 = Annotation.secondary(0, Span.init(11, 24)).withLabel("something else");
            const annotation3 = Annotation.secondary(0, Span.init(0, input.len - 1)).withLabel("full program");
            const diagnostic = Diagnostic.err().withAnnotations(&.{annotation1, annotation2, annotation3});

            // 1 |   let main = 23;
            //   |  _-          -
            //   | |  __________|
            // 2 | | | something += 3.0;
            //   | | |_________-    ^
            //   | |  _________|____|
            //   | | |         |
            //   | | |         something else
            // 3 | | | print(example_source);
            //   | | |_____^                -
            //   | |_______|________________|
            //   |         |                full program
            //   |         something

            try runTest(input, &diagnostic, 0, &.{null, null}, &.{ .{ .annotation = &annotation3, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(2, 21), }, .{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 8), }}, &.{
                AnnotationData { .connecting_multiline = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 0),
                }},
                AnnotationData { .start = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 11),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(0, 11),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(0, 11),
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 1, &.{&annotation3, &annotation2}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 1, .start_location = LineColumn.init(1, 13), .end_location = LineColumn.init(2, 4), }, .{ .annotation = &annotation2, .vertical_bar_index = 1, .start_location = LineColumn.init(0, 11), .end_location = LineColumn.init(1, 8), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(1, 8),
                }},
                AnnotationData { .end = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 8),
                }},
                AnnotationData { .start = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(1, 13),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 8),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 13),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .hanging = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 8),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .label = .{
                    .style = annotation2.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(1, 8),
                    .label = "something else",
                }},
                AnnotationData.newline,
            });
            try runTest(input, &diagnostic, 2, &.{&annotation3, &annotation1}, &.{ .{ .annotation = &annotation1, .vertical_bar_index = 1, .start_location = LineColumn.init(1, 13), .end_location = LineColumn.init(2, 4), }, .{ .annotation = &annotation3, .vertical_bar_index = 0, .start_location = LineColumn.init(0, 0), .end_location = LineColumn.init(2, 21), }}, &.{
                AnnotationData { .continuing_multiline = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .continuing_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 1,
                    .end_location = LineColumn.init(2, 4),
                }},
                AnnotationData { .end = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 4),
                }},
                AnnotationData { .end = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 21),
                }},
                AnnotationData.newline,
                AnnotationData { .continuing_multiline = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                }},
                AnnotationData { .connecting_multiline = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .vertical_bar_index = 0,
                    .end_location = LineColumn.init(2, 21),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 4),
                }},
                AnnotationData { .hanging = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 21),
                }},
                AnnotationData.newline,
                AnnotationData { .hanging = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 4),
                }},
                AnnotationData { .label = .{
                    .style = annotation3.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 21),
                    .label = "full program",
                }},
                AnnotationData.newline,
                AnnotationData { .label = .{
                    .style = annotation1.style,
                    .severity = diagnostic.severity,
                    .location = LineColumn.init(2, 4),
                    .label = "something",
                }},
                AnnotationData.newline,
            });
        }
    };
};
