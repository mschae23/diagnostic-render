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

//! Provides the terminal colors used in diagnostics.

const std = @import("std");
const Color = std.io.tty.Color;
const Config = std.io.tty.Config;
const diagnostic = @import("./diagnostic.zig");

/// Resets all style and formatting.
reset: Color,
/// Sets the formatting for annotations with a specific [`Severity`].
///
/// [`Severity`]: diagnostic.Severity
severity: [countEnumCases(diagnostic.Severity)] Color,
/// Sets the formatting for the optional error name or code.
name: [countEnumCases(diagnostic.Severity)] Color,
/// Sets the formatting for the main message of a diagnostic.
message: Color,
/// Sets the formatting for the file path, line and column numbers printed
/// at the start of a code block.
path: Color,
/// Sets the formatting for the line number of a line of source code.
line_number: Color,
/// Sets the formatting for the separator between the line number and the line of source code.
/// In most cases, this is either `" | "`, `"-->"`, or `"..."`.
line_number_separator: Color,
/// Sets the formatting for an annotation.
/// The annotation style (primary or secondary) and the diagnostic severity are
/// provided as context.
///
/// The default configuration would redirect to [`severity`] in the case of
/// a primary annotation style, and use a specific formatting for the secondary
/// annotation style.
///
/// [`severity`]: severity
annotation: [countEnumCases(diagnostic.AnnotationStyle) * countEnumCases(diagnostic.Severity)] Color,
/// Sets the formatting for a line of source code.
source: Color,
/// Sets the formatting for notes with a specific [`Severity`].
///
/// [`Severity`]: diagnostic.Severity
note_severity: [countEnumCases(diagnostic.Severity)] Color,
/// Sets the formatting for the main message of a note.
note_message: [countEnumCases(diagnostic.Severity)] Color,

const Self = @This();

pub const DEFAULT_SEVERITY: [countEnumCases(diagnostic.Severity)] Color = .{
    // Help
    Color.green,
    // Note
    Color.bright_blue,
    // Warning
    Color.yellow,
    // Error
    Color.bright_red,
    // Bug
    Color.bright_red,
};

pub const DEFAULT: Self = Self {
    .reset = Color.reset,
    .severity = DEFAULT_SEVERITY,
    .name = DEFAULT_SEVERITY,
    .message = Color.bright_white,
    .path = Color.reset,
    .line_number = Color.bright_blue,
    .line_number_separator = Color.bright_blue,
    .annotation = .{
        // == Primary ==
        // Help
        Color.green,
        // Note
        Color.bright_blue,
        // Warning
        Color.yellow,
        // Error
        Color.bright_red,
        // Bug
        Color.bright_red,

        // == Secondary ==
        // Help
        Color.bright_blue,
        // Note
        Color.bright_blue,
        // Warning
        Color.bright_blue,
        // Error
        Color.bright_blue,
        // Bug
        Color.bright_blue,
    },
    .source = Color.reset,
    .note_severity = .{
        // Help
        Color.bright_white,
        // Note
        Color.bright_white,
        // Warning
        Color.bright_white,
        // Error
        Color.bright_white,
        // Bug
        Color.bright_white,
    },
    .note_message = .{
        // Help
        Color.reset,
        // Note
        Color.reset,
        // Warning
        Color.reset,
        // Error
        Color.reset,
        // Bug
        Color.reset,
    },
};

pub fn writeReset(self: *const Self, config: Config, writer: anytype) anyerror!void {
    return setColor(config, writer, self.reset);
}

pub fn writeSeverity(self: *const Self, config: Config, writer: anytype, s: diagnostic.Severity) anyerror!void {
    return setColor(config, writer, self.severity[@intFromEnum(s)]);
}

pub fn writeName(self: *const Self, config: Config, writer: anytype, s: diagnostic.Severity) anyerror!void {
    return setColor(config, writer, self.name[@intFromEnum(s)]);
}

pub fn writeMessage(self: *const Self, config: Config, writer: anytype) anyerror!void {
    return setColor(config, writer, self.message);
}

pub fn writePath(self: *const Self, config: Config, writer: anytype) anyerror!void {
    return setColor(config, writer, self.path);
}

pub fn writeLineNumber(self: *const Self, config: Config, writer: anytype) anyerror!void {
    return setColor(config, writer, self.line_number);
}

pub fn writeLineNumberSeparator(self: *const Self, config: Config, writer: anytype) anyerror!void {
    return setColor(config, writer, self.line_number_separator);
}

pub fn writeAnnotation(self: *const Self, config: Config, writer: anytype, style: diagnostic.AnnotationStyle, s: diagnostic.Severity) anyerror!void {
    return setColor(config, writer, self.annotation[countEnumCases(diagnostic.AnnotationStyle) * @as(usize, @intFromEnum(style)) + @as(usize, @intFromEnum(s))]);
}

pub fn writeSource(self: *const Self, config: Config, writer: anytype) anyerror!void {
    return setColor(config, writer, self.source);
}

pub fn writeNoteSeverity(self: *const Self, config: Config, writer: anytype, s: diagnostic.Severity) anyerror!void {
    return setColor(config, writer, self.note_severity[@intFromEnum(s)]);
}

pub fn writeNoteMessage(self: *const Self, config: Config, writer: anytype, s: diagnostic.Severity) anyerror!void {
    return setColor(config, writer, self.note_message[@intFromEnum(s)]);
}

pub fn setColor(config: Config, writer: anytype, color: Color) anyerror!void {
    bright: {
        const original: Color = switch (color) {
            .bright_black => .black,
            .bright_red => .red,
            .bright_green => .green,
            .bright_yellow => .yellow,
            .bright_blue => .blue,
            .bright_magenta => .magenta,
            .bright_cyan => .cyan,
            else => break :bright,
        };

        try config.setColor(writer, .bold);
        return config.setColor(writer, original);
    }

    return config.setColor(writer, color);
}

fn countEnumCases(comptime T: type) comptime_int {
    return switch (@typeInfo(T)) {
        .Enum => |info| info.fields.len,
        else => @compileError("Type is not an enum: " ++ @typeName(T)),
    };
}
