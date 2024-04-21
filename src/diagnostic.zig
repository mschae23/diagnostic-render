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

//! Diagnostic data structures.
//!
//! End users are encouraged to create their own implementations
//! for their specific use cases, and convert them to this crate's
//! representation when needed.

const std = @import("std");

/// A severity level for diagnostic messages.
///
/// These are ordered in the following way:
/// - Severity.bug > Severity.error
/// - Severity.error > Severity.warning
/// - Severity.warning > Severity.note
/// - Severity.note > Severity.help
/// ```
pub const Severity = enum(u3) {
    /// A help message.
    help,
    /// A note.
    note,
    /// A warning.
    warning,
    /// An error.
    @"error",
    /// An unexpected bug.
    bug,

    pub fn asString(value: Severity) [:0]const u8 {
        return switch (value) {
            .help => "help",
            .note => "note",
            .warning => "warning",
            .@"error" => "error",
            .bug => "bug",
        };
    }

    pub fn format(value: Severity, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        return writer.writeAll(value.asString());
    }
};

/// A style for annotations.
pub const AnnotationStyle = enum(u1) {
    /// Annotations that describe the primary cause of a diagnostic.
    primary,
    /// Annotations that provide additional context for a diagnostic.
    secondary,
};

/// A range of bytes.
pub const Span = struct {
    /// The start byte index of the range. Inclusive.
    start: usize,
    /// The end byte index of the range. Exclusive.
    end: usize,

    pub fn init(start: usize, end: usize) Span {
        return Span {
            .start = start, .end = end,
        };
    }
};

/// An annotation describing an underlined region of code associated with a diagnostic.
pub fn Annotation(comptime FileId: type) type {
    return struct {
        /// The style of the annotation.
        style: AnnotationStyle,
        /// The file that we are annotating.
        file_id: FileId,
        /// The range in bytes we are going to include in the final snippet.
        range: Span,
        /// An optional label to provide some additional information for the
        /// underlined code. These should not include line breaks.
        label: []const u8,

        const Self = @This();

        /// Create a new annotation with no label.
        pub fn init(style: AnnotationStyle, file_id: FileId, range: Span) Self {
            return Self {
                .style = style, .file_id = file_id, .range = range, .label = "",
            };
        }

        /// Create a new annotation with a style of [`AnnotationStyle.primary`].
        ///
        /// [`AnnotationStyle.primary`]: AnnotationStyle.primary
        pub fn primary(file_id: FileId, range: Span) Self {
            return init(AnnotationStyle.primary, file_id, range);
        }

        /// Create a new annotation with a style of [`AnnotationStyle.secondary`].
        ///
        /// [`AnnotationStyle.secondary`]: AnnotationStyle.secondary
        pub fn secondary(file_id: FileId, range: Span) Self {
            return init(AnnotationStyle.secondary, file_id, range);
        }

        /// Add a label to the annotation.
        pub fn with_label(self: Self, label: []const u8) Self {
            var self2 = self;
            self2.label = label;
            return self2;
        }
    };
}

/// A note associated with the primary cause of a diagnostic.
/// They can be used to explain the diagnostic, or include help
/// on how to fix an issue.
///
/// They are displayed at the end of diagnostics, after the source code with
/// its annotations.
pub const Note = struct {
    /// The severity of the note.
    ///
    /// This should usually only be [`Severity.help`] or [`Severity.note`].
    ///
    /// [`Severity.help`]: Severity.help
    /// [`Severity.note`]: Severity.note
    severity: Severity,
    /// The message of this note.
    /// This can include line breaks for improved formatting.
    /// It should not be empty.
    message: []const u8,

    /// Create a new note.
    pub fn init(severity: Severity, message: []const u8) Note {
        return Note {
            .severity = severity,
            .message = message,
        };
    }

    /// Create a new note with a severity of [`Severity.note`].
    ///
    /// [`Severity.note`]: Severity.note
    pub fn note(message: []const u8) Note {
        return init(Severity.note, message);
    }

    /// Create a new note with a severity of [`Severity.help`].
    ///
    /// [`Severity.help`]: Severity.help
    pub fn help(message: []const u8) Note {
        return init(Severity.help, message);
    }
};

