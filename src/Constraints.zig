//! This struct represents the freedom a Box gets when determining its size.
//! It's passed to a Box by it's parent and is used to set limits to the size it can have.
const std = @import("std");

const Size = @import("Size.zig");

min: Size,
max: Size,

const Self = @This();

/// Clamps a given size to fit the Constraints
pub fn clamp(self: Self, size: Size) Size {
    return .{
        .width = std.math.clamp(size.width, self.min.width, self.max.width),
        .height = std.math.clamp(size.height, self.min.height, self.max.height),
    };
}

/// Asserts that a size is within the constraints.
/// It's good practice to call this on children to verify the value they return from `layout`.
pub fn assertFits(self: Self, size: Size) error{ConstraintViolation}!void {
    if (!self.fits(size))
        return error.ConstraintViolation;
}

/// Checks if a size fits the constraints.
pub fn fits(self: Self, size: Size) bool {
    return size.width >= self.min.width and
        size.height >= self.min.height and
        size.width <= self.max.width and
        size.height <= self.max.height;
}

/// Helper for constructing a tight constraint for a given size.
pub fn tight(size: Size) Self {
    return .{
        .min = size,
        .max = size,
    };
}

/// Checks if this is a tight constraint.
pub fn isTight(self: Self) bool {
    return std.meta.eql(self.min, self.max);
}
