const std = @import("std");

comptime {
    // Make sure all tests run
    if (@import("builtin").is_test) {
        std.testing.refAllDeclsRecursive(@This());
    }
}

pub const boxes = @import("boxes.zig");

pub const Box = @import("Box.zig");
pub const BoxData = @import("BoxData.zig");
const ChildList = @import("ChildList.zig");
pub const Constraints = @import("Constraints.zig");
pub const LayoutCtx = @import("LayoutCtx.zig");
pub const Position = @import("Position.zig");
pub const Size = @import("Size.zig");

pub fn layout(root_box: Box, ctx: *LayoutCtx, root_constraints: Constraints) !void {
    try root_box.layout(ctx, root_constraints, true);
    root_box.position(ctx, .{ .x = 0, .y = 0 });
}
