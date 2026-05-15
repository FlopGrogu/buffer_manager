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
    std.debug.print("created pfn: {any} ", .{result.pfn});

    const query_results = try buffer_manager.PFNToPage(result.pfn, &my_manager);
    std.debug.print("queried page {any} ", .{query_results});

    buffer_manager.FreePageFrame(result.pfn, &my_manager);
    // const err: FileOpenError = AllocationError.OutOfMemory;
    // try expect(err == FileOpenError.OutOfMemory);
    //try buffer_manager.PFNToPage(result.pfn, &my_manager);
}
