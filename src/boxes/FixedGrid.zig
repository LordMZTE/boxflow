//! A Box that lays its children out in a given amount of rows and columns,
//! each with the same size.
//!
//! This Box always uses all available space.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const Constraints = @import("../Constraints.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Root = @import("../Root.zig");
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

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints) anyerror!void {
    const rows = @divExact(self.children.len, self.cols);

    const col_width = cons.max.width / self.cols;
    const row_height = cons.max.height / rows;

    const child_cons = Constraints.tight(.{
        .width = col_width,
        .height = row_height,
    });

    for (self.children) |child| {
        try child.layout(ctx, child_cons);
        try child_cons.assertFits(child.data.size);
    }

    self.data.size = cons.max;
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    const rows = @divExact(self.children.len, self.cols);

    const col_width = self.data.size.width / self.cols;
    const row_height = self.data.size.height / rows;

    for (self.children) |child, i| {
        const x = (i % self.cols) * col_width;
        const y = @divFloor(i, rows) * row_height;

        child.position(ctx, .{ .x = x, .y = y });
    }

    self.data.pos = pos;
}

pub fn box(self: *Self) Box {
    return Box.init(Self, self, &self.data, layout, position);
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

    var root = Root{
        .root_box = grid.box(),
        .size = .{ .width = 10, .height = 10 },
    };

    const fctx = try root.layout();

    try std.testing.expect(!fctx.overflow);

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
