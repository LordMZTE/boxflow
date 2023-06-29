//! This box takes up the space used by it's
//! child and then centers the child inside itself.
//!
//! Note that the makes the child box not respect minimum constraints,
//! as it will be centered if it's smaller. This can break flex layouts.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const ChildList = @import("../ChildList.zig");
const Clamped = @import("Clamped.zig");
const Constraints = @import("../Constraints.zig");
const Expanded = @import("Expanded.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Simple = @import("Simple.zig");
const Size = @import("../Size.zig");

data: BoxData = .{},
child: Box,

const Self = @This();

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints, final_pass: bool) anyerror!void {
    const child_cons = Constraints{
        // we take away the minimum constraint, because it's fine if the child is smaller
        .min = .{ .width = 0, .height = 0 },
        .max = cons.max,
    };

    try self.child.layout(ctx, child_cons, final_pass);

    if (self.child.data.overflow) {
        // No need to recursively set overflow, the child should've already done that.
        self.data.overflow = true;
        return;
    }

    try child_cons.assertFits(self.child.data.size);

    // we try to get as close to the child's size as fits within the constraints
    self.data.size = cons.clamp(self.child.data.size);
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    const child_pos = Position{
        .x = pos.x + (self.data.size.width - self.child.data.size.width) / 2,
        .y = pos.y + (self.data.size.height - self.child.data.size.height) / 2,
    };

    self.child.position(ctx, child_pos);

    self.data.pos = pos;
}

fn children(self: *Self, ctx: *LayoutCtx) anyerror!?ChildList {
    _ = ctx;
    return .{ .boxes = @as([*]const Box, @ptrCast(&self.child))[0..1] };
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

test "clamped centered box" {
    var inner = Simple{};
    var clamped = Clamped{
        .child = inner.box(),
        .constraints = .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 4, .height = 4 },
        },
    };
    var centered = Self{ .child = clamped.box() };

    // We need to use an Expanded here so the Centered is bigger than its child.
    var expanded = Expanded{ .child = centered.box() };

    var ctx = LayoutCtx{ .alloc = std.testing.allocator };
    try @import("../main.zig").layout(
        expanded.box(),
        &ctx,
        .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 8, .height = 8 },
        },
    );

    try std.testing.expect(!ctx.overflow);

    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 2, .y = 2 },
            .size = .{ .width = 4, .height = 4 },
        },
        inner.data,
    );
}
