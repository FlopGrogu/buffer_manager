const std = @import("std");
const Io = std.Io;

const buffer_manager = @import("buffer_manager");

pub fn main(_: std.process.Init) !void {
    var my_manager = buffer_manager.BufferManager{};
    my_manager.init();
    _ = try buffer_manager.AllocPageFrame(&my_manager);
    _ = try buffer_manager.AllocPageFrame(&my_manager);
    _ = try buffer_manager.AllocPageFrame(&my_manager);
    //_ = try buffer_manager.AllocPageFrame(&my_manager);
    const result = try buffer_manager.AllocPageFrame(&my_manager);
    //std.debug.print("created pfn: {any} ", .{result.pfn});

    // const query_results = try buffer_manager.PFNToPage(result.pfn, &my_manager);
    // std.debug.print("queried page {any} ", .{query_results});
    //std.debug.print("queried page {any} ", .{query_results});
    //buffer_manager.FreePageFrame(result.pfn, &my_manager);
    buffer_manager.MarkDirty(result.pfn, &my_manager);
}

test "alloc page frame" {
    var mgr = buffer_manager.BufferManager{};
    mgr.init();

    // Make sure that the pfn is always increasing by 1
    for (0..buffer_manager.BufferManager.maxBufferSize) |index| {
        const result = try buffer_manager.AllocPageFrame(&mgr);
        try std.testing.expect(result.pfn == index + 1);
    }

    // Check that PageTableSizeExceeded error is thrown if page table is out of space
    _ = buffer_manager.AllocPageFrame(&mgr) catch |err| {
        try std.testing.expect(err == buffer_manager.BufferManagerError.PageTableSizeExceeded);
    };
}

test "free page frame" {
    var mgr = buffer_manager.BufferManager{};
    mgr.init();
    _ = try buffer_manager.AllocPageFrame(&mgr);
    _ = try buffer_manager.AllocPageFrame(&mgr);
    _ = try buffer_manager.AllocPageFrame(&mgr);
    const result = try buffer_manager.AllocPageFrame(&mgr);
    buffer_manager.FreePageFrame(result.pfn, &mgr);
    _ = try buffer_manager.AllocPageFrame(&mgr);
    // Check that PageTableSizeExceeded error is thrown if page table is out of space
    _ = buffer_manager.AllocPageFrame(&mgr) catch |err| {
        try std.testing.expect(err == buffer_manager.BufferManagerError.PageTableSizeExceeded);
    };
}

test "mark page as dirty" {
    var mgr = buffer_manager.BufferManager{};
    mgr.init();
    const result = try buffer_manager.AllocPageFrame(&mgr);
    buffer_manager.MarkDirty(result.pfn, &mgr);
    const entry = try mgr.pfnToPageMetadata(result.pfn);
    try std.testing.expect(entry.is_dirty == true);
}

test "decrement pin count" {
    var mgr = buffer_manager.BufferManager{};
    mgr.init();
    const result = try buffer_manager.AllocPageFrame(&mgr);

    _ = try buffer_manager.PFNToPage(result.pfn, &mgr);
    var entry = try mgr.pfnToPageMetadata(result.pfn);
    try std.testing.expect(entry.pin_count == 2);

    entry = try mgr.pfnToPageMetadata(result.pfn);
    buffer_manager.DecrementPinCount(result.pfn, &mgr);
    try std.testing.expect(entry.pin_count == 1);

    entry = try mgr.pfnToPageMetadata(result.pfn);
    buffer_manager.DecrementPinCount(result.pfn, &mgr);
    try std.testing.expect(entry.pin_count == 0);

    entry = try mgr.pfnToPageMetadata(result.pfn);
    buffer_manager.DecrementPinCount(result.pfn, &mgr);
    try std.testing.expect(entry.pin_count == 0);
}
