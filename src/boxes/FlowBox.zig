//! This is the main layout box of boxflow. It can arrange Boxes in either a row or a column,
//! taking into account their flex options.
const std = @import("std");

const Box = @import("../Box.zig");
const BoxData = @import("../BoxData.zig");
const ChildList = @import("../ChildList.zig");
const Clamped = @import("Clamped.zig");
const Contracted = @import("Contracted.zig");
const Constraints = @import("../Constraints.zig");
const LayoutCtx = @import("../LayoutCtx.zig");
const Position = @import("../Position.zig");
const Simple = @import("Simple.zig");
const Size = @import("../Size.zig");

pub const Direction = enum {
    vertical,
    horizontal,
};

data: BoxData = .{},
children: []const Box,
direction: Direction,
alloc: std.mem.Allocator,

// An array containing the offsets of the children.
// This is used by `position` to determine the positions of children.
child_offsets: []usize,

const Self = @This();

pub fn init(ctx: *LayoutCtx, direction: Direction, children: []const Box) !Self {
    var self = .{
        .children = children,
        .direction = direction,
        .alloc = ctx.alloc,

        .child_offsets = try ctx.alloc.alloc(usize, children.len),
    };

    std.mem.set(usize, self.child_offsets, 0);

    return self;
}

pub fn deinit(self: *Self) void {
    self.alloc.free(self.child_offsets);
    self.* = undefined;
}

fn layout(self: *Self, ctx: *LayoutCtx, cons: Constraints, final_pass: bool) anyerror!void {
    _ = final_pass;
    switch (self.direction) {
        .vertical => {
            // the maximum width of the children
            var max_width: usize = 0;

            var cur_pos: usize = 0;
            // first pass, setting initial sizes
            {
                for (self.children) |child| {
                    var child_cons = cons;
                    child_cons.max.height -|= cur_pos;
                    child_cons.min.height -|= cur_pos;

                    try child.layout(ctx, child_cons, false);
                    try child_cons.assertFits(child.data.size);

                    cur_pos += child.data.size.height;

                    if (max_width < child.data.size.width) {
                        max_width = child.data.size.width;
                    }
                }
            }

            // second pass, evaluating flex boxes
            {
                const remaining_space = cons.max.height - cur_pos;
                cur_pos = 0;

                // the amount of extra space that will be added to the flex boxes
                const flex_extra_space = try ctx.alloc.alloc(?f64, self.children.len);
                defer ctx.alloc.free(flex_extra_space);
                std.mem.set(?f64, flex_extra_space, null);

                var flex_sum: f64 = 0;
                for (self.children) |child| {
                    flex_sum += @intToFloat(f64, child.data.flex_expand);
                }

                // set the extra space to the part of remaining space the boxes will get
                for (flex_extra_space, 0..) |*fes, i| {
                    if (self.children[i].data.flex_expand > 0) {
                        fes.* = @intToFloat(f64, self.children[i].data.flex_expand) / flex_sum;
                    }
                }

                // set the extra space of the widgets to the actual absolute amount of space
                for (flex_extra_space) |*espace| {
                    if (espace.*) |*fes| {
                        fes.* *= @intToFloat(f64, remaining_space);
                    }
                }

                // re-layout the flex children with tight constraints
                for (self.children, 0..) |*child, i| {
                    if (flex_extra_space[i]) |fes| {
                        const child_height = @floatToInt(usize, fes) + child.data.size.height;
                        const child_cons = Constraints.tight(.{
                            .width = child.data.size.width,
                            .height = child_height,
                        });

                        try child.layout(ctx, child_cons, true);
                        if (!child.data.overflow)
                            try child_cons.assertFits(child.data.size);
                    }

                    self.child_offsets[i] = cur_pos;

                    cur_pos += child.data.size.height;
                }
            }

            self.data.size = .{
                .height = cur_pos,
                .width = max_width,
            };
        },
        // TODO: deduplicate this
        .horizontal => {
            // the maximum height of the children
            var max_height: usize = 0;

            var cur_pos: usize = 0;
            // first pass, setting initial sizes
            {
                for (self.children) |child| {
                    var child_cons = cons;
                    child_cons.max.width -|= cur_pos;
                    child_cons.min.width -|= cur_pos;

                    try child.layout(ctx, child_cons, false);
                    try child_cons.assertFits(child.data.size);

                    cur_pos += child.data.size.width;

                    if (max_height < child.data.size.height) {
                        max_height = child.data.size.height;
                    }
                }
            }

            // second pass, evaluating flex boxes
            {
                const remaining_space = cons.max.width - cur_pos;
                cur_pos = 0;

                // the amount of extra space that will be added to the flex boxes
                const flex_extra_space = try ctx.alloc.alloc(?f64, self.children.len);
                defer ctx.alloc.free(flex_extra_space);
                std.mem.set(?f64, flex_extra_space, null);

                var flex_sum: f64 = 0;
                for (self.children) |child| {
                    flex_sum += @intToFloat(f64, child.data.flex_expand);
                }

                // set the extra space to the part of remaining space the boxes will get
                for (flex_extra_space, 0..) |*fes, i| {
                    if (self.children[i].data.flex_expand > 0) {
                        fes.* = @intToFloat(f64, self.children[i].data.flex_expand) / flex_sum;
                    }
                }

                // set the extra space of the widgets to the actual absolute amount of space
                for (flex_extra_space) |*espace| {
                    if (espace.*) |*fes| {
                        fes.* *= @intToFloat(f64, remaining_space);
                    }
                }

                // re-layout the flex children with tight constraints
                for (self.children, 0..) |*child, i| {
                    if (flex_extra_space[i]) |fes| {
                        const child_width = @floatToInt(usize, fes) + child.data.size.width;
                        const child_cons = Constraints.tight(.{
                            .width = child_width,
                            .height = child.data.size.height,
                        });

                        try child.layout(ctx, child_cons, true);
                        if (!child.data.overflow)
                            try child_cons.assertFits(child.data.size);
                    }

                    self.child_offsets[i] = cur_pos;

                    cur_pos += child.data.size.width;
                }
            }

            self.data.size = .{
                .height = max_height,
                .width = cur_pos,
            };
        },
    }
}

