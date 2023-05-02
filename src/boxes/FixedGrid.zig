//! A Box that lays its children out in a given amount of rows and columns,
//! each with the same size.
//!
//! This Box always uses all available space.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const ChildList = @import("../ChildList.zig");
const Constraints = @import("../Constraints.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Size = @import("../Size.zig");
const Simple = @import("Simple.zig");

data: BoxData = .{},

/// The amount of columns this grid will have.
/// The caller asserts that this is nonzero.
cols: usize,

/// The children of this grid, in reading order.
/// The caller asserts that `children.len % cols == 0`.
children: []const Box,

const Self = @This();

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints, final_pass: bool) anyerror!void {
    if (final_pass) {
        const rows = @divExact(self.children.len, self.cols);

        const col_width = cons.max.width / self.cols;
        const row_height = cons.max.height / rows;

        const child_cons = Constraints.tight(.{
            .width = col_width,
            .height = row_height,
        });

        for (self.children) |child| {
            try child.layout(ctx, child_cons, true);
            if (!child.data.overflow)
                try child_cons.assertFits(child.data.size);
        }
    }

    self.data.size = cons.max;
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    const rows = @divExact(self.children.len, self.cols);

    const col_width = self.data.size.width / self.cols;
    const row_height = self.data.size.height / rows;

    for (self.children, 0..) |child, i| {
        if (child.data.overflow)
            continue;

        const x = pos.x + (i % self.cols) * col_width;
        const y = pos.y + @divFloor(i, rows) * row_height;

        child.position(ctx, .{ .x = x, .y = y });
    }

    self.data.pos = pos;
}

fn childrenF(self: *Self, ctx: *LayoutCtx) anyerror!?ChildList {
    _ = ctx;
    return .{ .boxes = self.children };
}

pub fn box(self: *Self) Box {
    return Box.init(
        Self,
        self,
        &self.data,
        layout,
        position,
        childrenF,
    );
}

test "2x2 simple grid" {
    var inners = [1]Simple{.{}} ** 4;
    var grid = Self{
        .cols = 2,
        .children = &.{
            inners[0].box(),
            inners[1].box(),
            inners[2].box(),
            inners[3].box(),
        },
    };

    var ctx = LayoutCtx{ .alloc = std.testing.allocator };
    try @import("../main.zig").layout(
        grid.box(),
        &ctx,
        .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 10, .height = 10 },
        },
    );

    try std.testing.expect(!ctx.overflow);

    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 0, .y = 0 },
            .size = .{ .width = 5, .height = 5 },
        },
        inners[0].data,
    );
    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 5, .y = 0 },
            .size = .{ .width = 5, .height = 5 },
        },
        inners[1].data,
    );
    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 0, .y = 5 },
            .size = .{ .width = 5, .height = 5 },
        },
        inners[2].data,
    );
    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 5, .y = 5 },
            .size = .{ .width = 5, .height = 5 },
        },
        inners[3].data,
    );
}
