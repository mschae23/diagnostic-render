//! Provides the terminal colors used in diagnostics.

const std = @import("std");
const Color = std.io.tty.Color;
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

pub fn getSeverity(self: Self, s: diagnostic.Severity) Color {
    return self.severity[@intFromEnum(s)];
}

pub fn getName(self: Self, s: diagnostic.Severity) Color {
    return self.name[@intFromEnum(s)];
}

pub fn getAnnotation(self: Self, style: diagnostic.AnnotationStyle, s: diagnostic.Severity) Color {
    return self.name[countEnumCases(diagnostic.AnnotationStyle) * @as(usize, @intFromEnum(style)) + @as(usize, @intFromEnum(s))];
}

pub fn getNoteSeverity(self: Self, s: diagnostic.Severity) Color {
    return self.note_severity[@intFromEnum(s)];
}

pub fn getNoteMessage(self: Self, s: diagnostic.Severity) Color {
    return self.note_message[@intFromEnum(s)];
}

fn countEnumCases(comptime T: type) comptime_int {
    return switch (@typeInfo(T)) {
        .Enum => |info| info.fields.len,
        else => @compileError("Type is not an enum: " ++ @typeName(T)),
    };
}