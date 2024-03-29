//! This box forces its child to take the minimum amount of available space in a given axis,
//! or both.
//!
//! This can often be useful for allowing a widget that is would otherwise take up all
//! available space to be used in a flex layout.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const ChildList = @import("../ChildList.zig");
const Constraints = @import("../Constraints.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Size = @import("../Size.zig");

pub const Axis = enum {
    horizontal,
    vertical,
    both,
};

data: BoxData = .{},
axis: Axis = .both,
child: Box,

const Self = @This();

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints, final_pass: bool) anyerror!void {
    const child_cons = switch (self.axis) {
        .horizontal => Constraints{
            .min = cons.min,
            .max = .{
                .width = cons.min.width,
                .height = cons.max.height,
            },
        },
        .vertical => Constraints{
            .min = cons.min,
            .max = .{
                .width = cons.max.width,
                .height = cons.min.height,
            },
        },
        .both => Constraints.tight(cons.min),
    };

    if (final_pass) {
        try self.child.layout(ctx, child_cons, true);

        if (!self.child.data.overflow)
            try child_cons.assertFits(self.child.data.size);
    }

    self.data.size = child_cons.max;
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
