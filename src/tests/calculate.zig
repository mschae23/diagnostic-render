const std = @import("std");
const io = @import("../io.zig");
const file = @import("../file.zig");
const LineColumn = file.LineColumn;
const diag = @import("../diagnostic.zig");
const Annotation = diag.Annotation(usize);
const Span = diag.Span;

const calculate = @import("../render/calculate/mod.zig");
const StartAnnotationData = calculate.StartAnnotationData;
const EndAnnotationData = calculate.EndAnnotationData;
const BothAnnotationData = calculate.BothAnnotationData;
const StartEndAnnotationData = calculate.StartEndAnnotationData;
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
            const annotation1 = Annotation.primary(0, Span.init(3, 12)).with_label("expected type annotation here");
            const annotation2 = Annotation.secondary(0, Span.init(28, 21)).with_label("due to this");

            // 1 | let main = 23;
            //   |    ^^^^^^^^^^ expected type annotation here
            // 2 | something += 3.0;
            //   |              --- due to this

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .both = BothAnnotationData {
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
                },
            }, &.{VerticalOffset { .connection = 0, .label = 0, }});
            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .both = BothAnnotationData {
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
                },
            }, &.{VerticalOffset { .connection = 0, .label = 0, }});
        }

        test "2" {
            const annotation1 = Annotation.primary(0, Span.init(11, 13)).with_label("number");
            const annotation2 = Annotation.secondary(0, Span.init(4, 8)).with_label("identifier");

            // 1 | let main = 23;
            //   |     ----   ^^ number
            //   |     |
            //   |     identifier

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .both = BothAnnotationData {
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
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .both = BothAnnotationData {
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
                },
            }, &.{
                VerticalOffset { .connection = 1, .label = 2, },
                VerticalOffset { .connection = 0, .label = 0, },
            });
        }

        test "overlapping 1" {
            const annotation1 = Annotation.primary(0, Span.init(4, 13)).with_label("something");
            const annotation2 = Annotation.secondary(0, Span.init(8, 11)).with_label("something else");

            // 1 | let main = 23;
            //   |     ^^^^---^^
            //   |     |   |
            //   |     |   something else
            //   |     something

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .both = BothAnnotationData {
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
                },
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .both = BothAnnotationData {
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
                },
            }, &.{
                VerticalOffset { .connection = 2, .label = 3, },
                VerticalOffset { .connection = 1, .label = 2, },
            });
        }
    };

    pub const ending = struct {
        test "1" {
            const annotation1 = Annotation.primary(0, Span.init(0, 19)).with_label("something");

            // 2 | | something += 3.0;
            //   | |_____^ something

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .end = EndAnnotationData {
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 4),
                    }},
                },
            }, &.{
                VerticalOffset { .connection = 0, .label = 0, },
            });
        }

        test "2" {
            const annotation1 = Annotation.primary(0, Span.init(0, 28)).with_label("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 19)).with_label("something else");

            // 1 |     let main = 23;    // Vertical offsets for annotations on this line are not tested by this test
            //   |  ___^   -
            //   | |  _____|
            // 2 | | | something += 3.0;
            //   | | |     -        ^
            //   | | |_____|________|
            //   | |_______|        something
            //   |         something else

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .end = EndAnnotationData {
                        .style = annotation2.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 4),
                    }},
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .end = EndAnnotationData {
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 13),
                    }},
                },
            }, &.{
                VerticalOffset { .connection = 2, .label = 3, },
                VerticalOffset { .connection = 1, .label = 2, },
            });
        }

        test "overlapping 1" {
            const annotation1 = Annotation.primary(0, Span.init(0, 19)).with_label("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 28)).with_label("something else");

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
                    .data = StartEndAnnotationData { .end = EndAnnotationData {
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 4),
                    }},
                },
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .end = EndAnnotationData {
                        .style = annotation2.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 13),
                    }},
                },
            }, &.{
                VerticalOffset { .connection = 2, .label = 3, },
                VerticalOffset { .connection = 1, .label = 2, },
            });
        }
    };

    pub const starting = struct {
        test "simple 1" {
            const annotation1 = Annotation.primary(0, Span.init(4, 28)).with_label("something");

            // 1 |   let main = 23;
            //   |  _____^
            // 2 | | ...

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .start = StartAnnotationData {
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(0, 4),
                    }},
                },
            }, &.{
                VerticalOffset { .connection = 0, .label = 0, },
            });
        }

        test "1" {
            const annotation1 = Annotation.primary(0, Span.init(11, 28)).with_label("something");
            const annotation2 = Annotation.secondary(0, Span.init(4, 8)).with_label("something else");

            // 1 |   let main = 23;
            //   |       ----   ^
            //   |  _____|______|
            //   | |     |
            //   | |     something else
            // 2 | | ...

            try runTest(&.{
                StartEnd {
                    .annotation = &annotation2,
                    .data = StartEndAnnotationData { .both = BothAnnotationData {
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
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .start = StartAnnotationData {
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(0, 11),
                    }},
                },
            }, &.{
                VerticalOffset { .connection = 2, .label = 3, },
                VerticalOffset { .connection = 1, .label = 0, },
            });
        }

        test "with ending 1" {
            const annotation1 = Annotation.primary(0, Span.init(28, 38)).with_label("something");
            const annotation2 = Annotation.secondary(0, Span.init(11, 24)).with_label("something else");

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
                    .data = StartEndAnnotationData { .end = EndAnnotationData {
                        .style = annotation2.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 9),
                    }},
                },
                StartEnd {
                    .annotation = &annotation1,
                    .data = StartEndAnnotationData { .start = StartAnnotationData {
                        .style = annotation1.style,
                        .severity = .@"error",
                        .location = LineColumn.init(1, 13),
                    }},
                },
            }, &.{
                VerticalOffset { .connection = 0, .label = 3, },
                VerticalOffset { .connection = 1, .label = 0, },
            });
        }
    };
};
