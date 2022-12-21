//! The simplest of boxes. It simply tries to be as big as the constraints allow.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const Constraints = @import("../Constraints.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Size = @import("../Size.zig");

data: BoxData = .{},

const Self = @This();

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints, final_pass: bool) anyerror!void {
    _ = ctx;
    _ = final_pass;
    self.data.size = cons.max;
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    _ = ctx;
    self.data.pos = pos;
}

pub fn box(self: *Self) Box {
    return Box.init(
        Self,
        self,
        &self.data,
        layout,
        position,
        null,
    );
}

test "simple layout" {
    var sbox = Self{};

    var ctx = LayoutCtx{ .alloc = std.testing.allocator };
    try @import("../main.zig").layout(
        sbox.box(),
        &ctx,
        .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 10, .height = 10 },
        },
    );

    try std.testing.expect(!ctx.overflow);
    try std.testing.expectEqual(
        BoxData{ .size = .{ .width = 10, .height = 10 } },
        sbox.data,
    );
}
