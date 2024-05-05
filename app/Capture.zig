const std = @import("std");
const utils = @import("../utils.zig");

const fs = std.fs;
const heap = std.heap;
const mem = std.mem;
const os = std.os;

const CharArray = utils.CharArray;

is_capturing: bool,
buffer: *CharArray,
allocator: mem.Allocator,

const Self = @This();
pub fn init(allocator: mem.Allocator) !Self {
    const buffer = try allocator.create(CharArray);
    buffer.* = CharArray.init(allocator);
    return .{
        .buffer = buffer,
        .allocator = allocator,
        .is_capturing = false,
    };
}

pub fn deinit(self: *Self) void {
    self.buffer.deinit();
    self.allocator.destroy(self.buffer);
}

pub fn start(self: *Self) void {
    self.is_capturing = true;
}

pub fn stop(self: *Self) void {
    self.buffer.clearAndFree();
    self.is_capturing = false;
}

pub fn capture(self: *Self, str: []const u8) !void {
    _ = try self.buffer.appendSlice(str);
}

pub fn string(self: *Self) []const u8 {
    return self.buffer.items;
}