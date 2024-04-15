const std = @import("std");
const io = @import("./io.zig");
const grapheme = @import("zg-grapheme");
const DisplayWidth = @import("zg-displaywidth");

pub const FileData = struct {
    name: [:0]const u8,
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

pub fn Files(comptime FileId: type) type {
    return struct {
        files: *std.AutoHashMap(FileId, FileData),

        allocator: std.mem.Allocator,
        line_starts: std.AutoHashMap(FileId, std.ArrayListUnmanaged(usize)),
        grapheme_data: grapheme.GraphemeData,
        displaywidth_data: DisplayWidth.DisplayWidthData,

        const Self = @This();

        /// Caller retains overship over HashMap memory.
        pub fn init(allocator: std.mem.Allocator, files: *std.AutoHashMap(FileId, FileData)) !Self {
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
        pub fn name(self: *const Self, file_id: FileId) ?[:0]const u8 {
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

                return left -| 1;
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
                }

                return LineRange {
                    .start = line_starts.items[line_index],
                    .end = line_starts.items[line_index + 1],
                };
            } else {
                return null;
            }
        }

        /// Returns the column index of a character in a file.
        ///
        /// If `index_mode` is `.exclusive`, this function instead looks up the column index for the preceding character.
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
                if (byte_index < line_range.start or byte_index > line_range.end) {
                    return null;
                } else if (index_mode == .inclusive and byte_index >= line_range.end) {
                    return null;
                }

                const opt_file_data = self.files.get(file_id);

                if (opt_file_data) |file_data| {
                    try file_data.seeker.seekTo(line_range.start);

                    var remaining_bytes = byte_index - line_range.start;
                    var count: usize = 0;

                    const dw = DisplayWidth { .data = &self.displaywidth_data };
                    var gc_string = try std.ArrayListUnmanaged(u8).initCapacity(self.allocator, 1);
                    defer gc_string.deinit(self.allocator);
                    var cp_0: ?u21 = null;
                    var cp_1: ?u21 = null;
                    var grapheme_state = grapheme.State {};
                    var buf: [4]u8 = .{0} ** 4;
                    var last_grapheme_break: bool = false;

                    while (remaining_bytes > 0) {
                        const codepoint = codepoint: {
                            remaining_bytes -= 1;
                            const byte = file_data.reader.readByte() catch |err| switch(err) {
                                error.EndOfStream => {
                                    break;
                                },
                                else => return err,
                            };
                            const codepoint_length = std.unicode.utf8ByteSequenceLength(byte) catch |err| switch (err) {
                                error.Utf8InvalidStartByte => {
                                    while (true) {
                                        remaining_bytes -= 1;
                                        const byte2 = file_data.reader.readByte() catch |err2| switch (err2) {
                                            error.EndOfStream => {
                                                break;
                                            },
                                            else => return err,
                                        };
                                        _ = std.unicode.utf8ByteSequenceLength(byte2) catch |err3| switch (err3) {
                                            error.Utf8InvalidStartByte => continue,
                                        };
                                        break;
                                    }

                                    break :codepoint std.unicode.replacement_character;
                                },
                            };

                            buf[0] = byte;
                            file_data.reader.readNoEof(buf[1 .. codepoint_length]) catch |err| switch (err) {
                                error.EndOfStream => break,
                                else => return err,
                            };

                            break :codepoint std.unicode.utf8Decode(buf[0..codepoint_length]) catch break :codepoint std.unicode.replacement_character;
                        };

                        cp_0 = cp_1;
                        cp_1 = codepoint;

                        if (cp_0 == null) {
                            // First iteration
                            continue;
                        } else {
                            _ = std.unicode.utf8Encode(cp_0.?, try gc_string.addManyAsSlice(self.allocator, std.unicode.utf8CodepointSequenceLength(cp_0.?) catch unreachable)) catch unreachable;
                        }

                        const grapheme_break = grapheme.graphemeBreak(cp_0.?, cp_1.?, &self.grapheme_data, &grapheme_state);
                        last_grapheme_break = grapheme_break;

                        if (grapheme_break) {
                            if (cp_0 == '\t') {
                                count += tab_length;
                            } else {
                                count += dw.strWidth(gc_string.items);
                            }

                            gc_string.clearRetainingCapacity();
                        }
                    }

                    if (last_grapheme_break) {
                        if (index_mode == .inclusive) {
                            if (cp_1.? == '\t') {
                                count += tab_length;
                            } else {
                                _ = std.unicode.utf8Encode(cp_1.?, try gc_string.addManyAsSlice(self.allocator, std.unicode.utf8CodepointSequenceLength(cp_1.?) catch unreachable)) catch unreachable;
                                count += dw.strWidth(gc_string.items);
                            }
                        } else {
                            // Ignore next character if exclusive. There was a grapheme break between cp_0 and cp_1,
                            // so there is definitely still a character after cp_0, which was the last one counted.
                            // Since this is supposed to return an exclusive column index, increment count by one
                            // to point to the next grapheme cluster.
                            count += 1;
                        }
                    }

                    // Byte index points to cp_1 at this point. If there was no grapheme break here, cp_1 is still part of the
                    // last grapheme cluster. That is not a valid byte index. In exclusive mode, this can be remedied by simply
                    // not incrementing the count at this point; however, in inclusive mode, the grapheme cluster that it is pointing
                    // into has not been counted yet when it technically should, but we cannot use dw.strWidth because the sequence of
                    // codepoints is incomplete.
                    //
                    // Potential ways to deal with this:
                    // 1. Simply increment count by one. Simple, but most likely wrong.
                    // 2. Read until next grapheme cluster boundary. Could be undesirable.

                    // TODO Rewrite this whole function. `byte_index` points to the first byte of the *next* character - the next
                    // character should not be counted even in inclusive mode. Even if byte_index is invalid and points into the middle
                    // of a UTF-8 codepoint or even the middle of a grapheme cluster, it doesn't matter. The last grapheme boundary is
                    // all that counts. Exclusive mode is even simpler, the last grapheme boundary doesn't even count anymore.
                    //
                    // Steps to implement this properly:
                    // 1. Read the characters normally until byte_index (the function already does this)
                    // 2. Read the UTF-8 codepoint at byte_index to see whether there is a grapheme boundary at this index.
                    //   - the function documentation requires there to be one. If there is one, count it.
                    //   - if there isn't one, just don't count any codepoints since the last boundary, since this byte index is technically
                    //     already referring to the *next* character.

                    return count;
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
