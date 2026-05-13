//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const BufferManagerError = error{ PageTableSizeExceeded, PageNotFound };
// /// This is a documentation comment to explain the `printAnotherMessage` function below.
// ///
// /// Accepting an `Io.Writer` instance is a handy way to write reusable code.
// pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
//     try writer.print("Run `zig build test` to run the tests.\n", .{});
// }

// pub fn add(a: i32, b: i32) i32 {
//     return a + b;
// }

// test "basic add functionality" {
//     try std.testing.expect(add(3, 7) == 10);
// }
const PageMetadata = struct { pfn: u64, page: *Page };

// Size of page is 1 shifted 12 times to the left which is basically 4096 aka 4kB
const page_size = 1 << 12;
const Page = struct {
    mem: [page_size]u8 align(page_size), //start saving pages on multiples of 4096 in the memory
};
// Allocates a page frame. Also allocates and returns a corresponding page
pub fn AllocPageFrame(bfr_mngr: *BufferManager) !PageMetadata {
    return bfr_mngr.allocPageFrame();
}

// Final free of a page frame
fn FreePageFrame(pfn: u64, bfr_mngr: *BufferManager) !void {
    try bfr_mngr.freePageFrame(pfn);
}
// // Get the page of a pfn either from memory or disk. Incremenst the pin count by
// // one. The pin count is needed to not evict pages that are currently in use
pub fn PFNToPage(pfn: u64, bfr_mngr: *BufferManager) !*Page {
    return try bfr_mngr.pfnToPage(pfn);
}
// // // Marks the page as dirty (e.g. by setting its dirty bit)
// fn MarkDirty(pfn: u64, bfr_mngr: *BufferManager) void {}
// // // Flush a dirty page to disk and clear its dirty bit
// fn FlushPage(pfn: u64, bfr_mngr: *BufferManager) !void {}
// // // Releases a page by decrementing the pin count. Further acceses must first
// // // call PFNToPage() again.
// fn DecrementPinCount(pfn: u64, bfr_mngr: *BufferManager) void {}
// // // Optional
// fn PFNToPageAsync(pfn: u64, bfr_mngr: *BufferManager) !?*Page {}

pub const BufferManager = struct {
    const maxBufferSize = 4;

    var page_table: [maxBufferSize]PageMetadata = undefined;
    var page_table_index: u64 = 0;
    var next_pfn: u64 = 0;

    pub fn init(_: *BufferManager) void {
        for (page_table, 0..) |_, index| {
            page_table[index].pfn = 0;
        }
    }

    pub fn allocPageFrame(_: *BufferManager) !PageMetadata {
        if (page_table_index >= maxBufferSize) {
            return BufferManagerError.PageTableSizeExceeded;
        }
        const page = try std.heap.page_allocator.alloc(Page, 1);
        next_pfn += 1;
        // cast a many item pointer to a normal pointer
        const page_ptr: *Page = @ptrCast(page.ptr);
        const new_page_metadata = PageMetadata{ .page = page_ptr, .pfn = next_pfn };
        // add the new page metadata to the page_table
        page_table[page_table_index] = new_page_metadata;
        return new_page_metadata;
    }

    pub fn pfnToPage(_: *BufferManager, pfn: u64) !*Page {
        for (page_table) |entry| {
            if (entry.pfn == pfn) {
                return entry.page;
            }
        }
        return BufferManagerError.PageNotFound;
    }

    // pub fn freePageFrame(_: *BufferManager, pfn: u64) !PageMetadata {
    //     const page = try std.heap.page_allocator.alloc(Page, 1);
    //     index += 1;
    //     return PageMetadata{ .page = @ptrCast(page.ptr), .pfn = index };
    // }
};