/// Represents a diagnostic message that can provide information like errors and
/// warnings to the user.
///
/// The position of a Diagnostic is considered to be the position of the [`Annotation`]
/// that has the earliest starting position and has the highest style which appears
/// in all the annotations of the diagnostic.
///
/// [`Annotation`]: Annotation
pub fn Diagnostic(comptime FileId: type) type {
    return struct {
        /// The overall severity of the diagnostic.
        severity: Severity,
        /// An optional name or code that identifies this diagnostic.
        name: ?[]const u8,
        /// The main message associated with this diagnostic.
        ///
        /// These should not include line breaks, and in order support the 'short'
        /// diagnostic display style, the message should be specific enough to make
        /// sense on its own, without additional context provided by annotations and notes.
        message: []const u8,
        /// Source annotations that describe the cause of the diagnostic.
        ///
        /// The order of the annotations inside the vector does not have any meaning.
        /// The annotations are always arranged in the order they appear in the source code.
        annotations: []const Annotation(FileId),
        /// Notes that are associated with the primary cause of the diagnostic.
        notes: []const Note,

        // /// Additional diagnostics that can be used to show context from other files,
        // /// provide help by showing changed code, or similar. They are shown below notes.
        // pub sub_diagnostics: []const Diagnostic(FileId),

        /// The number of diagnostics following this one that are hidden due to
        /// something like panic mode in error reporting.
        suppressed_count: u32,

        const Self = @This();

        /// Create a new diagnostic.
        pub fn init(severity: Severity) Self {
            return Self {
                .severity = severity,
                .name = null,
                .message = "",
                .annotations = &.{},
                .notes = &.{},
                .suppressed_count = 0,
            };
        }

        /// Create a new diagnostic with a severity of [`Severity.bug`].
        ///
        /// [`Severity.bug`]: Severity.bug
        pub fn bug() Self {
            return init(.bug);
        }

        /// Create a new diagnostic with a severity of [`Severity.error`].
        ///
        /// [`Severity.error`]: Severity.error
        pub fn err() Self {
            return init(.@"error");
        }

        /// Create a new diagnostic with a severity of [`Severity.warning`].
        ///
        /// [`Severity.warning`]: Severity.warning
        pub fn warning() Self {
            return init(.warning);
        }

        /// Create a new diagnostic with a severity of [`Severity.note`].
        ///
        /// [`Severity.note`]: Severity.note
        pub fn note() Self {
            return init(.note);
        }

        /// Create a new diagnostic with a severity of [`Severity.help`].
        ///
        /// [`Severity.help`]: Severity.help
        pub fn help() Self {
            return init(.help);
        }

        /// Set the name or code of the diagnostic.
        pub fn with_name(self: Self, name: []const u8) Self {
            var self2 = self;
            self2.name = name;
            return self2;
        }

        /// Set the message of the diagnostic.
        pub fn with_message(self: Self, message: []const u8) Self {
            var self2 = self;
            self2.message = message;
            return self2;
        }

        // /// Add an annotation to the diagnostic.
        // pub fn with_annotation(self: Self, annotation: Annotation(FileId)) Self {
        //     self.annotations.addOne(annotation);
        //     return self;
        // }

        /// Set the annotations of the diagnostic.
        pub fn with_annotations(self: Self, annotations: []const Annotation(FileId)) Self {
            var self2 = self;
            self2.annotations = annotations;
            return self2;
        }

        // /// Add a note to the diagnostic.
        // pub fn with_note(self: Self, note: Note) Self {
        //     var self2 = self;
        //     self2.notes.push(note);
        //     return self2;
        // }

        /// Set the notes of the diagnostic.
        pub fn with_notes(self: Self, notes: []const Note) Self {
            var self2 = self;
            self2.notes = notes;
            return self2;
        }

        /// Sets the number of suppressed diagnostics.
        pub fn with_suppressed_count(self: Self, suppressed_count: u32) Self {
            var self2 = self;
            self2.suppressed_count = suppressed_count;
            return self2;
        }
    };
}
