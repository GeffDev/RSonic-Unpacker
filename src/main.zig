const std = @import("std");
const v1 = @import("v1.zig");

pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var timer = try std.time.Timer.start();
    try v1.unpackV1DataFile();
    const elapsed_time = timer.read();
    std.log.info("elapsed time: {}.{}s", .{elapsed_time / std.time.ns_per_s, elapsed_time / std.time.ns_per_ms});
}
