//! This struct is passed to every box during layouting. It's used to keep track
//! of the current state.

/// This value is set to true by a box to indicate that an overflow has occured,
/// meaning boxes couldn't be fit into their parents.
///
/// This is mainly useful for checking if something has gone wrong.
overflow: bool = false,
