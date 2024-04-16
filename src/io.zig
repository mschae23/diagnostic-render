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

pub fn anySeekableStream(comptime T: type, comptime Context: type, stream: *const Context) AnySeekableStream {
    const TypeErased = struct {
        pub fn typeErasedSeekToFn(context: *const anyopaque, pos: u64) anyerror!void {
            const ptr: *const Context = @alignCast(@ptrCast(context));
            return T.seekTo(ptr.*, pos);
        }

        pub fn typeErasedSeekByFn(context: *const anyopaque, amt: i64) anyerror!void {
            const ptr: *const Context = @alignCast(@ptrCast(context));
            return T.seekBy(ptr.*, amt);
        }

        pub fn typeErasedGetPosFn(context: *const anyopaque) anyerror!u64 {
            const ptr: *const Context = @alignCast(@ptrCast(context));
            return T.getPos(ptr.*);
        }

        pub fn typeErasedGetEndPosFn(context: *const anyopaque) anyerror!u64 {
            const ptr: *const Context = @alignCast(@ptrCast(context));
            return T.getEndPos(ptr.*);
        }
    };

    return .{
        .context = @ptrCast(stream),
        .seekToFn = TypeErased.typeErasedSeekToFn,
        .seekByFn = TypeErased.typeErasedSeekByFn,
        .getPosFn = TypeErased.typeErasedGetPosFn,
        .getEndPosFn = TypeErased.typeErasedGetEndPosFn,
    };
}
