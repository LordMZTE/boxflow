//! This box adds n pixels of padding around all sides of a child box.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const Constraints = @import("../Constraints.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Root = @import("../Root.zig");
const Simple = @import("Simple.zig");
const Size = @import("../Size.zig");

data: BoxData = .{},
child: Box,
padding: usize,

const Self = @This();

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints) anyerror!void {
    if (cons.max.width <= self.padding * 2 or cons.max.height <= self.padding * 2) {
        ctx.overflow = true;
        return;
    }

    const child_max = Size{
        .width = cons.max.width - self.padding * 2,
        .height = cons.max.height - self.padding * 2,
    };
    const child_cons = Constraints{
        .min = .{
            // ensure that we don't get incorrect constraints when the
            // padded constraints are smaller than our minimum
            .width = std.math.min(cons.min.width, child_max.width),
            .height = std.math.min(cons.min.height, child_max.height),
        },
        .max = child_max,
    };
    try self.child.layout(ctx, child_cons);
    try child_cons.assertFits(self.child.data.size);

    self.data.size = .{
        .width = self.child.data.size.width + self.padding * 2,
        .height = self.child.data.size.height + self.padding * 2,
    };
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    self.data.pos = pos;
    self.child.position(ctx, .{ .x = pos.x + self.padding, .y = pos.y + self.padding });
}

pub fn box(self: *Self) Box {
    return Box.init(Self, self, &self.data, layout, position);
}

test "simple layout" {
    var sbox = Simple{};

    var padded = Self{ .child = sbox.box(), .padding = 2 };

    var root = Root{ .root_box = padded.box(), .size = .{ .width = 10, .height = 10 } };
    const fctx = try root.layout();

    try std.testing.expect(!fctx.overflow);
    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 2, .y = 2 },
            .size = .{ .width = 6, .height = 6 },
        },
        sbox.data,
    );
}

test "overflow" {
    var child = Simple{};
    var padded = Self{ .child = child.box(), .padding = 2 };

    var root = Root{ .root_box = padded.box(), .size = .{ .width = 1, .height = 1 } };

    const fctx = try root.layout();
    try std.testing.expect(fctx.overflow);
}

test "tight constraints" {
    const cons = Constraints.tight(.{ .width = 10, .height = 10 });
    var b = Simple{};
    var padding = Self{ .child = b.box(), .padding = 1 };

    var ctx = LayoutCtx{};
    try padding.box().layout(&ctx, cons);

    try std.testing.expect(!ctx.overflow);
}
