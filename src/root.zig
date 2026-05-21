//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const BufferManagerError = error{ PageTableSizeExceeded, PageNotFound };

const PageMetadata = struct { pfn: u64, page: []Page, is_dirty: bool, pin_count: u64 };

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
pub fn FreePageFrame(pfn: u64, bfr_mngr: *BufferManager) void {
    bfr_mngr.freePageFrame(pfn);
}
// // Get the page of a pfn either from memory or disk. Incremenst the pin count by
// // one. The pin count is needed to not evict pages that are currently in use
pub fn PFNToPage(pfn: u64, bfr_mngr: *BufferManager) !*Page {
    var page_ptr = try bfr_mngr.pfnToPageMetadata(pfn);
    page_ptr.pin_count += 1;
    return @ptrCast(page_ptr.page.ptr);
}
// // Marks the page as dirty (e.g. by setting its dirty bit)
pub fn MarkDirty(pfn: u64, bfr_mngr: *BufferManager) void {
    bfr_mngr.markDirty(pfn);
}
// // // Flush a dirty page to disk and clear its dirty bit
pub fn FlushPage(pfn: u64, bfr_mngr: *BufferManager) !void {
    bfr_mngr.flushPage(pfn);
}

// // Releases a page by decrementing the pin count. Further acceses must first
// // call PFNToPage() again
pub fn DecrementPinCount(pfn: u64, bfr_mngr: *BufferManager) void {
    bfr_mngr.decrementPinCount(pfn);
}

pub const BufferManager = struct {
    pub const maxBufferSize = 4;
    page_table: [maxBufferSize]PageMetadata = undefined,
    next_pfn: u64 = 0,
    //file = undefined,

    pub fn init(self: *BufferManager) void {
        //var name_buf: [32]u8 = undefined;
        //const filename = try std.fmt.bufPrint(&name_buf, "page_{d}.bin", .{pfn});
        const io = std.testing.io;
        _ = std.Io.Dir.cwd().createFile(io, "test.txt", .{}) catch |err| {
            std.debug.print("{any}", .{err});
        };

        self.next_pfn = 0;
        for (self.page_table, 0..) |_, index| {
            self.page_table[index].pfn = 0;
        }
    }

    fn freeIndex(self: *BufferManager) !usize {
        for (self.page_table, 0..) |_, index| {
            if (self.page_table[index].pfn == 0) {
                return index;
            }
        }
        return BufferManagerError.PageTableSizeExceeded;
    }

    pub fn allocPageFrame(self: *BufferManager) !PageMetadata {
        // Get the next free entry position in our page table
        const page_table_index = try self.freeIndex();

        // Allocate a new page
        const page = try std.heap.page_allocator.alloc(Page, 1);

        // Increase the page frame number by one
        // This functions as an id to reference pages
        self.next_pfn += 1;

        // cast a many item pointer to a normal pointer
        const new_page_metadata = PageMetadata{
            .pfn = self.next_pfn,
            .page = page,
            .is_dirty = false,
            .pin_count = 1,
        };
        self.page_table[page_table_index] = new_page_metadata;
        return new_page_metadata;
    }

    // remove pub once testing is done
    pub fn pfnToPageMetadata(self: *BufferManager, pfn: u64) !*PageMetadata {
        for (&self.page_table) |*entry| {
            if (entry.pfn == pfn) {
                return entry;
            }
        }
        return BufferManagerError.PageNotFound;
    }

    pub fn freePageFrame(self: *BufferManager, pfn: u64) void {
        if (self.pfnToPageMetadata(pfn)) |page_metadata| {
            //std.debug.print("{any}", .{page_metadata.page.ptr});
            std.heap.page_allocator.free(page_metadata.page);
            page_metadata.*.pfn = 0;
        } else |_| {
            //std.debug.print("haha", .{});
        }
    }
    pub fn markDirty(self: *BufferManager, pfn: u64) void {
        if (self.pfnToPageMetadata(pfn)) |page_metadata| {
            std.debug.print("page metadata: {any}", .{page_metadata.is_dirty});
            page_metadata.is_dirty = true;
        } else |_| {
            //std.debug.print("haha", .{});
        }
    }

    pub fn decrementPinCount(self: *BufferManager, pfn: u64) void {
        if (self.pfnToPageMetadata(pfn)) |page_metadata| {
            if (page_metadata.pin_count > 0) {
                std.debug.print("page metadata: {any}", .{page_metadata.pin_count});
                page_metadata.pin_count -= 1;
            }
        } else |_| {
            //std.debug.print("haha", .{});
        }
    }

    pub fn flushPage(self: *BufferManager, pfn: u64) void {
        if (self.pfnToPageMetadata(pfn)) |page_metadata| {
            if (!page_metadata.is_dirty) return;
            std.debug.print("page metadata is dirty: {any}", .{page_metadata.is_dirty});
            // open file at location l
            //(page_metadata.page;

        } else |_| {
            //std.debug.print("haha", .{});
        }
    }
};
