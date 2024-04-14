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
pub const diagnostic = @import("./diagnostic.zig");
pub const render = @import("./render/mod.zig");

test {
    @import("std").testing.refAllDeclsRecursive(@This());
    @import("std").testing.refAllDeclsRecursive(@import("./tests/tests.zig"));
}
