const std = @import("std");
const io = @import("../io.zig");
const file = @import("../file.zig");
const diagnostic = @import("../diagnostic.zig");

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

    pub fn init(line_index: usize, column_index: usize) usize {
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
    surrounding_lines: usize,
};

/// An ASCII renderer for diagnostics.
pub fn DiagnosticRenderer(comptime FileId: type) type {
    return struct {
        writer: std.io.AnyWriter, colors: std.io.tty.Config, files: file.Files(FileId), config: RenderConfig,
        max_nested_blocks: usize, line_digits: u32,

        const Self = @This();

        /// Creates a new diagnostics renderer.
        pub fn new(writer: std.io.AnyWriter, colors: std.io.tty.Config, files: file.Files(FileId), config: RenderConfig) Self {
            return Self {
                .writer = writer, .colors = colors, .files = files, .config = config,
                .max_nested_blocks = 0, .line_digits = 0,
            };
        }

        /// Renders the given diagnostics.
        pub fn render(self: Self, diagnostics: []const diagnostic.Diagnostic(FileId)) anyerror!void {
            if (diagnostics.len == 0) {
                return;
            }

            _ = self;
            // self.renderImpl(diagnostics);
        }
    };
}
