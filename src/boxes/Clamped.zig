//! This Box clamps the size of the child to some given constraints
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const ChildList = @import("../ChildList.zig");
const Constraints = @import("../Constraints.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Simple = @import("Simple.zig");
const Size = @import("../Size.zig");

data: BoxData = .{},
child: Box,
constraints: Constraints,

const Self = @This();

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints, final_pass: bool) anyerror!void {
    const child_constraints = Constraints{
        .min = cons.clamp(self.constraints.min),
        .max = cons.clamp(self.constraints.max),
    };

    try self.child.layout(ctx, child_constraints, final_pass);
    try child_constraints.assertFits(self.child.data.size);

    self.data.size = self.child.data.size;
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    self.child.position(ctx, pos);
    self.data.pos = pos;
}

fn children(self: *Self, ctx: *LayoutCtx) anyerror!?ChildList {
    _ = ctx;
    return .{ .boxes = @ptrCast([*]const Box, &self.child)[0..1] };
}

pub fn box(self: *Self) Box {
    return Box.init(
        Self,
        self,
        &self.data,
        layout,
        position,
        children,
    );
}

test "limit size" {
    var b = Simple{};

    var lim = Self{
        .child = b.box(),
        .constraints = .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 5, .height = 5 },
        },
    };

    var ctx = LayoutCtx{ .alloc = std.testing.allocator };
    try @import("../main.zig").layout(
        lim.box(),
        &ctx,
        .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 10, .height = 10 },
        },
    );

    try std.testing.expect(!ctx.overflow);
    try std.testing.expectEqual(Size{ .width = 5, .height = 5 }, b.data.size);
}

test "useless limit" {
    var b = Simple{};

    var lim = Self{
        .child = b.box(),
        .constraints = .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 10, .height = 10 },
        },
    };

    var ctx = LayoutCtx{ .alloc = std.testing.allocator };
    try @import("../main.zig").layout(
        lim.box(),
        &ctx,
        .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 5, .height = 5 },
        },
    );

    try std.testing.expect(!ctx.overflow);
    try std.testing.expectEqual(Size{ .width = 5, .height = 5 }, b.data.size);
}