fn position(self: *Self, ctx: *LayoutCtx, pos: Position) void {
    for (self.children, 0..) |child, i| {
        if (child.data.overflow)
            continue;

        const child_pos = switch (self.direction) {
            .vertical => .{ .x = pos.x, .y = pos.y + self.child_offsets[i] },
            .horizontal => .{ .x = pos.x + self.child_offsets[i], .y = pos.y },
        };
        child.position(ctx, child_pos);
    }
    self.data.pos = pos;
}

fn childrenF(self: *Self, ctx: *LayoutCtx) !?ChildList {
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

test "2 vertical boxes with fixed size" {
    var ctx = LayoutCtx{ .alloc = std.testing.allocator };

    var box_1 = Simple{};
    var box_2 = Simple{};

    const clamp_cons = Constraints{
        .min = .{ .width = 0, .height = 0 },
        .max = .{ .width = 5, .height = 5 },
    };

    var clamp_1 = Clamped{ .child = box_1.box(), .constraints = clamp_cons };
    var clamp_2 = Clamped{ .child = box_2.box(), .constraints = clamp_cons };

    var fbox = try Self.init(
        &ctx,
        .vertical,
        &.{ clamp_1.box(), clamp_2.box() },
    );
    defer fbox.deinit();

    try std.testing.expectEqual(
        @as(usize, 2),
        (try fbox.box().children(&ctx)).?.boxes.len,
    );

    try @import("../main.zig").layout(
        fbox.box(),
        &ctx,
        .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 10, .height = 20 },
        },
    );

    try std.testing.expect(!ctx.overflow);

    try std.testing.expectEqual(
        Size{ .width = 5, .height = 10 },
        fbox.data.size,
    );

    try std.testing.expectEqual(
        BoxData{ .size = .{ .width = 5, .height = 5 } },
        box_1.data,
    );

    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 0, .y = 5 },
            .size = .{ .width = 5, .height = 5 },
        },
        box_2.data,
    );
}

