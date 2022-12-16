//! This Box clamps the size of the child to some given constraints
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

pub fn box(self: *Self) Box {
    return Box.init(Self, self, &self.data, layout, position);
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

    var root = Root{ .root_box = lim.box(), .size = .{ .width = 10, .height = 10 } };

    const fctx = try root.layout();

    try std.testing.expect(!fctx.overflow);
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

    var root = Root{ .root_box = lim.box(), .size = .{ .width = 5, .height = 5 } };

    const fctx = try root.layout();

    try std.testing.expect(!fctx.overflow);
    try std.testing.expectEqual(Size{ .width = 5, .height = 5 }, b.data.size);
}
