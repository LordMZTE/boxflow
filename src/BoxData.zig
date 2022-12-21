//! This struct represents fields a Box must have.
//! These fields are accessed by parents as well as the user for working with the laid out boxes.

const Position = @import("Position.zig");
const Size = @import("Size.zig");

pos: Position = .{ .x = 0, .y = 0 },
size: Size = .{ .width = 0, .height = 0 },

/// This is boxflow's equivalent to CSS' `flex-expand`.
///
/// You might be wondering why there's no `flex-shrink` here.
/// The answer is simply that any widget with flex_expand > 0 must always return its minimum
/// possible size (adhering to constraints). This means that the limit of a box being exceeded
/// is simply an overflow.
flex_expand: usize = 0,

/// A flag to indicate if this Box has not been laid out due to an overflow.
/// If this is set, `pos` and `size` must be treated as invalid.
/// All children of this Box must also have the flag set.
overflow: bool = false,
