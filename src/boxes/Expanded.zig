//! This box forces its child to take up all available space.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const ChildList = @import("../ChildList.zig");
const Constraints = @import("../Constraints.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Size = @import("../Size.zig");

data: BoxData = .{},
child: Box,

const Self = @This();

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints, final_pass: bool) anyerror!void {
    if (final_pass) {
        const child_cons = Constraints.tight(cons.max);
        try self.child.layout(ctx, child_cons, true);

        if (!self.child.data.overflow)
            try child_cons.assertFits(self.child.data.size);
    }

    self.data.size = cons.max;
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    self.child.position(ctx, pos);
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
