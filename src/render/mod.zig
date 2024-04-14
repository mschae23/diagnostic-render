const std = @import("std");
const io = @import("../io.zig");
const file = @import("../file.zig");
const diag = @import("../diagnostic.zig");
const ColorConfig = @import("../ColorConfig.zig");

/// Represents a location in a specific source file,
/// using line and column indices.
///
/// Note that these are indices and not user-facing numbers,
/// so they are `0`-indexed.
///
/// It is not necessarily checked that this position exists
/// in the source file.
pub const LineColumn = struct {
    /// The `0`-indexed line index.
    line_index: usize,
    /// The `0`-indexed column index.
    column_index: usize,

    pub fn init(line_index: usize, column_index: usize) LineColumn {
        return LineColumn {
            .line_index = line_index,
            .column_index = column_index,
        };
    }
};

/// Contains some configuration parameters for [`DiagnosticRenderer`].
///
/// [`DiagnosticRenderer`]: DiagnosticRenderer
pub const RenderConfig = struct {
    /// How many lines of source code to include around annotated lines for context.
    surrounding_lines: usize = 1,
    /// The display width of horizontal tab characters.
    tab_length: usize = 4,
    /// The color config.
    colors: ColorConfig = ColorConfig.DEFAULT,
};

/// A renderer for diagnostics using an "ASCII art"-like format.
pub fn DiagnosticRenderer(comptime FileId: type) type {
    return struct {
        writer: std.io.AnyWriter, colors: std.io.tty.Config, files: file.Files(FileId), config: RenderConfig,
        max_nested_blocks: usize, line_digits: u32,

        const Self = @This();

        /// Creates a new diagnostics renderer.
        pub fn init(writer: std.io.AnyWriter, colors: std.io.tty.Config, files: file.Files(FileId), config: RenderConfig) Self {
            return Self {
                .writer = writer, .colors = colors, .files = files, .config = config,
                .max_nested_blocks = 0, .line_digits = 0,
            };
        }

        /// Renders the given diagnostics.
        pub fn render(self: Self, diagnostics: []const diag.Diagnostic(FileId)) anyerror!void {
            if (diagnostics.len == 0) {
                return;
            }

            return self.renderImpl(diagnostics);
        }

        fn renderImpl(self: Self, diagnostics: []const diag.Diagnostic(FileId)) anyerror!void {
            var self2 = self;
            var i: usize = 0;

            while (i < diagnostics.len) : (i += 1) {
                const diagnostic = &diagnostics[i];
                try self2.renderDiagnostic(diagnostic);

                if (i < diagnostics.len - 1) {
                    try self2.writer.writeByte('\n');
                }
            }
        }

        fn renderDiagnostic(self: *Self, diagnostic: *const diag.Diagnostic(FileId)) anyerror!void {
            try self.renderDiagnosticHeader(diagnostic);
        }

        fn renderDiagnosticHeader(self: *Self, diagnostic: *const diag.Diagnostic(FileId)) anyerror!void {
            try self.colors.setColor(self.writer, self.config.colors.getSeverity(diagnostic.severity));
            try self.writer.print("{any}", .{diagnostic.severity});

            if (diagnostic.name) |name| {
                try self.writer.writeByte('[');
                try self.colors.setColor(self.writer, self.config.colors.getName(diagnostic.severity));
                try self.writer.writeAll(name);
                try self.colors.setColor(self.writer, self.config.colors.getSeverity(diagnostic.severity));
                try self.writer.writeByte(']');
            }

            if (diagnostic.message.len != 0) {
                try self.colors.setColor(self.writer, self.config.colors.message);
                try self.writer.print(": {s}", .{diagnostic.message});
            }

            try self.colors.setColor(self.writer, self.config.colors.reset);

            if (diagnostic.message.len == 0) {
                try self.writer.writeByte('\n');
            }
        }
    };
}
