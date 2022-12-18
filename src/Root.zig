//! The root container of a layout tree.
//! Use this type to layout your boxes.
const std = @import("std");
const Box = @import("Box.zig");
const Constraints = @import("Constraints.zig");
const LayoutCtx = @import("LayoutCtx.zig");
const Size = @import("Size.zig");

root_box: Box,
size: Size,

const Self = @This();

/// Performs the layouting of a box tree.
///
/// Returns the final layout context.
pub fn layout(self: *Self, alloc: std.mem.Allocator) !LayoutCtx {
    var ctx = LayoutCtx{
        .alloc = alloc,
    };

    try self.layoutWithContext(&ctx);

    return ctx;
}

pub fn layoutWithContext(self: *Self, ctx: *LayoutCtx) !void {
    const constraints = Constraints{
        .min = .{ .width = 0, .height = 0 },
        .max = self.size,
    };

    try self.root_box.layout(ctx, constraints, true);
    self.root_box.position(ctx, .{ .x = 0, .y = 0 });
}
