//! This box forces its child to take up all available space.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
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
        try child_cons.assertFits(self.child.data.size);
    }

    self.data.size = cons.max;
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    self.child.position(ctx, pos);
    self.data.pos = pos;
}

pub fn box(self: *Self) Box {
    return Box.init(Self, self, &self.data, layout, position);
}
