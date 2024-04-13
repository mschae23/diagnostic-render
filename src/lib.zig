//! This library provides an [ASCII renderer] for printing formatted [diagnostics]
//! like error messages and warnings on some source code.
//!
//! These diagnostics contain annotations that are shown directly on the lines
//! in the source they refer to, as well as notes shown after the source.
//!
//! # Example
//! ```text
//! // TODO give an example here
//! ```
//!
//! [ASCII renderer]: render.DiagnosticRenderer
//! [diagnostics]: diagnostic.Diagnostic

pub const io = @import("./io.zig");
pub const file = @import("./file.zig");
pub const render = @import("./render.zig");
pub const diagnostic = @import("./diagnostic.zig");

test "stderr color functionality" {
    const std = @import("std");

    const stderr = std.io.getStdErr();
    const tty = std.io.tty.detectConfig(stderr);
    const stderr_writer = stderr.writer();

    try stderr_writer.print("Hello!\n", .{});
    try tty.setColor(stderr, .green);
    try stderr_writer.print("Haha", .{});
    try tty.setColor(stderr, .reset);
    try stderr_writer.print("\n", .{});
}

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}
