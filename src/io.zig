const std = @import("std");

pub const AnySeekableStream = struct {
    context: *const anyopaque,
    seekToFn: *const fn (context: *const anyopaque, pos: u64) anyerror!void,
    seekByFn: *const fn (context: *const anyopaque, amt: i64) anyerror!void,
    getPosFn: *const fn (context: *const anyopaque) anyerror!u64,
    getEndPosFn: *const fn (context: *const anyopaque) anyerror!u64,

    const Self = @This();
    pub const Error = anyerror;

    pub fn seekTo(self: Self, pos: u64) anyerror!void {
        return self.seekToFn(self.context, pos);
    }

    pub fn seekBy(self: Self, amt: i64) anyerror!void {
        return self.seekByFn(self.context, amt);
    }

    pub fn getPos(self: Self) anyerror!u64 {
        return self.getPosFn(self.context);
    }

    pub fn getEndPos(self: Self) anyerror!u64 {
        return self.getEndPosFn(self.context);
    }
};
