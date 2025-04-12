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
const io = @import("./io.zig");
const grapheme = @import("zg-grapheme");
const DisplayWidth = @import("zg-displaywidth");

pub const FileData = struct {
    name: []const u8,
    reader: std.io.AnyReader,
    // Must be the SeekableStream for the reader
    seeker: io.AnySeekableStream,
};

pub const LineRange = struct {
    /// Byte index at the start of a line. Inclusive.
    start: usize,
    /// Byte index at the end of a line. Exclusive.
    end: usize,
};

/// Represents the way a byte index should be treated, i. e.
/// whether it is inclusive or exclusive.
pub const IndexMode = enum {
    inclusive,
    exclusive,
};

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

pub const Location = struct {
    /// The user-facing line number.
    line_number: usize,
    /// The user-facing column number.
    column_number: usize,
};

/// The main data structure holding data for the files that diagnostics can be reported on.
///
/// ## Type parameters
/// * `FileDataMap`:
///   This type needs to have a `get(FileId)?*FileData` function.
///
///   Because it is stored inside the `Files` struct, it makes sense to use a pointer type here
///   if you need the actual data to be stored somewhere else.
pub fn Files(comptime FileId: type, comptime FileDataMap: type) type {
    return struct {
        files: FileDataMap,

        allocator: std.mem.Allocator,
        line_starts: std.AutoHashMap(FileId, std.ArrayListUnmanaged(usize)),
        grapheme_data: grapheme.GraphemeData,
        displaywidth_data: DisplayWidth.DisplayWidthData,

        const Self = @This();

        /// Caller retains overship over HashMap memory.
        pub fn init(allocator: std.mem.Allocator, files: FileDataMap) !Self {
            return Self {
                .files = files,

                .allocator = allocator,
                .line_starts = std.AutoHashMap(FileId, std.ArrayListUnmanaged(usize)).init(allocator),
                .grapheme_data = try grapheme.GraphemeData.init(allocator),
                .displaywidth_data = try DisplayWidth.DisplayWidthData.init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.displaywidth_data.deinit();
            self.grapheme_data.deinit();

            var line_starts_iter = self.line_starts.valueIterator();

            while (line_starts_iter.next()) |list| {
                list.deinit(self.allocator);
            }

            self.line_starts.deinit();
        }

        /// Returns the name associated with the given [`FileId`].
        ///
        /// The return value is only `null` if no file with this ID exists.
        ///
        /// [`FileId`]: FileId
        pub fn name(self: *const Self, file_id: FileId) ?[]const u8 {
            const opt_file_data = self.files.get(file_id);

            if (opt_file_data) |file_data| {
                return file_data.name;
            } else {
                return null;
            }
        }

        /// Returns the reader associated with the given [`FileId`]. This reader is associated with the seeker
        /// returned by [`seeker`].
        ///
        /// The return value is only `null` if no file with this ID exists.
        ///
        /// [`FileId`]: FileId
        /// [`seeker`]: seeker
        pub fn reader(self: *const Self, file_id: FileId) ?std.io.AnyReader {
            const opt_file_data = self.files.get(file_id);

            if (opt_file_data) |file_data| {
                return file_data.reader;
            } else {
                return null;
            }
        }

        /// Returns the seeker associated with the given [`FileId`]. This seeker is associated with the reader
        /// returned by [`reader`].
        ///
        /// The return value is only `null` if no file with this ID exists.
        ///
        /// [`FileId`]: FileId
        /// [`reader`]: reader
        pub fn seeker(self: *const Self, file_id: FileId) ?io.AnySeekableStream {
            const opt_file_data = self.files.get(file_id);

            if (opt_file_data) |file_data| {
                return file_data.seeker;
            } else {
                return null;
            }
        }

        /// Returns the line index of the character at a given byte index in a file. If the byte index is greater than or
        /// equal to the file's length, it returns the last line index, so the returned value is never `null` for valid
        /// files.
        ///
        /// If `index_mode` is `.exclusive`, this function instead looks up the line index for the byte index preceding
        /// the given value.
        ///
        /// This function requires the file source to be encoded with UTF-8. However, it has no requirements for the
        /// `byte_index` value.
        ///
        /// The return value is only `null` if no file with this ID exists. However, the underlying reader and seeker
        /// can error for any reason.
        pub fn lineIndex(self: *Self, file_id: FileId, byte_index: usize, index_mode: IndexMode) anyerror!?usize {
            const opt_line_starts = try self.getOrComputeLineStarts(file_id);

            if (opt_line_starts) |line_starts| {
                // Binary search
                var left: usize = 0;
                var right: usize = line_starts.items.len;

                while (left < right) {
                    // Avoid overflowing in the midpoint calculation
                    const mid = left + (right - left) / 2;
                    // Compare the key with the midpoint element
                    switch (std.math.order(byte_index, line_starts.items[mid])) {
                        .eq => return switch (index_mode) {
                            .inclusive => mid,
                            .exclusive => mid -| 1,
                        },
                        .gt => left = mid + 1,
                        .lt => right = mid,
                    }
                }

                return @min(left -| 1, line_starts.items.len - 2);
            } else {
                return null;
            }
        }

        /// Returns the line index of the last line in a file.
        ///
        /// The return value is only `null` if no file with this ID exists. However, the underlying reader and seeker
        /// can error for any reason.
        pub fn getLastLineIndex(self: *Self, file_id: FileId) anyerror!?usize {
            const opt_line_starts = try self.getOrComputeLineStarts(file_id);

            if (opt_line_starts) |line_starts| {
                return line_starts.items.len - 2;
            } else {
                return null;
            }
        }

        /// Returns the user-facing line number for a given line index in a file.
        ///
        /// While the distinction is technically important, as a language could, for example, define something
        /// like C's `#line` preprocessor instruction, no such feature is supported by this library.
        /// Therefore, this function practically just returns the given line index incremented by one (1).
        pub fn lineNumber(self: *Self, file_id: FileId, line_index: usize) usize {
            _ = self;
            _ = file_id;
            return line_index + 1;
        }

        /// Returns the byte range of a line in a file.
        ///
        /// The return value is only `null` if no file with this ID exists. However, the underlying reader and seeker
        /// can error for any reason.
        pub fn lineRange(self: *Self, file_id: FileId, line_index: usize) anyerror!?LineRange {
            const opt_line_starts = try self.getOrComputeLineStarts(file_id);

            if (opt_line_starts) |line_starts| {
                if (line_starts.items.len < line_index + 1) {
                    return null;
                } else if (line_index == line_starts.items.len - 2) {
                    return LineRange {
                        .start = line_starts.items[line_index],
                        .end = line_starts.items[line_index + 1], // no -1 because there's no LF byte
                    };
                }

                return LineRange {
                    .start = line_starts.items[line_index],
                    .end = line_starts.items[line_index + 1] - 1, // -1 because of LF byte
                };
            } else {
                return null;
            }
        }

        /// Returns the column index of a character in a file, with its line index already given.
        ///
        /// This function requires the file's source to be encoded in UTF-8. The provided `byte_index` must point to the first byte
        /// of the first UTF-8 codepoint of an extended grapheme cluster in the file. While pointing into the middle of a UTF-8
        /// codepoint is detectable (but may incur non-useful behaviour), it is unclear how to proceed if `byte_index` points to a codepoint
        /// that is not immediately following a grapheme boundary.
        ///
        /// The returned value is not a simple byte offset into the line, but rather the column (`0`-indexed) at which the character would
        /// be displayed in a display using a fixed-width font, such as a terminal.
        ///
        /// The return value is only `null` if no file with this ID exists. However, the underlying reader and seeker
        /// can error for any reason.
        pub fn columnIndex(self: *Self, file_id: FileId, line_index: usize, byte_index: usize, index_mode: IndexMode, tab_length: usize) anyerror!?usize {
            const opt_line_range = try self.lineRange(file_id, line_index);

            if (opt_line_range) |line_range| {
                var byte_index_2 = byte_index;

                if (byte_index < line_range.start) {
                    return 0;
                } else if (byte_index >= line_range.end) {
                    // To ensure that this function does not read into the next line, but also
                    // returns a useful result even if the byte_index is technically out of bounds.
                    byte_index_2 = line_range.end;
                }

                const opt_file_data = self.files.get(file_id);

                if (opt_file_data) |file_data| {
                    try file_data.seeker.seekTo(line_range.start);

                    // UTF-8 decoding is implemented as specified in https://encoding.spec.whatwg.org/#utf-8-decoder.

                    var result_column_index: usize = 0;

                    const dw = DisplayWidth { .data = &self.displaywidth_data };
                    var grapheme_state = grapheme.State {};
                    var grapheme_cluster = try std.ArrayListUnmanaged(u8).initCapacity(self.allocator, 1);
                    defer grapheme_cluster.deinit(self.allocator);

                    var last_codepoint: ?u21 = null;
                    var post_increment_column_index = false;

                    var codepoint: u21 = 0;
                    var bytes_seen: u3 = 0;
                    var bytes_needed: u3 = 0;
                    var lower_boundary: u21 = 0x80;
                    var upper_boundary: u21 = 0xBF;

                    var i: usize = line_range.start;

                    // Use <= to read the codepoint at byte_index_2 as well
                    while (i <= byte_index_2 or bytes_needed != 0) {
                        const current_codepoint = codepoint: {
                            i += 1;
                            const byte = file_data.reader.readByte() catch |err| switch (err) {
                                error.EndOfStream => if (bytes_needed != 0) {
                                    bytes_needed = 0;

                                    break :codepoint std.unicode.replacement_character;
                                } else {
                                    post_increment_column_index = true;
                                    break;
                                },
                                else => return err,
                            };

                            if (bytes_needed == 0) {
                                switch (byte) {
                                    0x00...0x7F => {
                                        break :codepoint byte;
                                    },
                                    0xC2...0xDF => {
                                        bytes_needed = 1;
                                        // The five least significant bits of byte.
                                        codepoint = byte & 0x1F;
                                    },
                                    0xE0...0xEF  => {
                                        if (byte == 0xE0) {
                                            lower_boundary = 0xA0;
                                        } else if (byte == 0xED) {
                                            upper_boundary = 0x9F;
                                        }

                                        bytes_needed = 2;
                                        // The four least significant bits of byte.
                                        codepoint = byte & 0xF;
                                    },
                                    0xF0...0xF4 => {
                                        if (byte == 0xF0) {
                                            lower_boundary = 0x90;
                                        } else if (byte == 0xF4) {
                                            upper_boundary = 0x8F;
                                        }

                                        bytes_needed = 3;
                                        // The three least significant bits of byte.
                                        codepoint = byte & 0xF;
                                    },
                                    else => {
                                        break :codepoint std.unicode.replacement_character;
                                    }
                                }

                                continue;
                            }

                            if (byte < lower_boundary or byte > upper_boundary) {
                                codepoint = 0;
                                bytes_needed = 0;
                                bytes_seen = 0;
                                lower_boundary = 0x80;
                                upper_boundary = 0xBF;
                                // "Restore byte to ioQueue", so that the byte will be read again in the next iteration
                                try file_data.seeker.seekBy(-1);

                                break :codepoint std.unicode.replacement_character;
                            }

                            lower_boundary = 0x80;
                            upper_boundary = 0xBF;
                            // Shift the existing bits of UTF-8 code point left by six places and set the newly-vacated
                            // six least significant bits to the six least significant bits of byte.
                            codepoint = (codepoint << 6) | (byte & 0x3F);
                            bytes_seen += 1;

                            if (bytes_seen != bytes_needed) {
                                continue;
                            }

                            const cp = codepoint;
                            codepoint = 0;
                            bytes_needed = 0;
                            bytes_seen = 0;
                            break :codepoint cp;
                        };

                        if (last_codepoint == null) {
                            // First iteration
                            last_codepoint = current_codepoint;
                            continue;
                        } else {
                            _ = std.unicode.utf8Encode(last_codepoint.?, try grapheme_cluster.addManyAsSlice(self.allocator, std.unicode.utf8CodepointSequenceLength(last_codepoint.?) catch unreachable)) catch unreachable;
                        }

                        const grapheme_break = grapheme.graphemeBreak(last_codepoint.?, current_codepoint, &self.grapheme_data, &grapheme_state);

                        if (grapheme_break) {
                            if (last_codepoint == '\t') {
                                // An alternative to this approach is "elastic tabstops": https://nick-gravgaard.com/elastic-tabstops/,
                                // but it seems to be rarely used.
                                result_column_index += tab_length - (result_column_index % tab_length);
                            } else {
                                result_column_index += dw.strWidth(grapheme_cluster.items);
                            }

                            grapheme_cluster.clearRetainingCapacity();
                        }

                        last_codepoint = current_codepoint;
                    }

                    if (post_increment_column_index) {
                        _ = std.unicode.utf8Encode(last_codepoint.?, try grapheme_cluster.addManyAsSlice(self.allocator, std.unicode.utf8CodepointSequenceLength(last_codepoint.?) catch unreachable)) catch unreachable;

                        if (last_codepoint == '\t') {
                            result_column_index += tab_length - (result_column_index % tab_length);
                        } else {
                            result_column_index += dw.strWidth(grapheme_cluster.items);
                        }
                    }

                    return switch (index_mode) {
                        .inclusive => result_column_index,
                        // In exclusive mode, the character referred to with byte_index is *not* part of some
                        // range anymore. So the most useful return value of columnIndex in exclusive mode
                        // is the number of columns to print in a fixed-width font such that the next character
                        // ends at byte_index. For example, the end byte index of annotations is exclusive, and
                        // this behaviour makes it easy to to print a character in the space of the last
                        // character of the annotation's range.
                        // This is why this subtracts 1 instead of the last character's width. If it did that
                        // and this last character is more than one column wide, the renderer can no longer rely
                        // on the behaviour described above. If it did, its annotations would get out of sync
                        // with their source line.
                        .exclusive => result_column_index - 1,
                    };
                } else {
                    return null;
                }
            } else {
                return null;
            }
        }

        /// Returns the user-facing column number for a given column index in a file.
        ///
        /// While the distinction is technically important, no feature distinguishing between them is supported by this library.
        /// Therefore, this function practically just returns the given column index incremented by one (1).
        pub fn columnNumber(self: *Self, file_id: FileId, column_index: usize) usize {
            _ = self;
            _ = file_id;
            return column_index + 1;
        }

        /// Returns both [line] and [column] indices for a given character in a file.
        ///
        /// The return value is only `null` if no file with this ID exists. However, the underlying reader and seeker
        /// can error for any reason.
        ///
        /// [line]: lineIndex
        /// [column]: columnIndex
        pub fn lineColumn(self: *Self, file_id: FileId, byte_index: usize, index_mode: IndexMode, tab_length: usize) anyerror!?LineColumn {
            const opt_line_index = try self.lineIndex(file_id, byte_index, index_mode);

            if (opt_line_index) |line_index| {
                return LineColumn {
                    .line_index = line_index,
                    .column_index = try self.columnIndex(file_id, line_index, byte_index, index_mode, tab_length) orelse unreachable,
                };
            } else {
                return null;
            }
        }

        /// Returns both user-facing [line] and [column] numbers for a given character in a file.
        ///
        /// The return value is only `null` if no file with this ID exists. However, the underlying reader and seeker
        /// can error for any reason.
        ///
        /// [line]: lineNumber
        /// [column]: columnNumber
        pub fn location(self: *Self, file_id: FileId, byte_index: usize, index_mode: IndexMode, tab_length: usize) anyerror!?Location {
            const opt_line_index = try self.lineIndex(file_id, byte_index, index_mode);

            if (opt_line_index) |line_index| {
                return Location {
                    .line_number = self.lineNumber(file_id, line_index),
                    .column_number = self.columnNumber(file_id, try self.columnIndex(file_id, line_index, byte_index, index_mode, tab_length) orelse unreachable),
                };
            } else {
                return null;
            }
        }

        /// Returns both a user-facing [line] and a byte-based column number for a given character in a file.
        ///
        /// The return value is only `null` if no file with this ID exists. However, the underlying reader and seeker
        /// can error for any reason.
        ///
        /// [line]: lineNumber
        pub fn codepointLocation(self: *Self, file_id: FileId, byte_index: usize) anyerror!?Location {
            const opt_line_index = try self.lineIndex(file_id, byte_index, .inclusive);

            if (opt_line_index) |line_index| {
                const line_range = try self.lineRange(file_id, line_index) orelse unreachable;

                const byte_index_2 =
                    if (byte_index < line_range.start)
                        line_range.start
                    else if (byte_index > line_range.end)
                        line_range.end
                    else byte_index;

                const column_index = column: {
                    const file_data = self.files.get(file_id) orelse unreachable;
                    try file_data.seeker.seekTo(line_range.start);

                    var codepoint_column_index: usize = 0;

                    var codepoint: u21 = 0;
                    var bytes_seen: u3 = 0;
                    var bytes_needed: u3 = 0;
                    var lower_boundary: u21 = 0x80;
                    var upper_boundary: u21 = 0xBF;

                    var i: usize = line_range.start;

                    while (i < byte_index_2 or bytes_needed != 0) {
                        const current_codepoint = codepoint: {
                            i += 1;
                            const byte = file_data.reader.readByte() catch |err| switch (err) {
                                error.EndOfStream => if (bytes_needed != 0) {
                                    bytes_needed = 0;

                                    break :codepoint std.unicode.replacement_character;
                                } else {
                                    break;
                                },
                                else => return err,
                            };

                            if (bytes_needed == 0) {
                                switch (byte) {
                                    0x00...0x7F => {
                                        break :codepoint byte;
                                    },
                                    0xC2...0xDF => {
                                        bytes_needed = 1;
                                        // The five least significant bits of byte.
                                        codepoint = byte & 0x1F;
                                    },
                                    0xE0...0xEF  => {
                                        if (byte == 0xE0) {
                                            lower_boundary = 0xA0;
                                        } else if (byte == 0xED) {
                                            upper_boundary = 0x9F;
                                        }

                                        bytes_needed = 2;
                                        // The four least significant bits of byte.
                                        codepoint = byte & 0xF;
                                    },
                                    0xF0...0xF4 => {
                                        if (byte == 0xF0) {
                                            lower_boundary = 0x90;
                                        } else if (byte == 0xF4) {
                                            upper_boundary = 0x8F;
                                        }

                                        bytes_needed = 3;
                                        // The three least significant bits of byte.
                                        codepoint = byte & 0xF;
                                    },
                                    else => {
                                        break :codepoint std.unicode.replacement_character;
                                    }
                                }

                                continue;
                            }

                            if (byte < lower_boundary or byte > upper_boundary) {
                                codepoint = 0;
                                bytes_needed = 0;
                                bytes_seen = 0;
                                lower_boundary = 0x80;
                                upper_boundary = 0xBF;
                                // "Restore byte to ioQueue", so that the byte will be read again in the next iteration
                                try file_data.seeker.seekBy(-1);

                                break :codepoint std.unicode.replacement_character;
                            }

                            lower_boundary = 0x80;
                            upper_boundary = 0xBF;
                            // Shift the existing bits of UTF-8 code point left by six places and set the newly-vacated
                            // six least significant bits to the six least significant bits of byte.
                            codepoint = (codepoint << 6) | (byte & 0x3F);
                            bytes_seen += 1;

                            if (bytes_seen != bytes_needed) {
                                continue;
                            }

                            const cp = codepoint;
                            codepoint = 0;
                            bytes_needed = 0;
                            bytes_seen = 0;
                            break :codepoint cp;
                        };
                        _ = current_codepoint;

                        codepoint_column_index += 1;
                    }

                    break :column codepoint_column_index;
                };

                return Location {
                    .line_number = self.lineNumber(file_id, line_index),
                    .column_number = self.columnNumber(file_id, column_index),
                };
            } else {
                return null;
            }
        }

        /// Internal, static helper function to generate the line starts table.
        fn lineStarts(allocator: std.mem.Allocator, source: std.io.AnyReader) anyerror!std.ArrayListUnmanaged(usize) {
            var line_starts = try std.ArrayListUnmanaged(usize).initCapacity(allocator, 2);
            line_starts.addOneAssumeCapacity().* = 0;

            var byte_index: usize = 0;

            while (true) : (byte_index += 1) {
                const byte = source.readByte() catch |err| switch (err) {
                    error.EndOfStream => {
                        (try line_starts.addOne(allocator)).* = byte_index;
                        return line_starts;
                    },
                    else => |e| return e,
                };

                if (byte == '\n') (try line_starts.addOne(allocator)).* = byte_index + 1;
            }
        }

        /// Returns or computes the line starts table, which is a simple list containing the start byte index for every line index
        /// in a file.
        ///
        /// The return value is only `null` if no file with this ID exists. However, the underlying reader and seeker
        /// can error for any reason.
        fn getOrComputeLineStarts(self: *Self, file_id: FileId) anyerror!?std.ArrayListUnmanaged(usize) {
            const entry = try self.line_starts.getOrPut(file_id);

            if (!entry.found_existing) {
                const opt_file_data = self.files.get(file_id);

                if (opt_file_data) |file_data| {
                    try file_data.seeker.seekTo(0);
                    entry.value_ptr.* = try lineStarts(self.allocator, file_data.reader);
                } else {
                    return null;
                }
            }

            return entry.value_ptr.*;
        }
    };
}
