//! The simplest of boxes. It simply tries to be as big as the constraints allow.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const Constraints = @import("../Constraints.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Root = @import("../Root.zig");
const Size = @import("../Size.zig");

data: BoxData = .{},

const Self = @This();

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints) anyerror!void {
    _ = ctx;
    self.data.size = cons.max;
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    _ = ctx;
    self.data.pos = pos;
}

pub fn box(self: *Self) Box {
    return Box.init(Self, self, &self.data, layout, position);
}

test "simple layout" {
    var sbox = Self{};

    var root = Root{ .root_box = sbox.box(), .size = .{ .width = 10, .height = 10 } };
    const fctx = try root.layout();

    try std.testing.expect(!fctx.overflow);
    try std.testing.expectEqual(
        BoxData{ .size = .{ .width = 10, .height = 10 } },
        sbox.data,
    );
}
