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

test "header 1" {
    try runTest("src/path/to/file.something", "unused source", &.{
        Diagnostic.err().withName("test/diagnostic_1").withMessage("Test message")
    }, "error[test/diagnostic_1]: Test message\n");
}

test "footer 1" {
    try runTest("src/path/to/file.something", "unused source", &.{
        Diagnostic.warning().withName("test/diagnostic_2").withMessage("Test message").withNotes(&.{
            Note.note("This is a test note.\nYes.")
        })
    },
    \\warning[test/diagnostic_2]: Test message
    \\ = note: This is a test note.
    \\         Yes.
    \\
    );
}
