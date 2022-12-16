//! This struct is the main attraction of boxflow.
//!
//! A box is simply an element which can be laid out.
//!
//! This type is dynamically dispatched, similarly to `std.mem.Allocator`.
//! For some example implementations, see `LinearBox`.

const Constraints = @import("Constraints.zig");
const LayoutCtx = @import("LayoutCtx.zig");
const Size = @import("Size.zig");
const Position = @import("Position.zig");
const BoxData = @import("BoxData.zig");

pub const LayoutFn = fn (*anyopaque, *LayoutCtx, Constraints, bool) anyerror!void;
pub const PositionFn = fn (*anyopaque, *LayoutCtx, Position) void;

ctx: *anyopaque,
data: *BoxData,

layoutFn: *const LayoutFn,
positionFn: *const PositionFn,

const Self = @This();

/// Creates a new dynamic Box object using the given context.
/// The pointee of `data` will be written to by the layouter in order to position the Box,
/// so ensure that the pointer remains valid until layouting is complete.
///
/// If your widget is flexible, make sure to always return the minimum size you can.
/// If `flex_expand` is > 0, the parent should increase the minimum size.
pub fn init(
    comptime T: type,
    ctx: *T,
    data: *BoxData,
    layoutFn: fn (*T, *LayoutCtx, Constraints, bool) anyerror!void,
    positionFn: fn (*T, *LayoutCtx, Position) void,
) Self {
    return .{
        .ctx = ctx,
        .data = data,

        .layoutFn = @ptrCast(*const LayoutFn, &layoutFn),
        .positionFn = @ptrCast(*const PositionFn, &positionFn),
    };
}

/// Performs the layout of the Box.
///
/// This function will layout a Box, as well as possible children.
/// If this Box has children, it should not set their positions using `position`,
/// but only store them so they can later be set to absolute positions when `position` is called.
///
/// After the box has determined its position, it should set the
/// `pos` field of its `BoxData` accordingly.
///
/// The `final_pass` parameter allows for optimization. If the parent container
/// needs to do multiple layout passes, the Box can avoid layouting children fully if
/// there will be more passes later on.
/// For example, FlowBox sets this to false for the initial pass.
///
/// This function may be called multiple times during layouting,
/// but only once with `final_pass` set to true.
pub fn layout(
    self: *const Self,
    ctx: *LayoutCtx,
    constraints: Constraints,
    final_pass: bool,
) anyerror!void {
    return self.layoutFn(self.ctx, ctx, constraints, final_pass);
}

/// This is called by the parent after layouting is complete. A Box implementing this
/// should set the position data of its `BoxData` field as well as call `position` on its children,
/// adjusting the position passed to them.
///
/// This function must only be called once as a final step of layouting.
pub fn position(self: *const Self, ctx: *LayoutCtx, pos: Position) void {
    self.positionFn(self.ctx, ctx, pos);
}
