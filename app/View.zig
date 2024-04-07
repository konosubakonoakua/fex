/// View is responsible for maintaing View.buffer which is an
/// ArrayList of fs items to be displayed.
///
/// It maintains the cursor, and first and last incices to keep
/// track of what portion of the buffer is in view.
const std = @import("std");

const fs = std.fs;
const heap = std.heap;
const mem = std.mem;
const os = std.os;

const Manager = @import("../fs/Manager.zig");
const Entry = Manager.Iterator.Entry;

const Self = @This();

allocator: mem.Allocator,
buffer: std.ArrayList(Entry),

first: usize, // first index (top buffer boundary)
last: usize, // last index (bottom buffer boundar)
cursor: usize, // location in buffer boundary

// Value is unset only after printing all
// all values have to be printed if contents in
// buffer bounds or buffer bounds change.
//
// Else just reprinting current and previous cursor
// positions are enough.
print_all: bool,
prev_cursor: usize, // Previous cursor position.

pub fn init(allocator: mem.Allocator) Self {
    return .{
        .allocator = allocator,
        .buffer = std.ArrayList(Entry).init(allocator),
        .cursor = 0,
        .first = 0,
        .last = 0,
        .prev_cursor = 0,
        .print_all = false,
    };
}

pub fn deinit(self: *Self) void {
    self.buffer.deinit();
}

pub fn update(
    self: *Self,
    iter: *Manager.Iterator,
    max_rows: u16,
) !void {
    const prev_first = self.first;
    const prev_last = self.last;
    if (self.first == 0) {
        self.correct(max_rows);
    }

    while (true) {
        // Cursor exceeds bottom boundary
        if (self.cursor > self.last) {
            try self.incrementIndices(iter);
        }

        // Cursor exceeds top boundary
        else if (self.cursor < self.first) {
            self.decrementIndices();
        }

        // Break, cursor within bounds
        else {
            break;
        }
    }
    self.correct(max_rows);

    // Whether buffer diff has changed
    self.print_all = self.print_all or (self.last != prev_last) or (self.first != prev_first);

    // Whether buffer bounds have scrolled
    self.print_all = self.print_all or (self.last - self.first) != (prev_last - prev_first);
}

fn correct(self: *Self, max_rows: u16) void {
    const current_diff: usize = self.last -| self.first;
    const max_diff: usize = self.first + max_rows;

    // Correct `last`: ensure `last` less than buffer len
    self.last = @min(max_diff, self.buffer.items.len) - 1;
    if (self.first == 0) {
        return;
    }

    // Correct `first`: ensure `first` before `last`
    if (current_diff > 0) {
        self.first = self.last -| current_diff;
    }

    // no-op after update loop
    // Correct `cursor`: place `cursor` within bounds
    if (self.cursor < self.first) {
        self.cursor = self.first;
    } else if (self.cursor > self.last) {
        self.cursor = self.last;
    }
}

fn incrementIndices(self: *Self, iter: *Manager.Iterator) !void {
    // Self buffer in range, no need to append
    if (self.last < (self.buffer.items.len - 1)) {
        self.first += 1;
        self.last += 1;
    }

    // Self buffer out of range, need to append
    else if (iter.next()) |e| {
        try self.buffer.append(e);
        self.first += 1;
        self.last += 1;
    }

    // No more items, reset cursor
    else {
        self.cursor = self.last;
    }
}

fn decrementIndices(self: *Self) void {
    const diff = self.last - self.first;
    self.first = self.cursor;
    self.last = self.first + diff;
}
