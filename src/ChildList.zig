//! A list of children of a box. This data type can either contain a slice into the
//! children stored in a Box, or an allocated slice.
const std = @import("std");

const Box = @import("Box.zig");

/// The children of a Box.
boxes: []const Box,

/// An allocator that was used to allocate `boxes` with,
/// or null if boxes is a slice into the parent.
alloc: ?std.mem.Allocator = null,

const Self = @This();

pub fn deinit(self: *const Self) void {
    if (self.alloc) |ally| {
        ally.free(self.boxes);
    }
}
