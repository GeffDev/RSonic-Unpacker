const std = @import("std");
const reader = @import("Reader.zig");

pub fn main() !void {
    //reader.fileHandle = file;
    try reader.unpackV1DataFile();
}
