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
pub fn layout(self: *Self) !LayoutCtx {
    const constraints = Constraints{
        .min = .{ .width = 0, .height = 0 },
        .max = self.size,
    };

    var ctx = LayoutCtx{};

    try self.root_box.layout(&ctx, constraints);
    self.root_box.position(&ctx, .{ .x = 0, .y = 0 });

    return ctx;
}
