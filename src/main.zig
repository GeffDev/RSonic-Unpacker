const std = @import("std");
const v1 = @import("v1.zig");

pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var timer = try std.time.Timer.start();
    // Parse arguments
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var args = try std.process.ArgIterator.initWithAllocator(alloc);
    _ = args.next();
    const file_name = args.next();

    try v1.unpackV1DataFile(file_name);
    // Get elapsed time and print
    const elapsed_time = timer.read();

    _ = gpa.deinit();
    std.log.info("elapsed time: {}.{}s", .{ elapsed_time / std.time.ns_per_s, elapsed_time / std.time.ns_per_ms });
}
