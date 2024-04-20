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

//! This library provides a [text renderer] for printing formatted [diagnostics]
//! like error messages and warnings on some source code using an "ASCII art"-like
//! format for fixed-width font output like in a terminal.
//!
//! These diagnostics contain annotations that are shown directly on the lines
//! in the source they refer to, as well as notes shown after the source.
//!
//! ## Example
//! ```
//! error[example/expect]: Example diagnostic message
//!  --> src/example.zig
//! 1 | const main = 23;
//!   |       ^^^^^^^^^ expected something here
//! 2 | something += 3.0;
//!   |              --- due to this
//! ```
//!
//! [text renderer]: render.DiagnosticRenderer
//! [diagnostics]: diagnostic.Diagnostic

pub const io = @import("./io.zig");
pub const file = @import("./file.zig");
pub const diagnostic = @import("./diagnostic.zig");
pub const render = @import("./render/mod.zig");

test {
    @import("std").testing.refAllDeclsRecursive(@This());
    @import("std").testing.refAllDeclsRecursive(@import("./tests/tests.zig"));
}