test "2 horizontal boxes with fixed size" {
    var ctx = LayoutCtx{ .alloc = std.testing.allocator };
    var box_1 = Simple{};
    var box_2 = Simple{};

    const clamp_cons = Constraints{
        .min = .{ .width = 0, .height = 0 },
        .max = .{ .width = 5, .height = 5 },
    };

    var clamp_1 = Clamped{ .child = box_1.box(), .constraints = clamp_cons };
    var clamp_2 = Clamped{ .child = box_2.box(), .constraints = clamp_cons };

    var fbox = try Self.init(
        &ctx,
        .horizontal,
        &.{ clamp_1.box(), clamp_2.box() },
    );
    defer fbox.deinit();

    try @import("../main.zig").layout(
        fbox.box(),
        &ctx,
        .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 10, .height = 20 },
        },
    );

    try std.testing.expect(!ctx.overflow);

    try std.testing.expectEqual(
        Size{ .width = 10, .height = 5 },
        fbox.data.size,
    );

    try std.testing.expectEqual(
        BoxData{ .size = .{ .width = 5, .height = 5 } },
        box_1.data,
    );

    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 5, .y = 0 },
            .size = .{ .width = 5, .height = 5 },
        },
        box_2.data,
    );
}

test "2 vertical boxes with equal flex" {
    var ctx = LayoutCtx{ .alloc = std.testing.allocator };
    var box_1 = Simple{};
    var box_2 = Simple{};

    var clamp_1 = Contracted{ .child = box_1.box(), .axis = .vertical };
    var clamp_2 = Contracted{ .child = box_2.box(), .axis = .vertical };

    clamp_1.data.flex_expand = 1;
    clamp_2.data.flex_expand = 1;

    var fbox = try Self.init(
        &ctx,
        .vertical,
        &.{ clamp_1.box(), clamp_2.box() },
    );
    defer fbox.deinit();

    try @import("../main.zig").layout(
        fbox.box(),
        &ctx,
        .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 5, .height = 10 },
        },
    );

    try std.testing.expect(!ctx.overflow);

    try std.testing.expectEqual(
        Size{ .width = 5, .height = 10 },
        fbox.data.size,
    );

    try std.testing.expectEqual(
        BoxData{ .size = .{ .width = 5, .height = 5 } },
        box_1.data,
    );

    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 0, .y = 5 },
            .size = .{ .width = 5, .height = 5 },
        },
        box_2.data,
    );
}

test "flex and fixed combo" {
    var ctx = LayoutCtx{ .alloc = std.testing.allocator };
    var box_1 = Simple{};
    var box_2 = Simple{};

    const clamp_cons = Constraints{
        .min = .{ .width = 0, .height = 0 },
        .max = .{ .width = 5, .height = 1 },
    };

    var clamp_1 = Clamped{ .child = box_1.box(), .constraints = clamp_cons };
    var clamp_2 = Clamped{ .child = box_2.box(), .constraints = clamp_cons };

    clamp_1.data.flex_expand = 1;

    var fbox = try Self.init(
        &ctx,
        .vertical,
        &.{ clamp_1.box(), clamp_2.box() },
    );
    defer fbox.deinit();

    try @import("../main.zig").layout(
        fbox.box(),
        &ctx,
        .{
            .min = .{ .width = 0, .height = 0 },
            .max = .{ .width = 10, .height = 10 },
        },
    );

    try std.testing.expect(!ctx.overflow);

    try std.testing.expectEqual(
        Size{ .width = 5, .height = 10 },
        fbox.data.size,
    );

    try std.testing.expectEqual(
        BoxData{ .size = .{ .width = 5, .height = 9 } },
        box_1.data,
    );

    try std.testing.expectEqual(
        BoxData{
            .pos = .{ .x = 0, .y = 9 },
            .size = .{ .width = 5, .height = 1 },
        },
        box_2.data,
    );
}
