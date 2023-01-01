const std = @import("std");

const Directories = struct {
    dirOffset: u64,
    dirName: []const u8,
};

var vFileSize: u64 = 0;
var virtualFileOffset: u64 = 0;

pub var fileHandle: std.fs.File = undefined;
pub var cwd: std.fs.Dir = undefined;

pub fn unpackV1DataFile() !void {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var file = std.fs.cwd().openFile("Data.bin", .{}) catch {
        std.log.err("could not open data file!", .{});
        return;
    };
    fileHandle = file;

    cwd = std.fs.cwd();

    var fileBuf: u8 = 0;
    // dirOffset? idk lol
    var dirThing: u32 = 0;
    var dirAmount: u8 = 0;
    var fileHeader: usize = 0;

    try fileHandle.seekTo(0);

    try fileRead(&fileBuf, 1);
    dirThing = fileBuf;
    try fileRead(&fileBuf, 1);
    dirThing += @as(u32, fileBuf) << 8;
    try fileRead(&fileBuf, 1);
    dirThing += @as(u32, fileBuf) << 16;
    try fileRead(&fileBuf, 1);
    dirThing += @as(u32, fileBuf) << 24;
    try fileRead(&dirAmount, 1);

    // array length must be comptime known so lets just
    // set this to 64 i guess
    var directories: [64]Directories = std.mem.zeroes([64]Directories);

    var i: usize = 0;
    while (i < dirAmount) : (i += 1) {
        var dirRead: [64]u8 = std.mem.zeroes([64]u8);
        var dirNameLen: u8 = 0;
        try fileRead(&dirNameLen, 1);

        var dirIndex: u8 = 0;
        while (dirIndex < dirNameLen) : (dirIndex += 1) {
            try fileRead(&dirRead[dirIndex], 1);
        }

        const slicedDir = try allocator.dupe(u8, dirRead[0..dirNameLen]);
        directories[i].dirName = slicedDir;

        try fileRead(&fileBuf, 1);
        fileHeader = fileBuf;
        try fileRead(&fileBuf, 1);
        fileHeader += @as(u32, fileBuf) << 8;
        try fileRead(&fileBuf, 1);
        fileHeader += @as(u32, fileBuf) << 16;
        try fileRead(&fileBuf, 1);
        fileHeader += @as(u32, fileBuf) << 24;

        virtualFileOffset = fileHeader + dirThing;
        directories[i].dirOffset = virtualFileOffset;
    }

    i = 0;
    var curDir: std.fs.Dir = undefined;
    while (i < dirAmount) : (i += 1) {
        curDir = try cwd.makeOpenPath(directories[i].dirName, .{});
        try file.seekTo(directories[i].dirOffset);

        while (try file.getPos() != directories[i + 1].dirOffset) {
            var fName: [64]u8 = std.mem.zeroes([64]u8);
            var fNameLen: u8 = 0;
            fileRead(&fNameLen, 1) catch |err| {
                if (err == error.EndOfStream) {
                    std.log.info("unpacked all files", .{});
                }
                return;
            };

            var fLenIndex: usize = 0;
            while (fLenIndex < fNameLen) : (fLenIndex += 1) {
                try fileRead(&fName[fLenIndex], 1);
            }

            // getting away with not using an allocator :smirk:
            std.log.info("unpacking file: {s}{s}", .{ directories[i].dirName, fName });

            const slicedFName = try allocator.dupe(u8, fName[0..fNameLen]);

            try fileRead(&fileBuf, 1);
            vFileSize = fileBuf;
            try fileRead(&fileBuf, 1);
            vFileSize += @as(u32, fileBuf) << 8;
            try fileRead(&fileBuf, 1);
            vFileSize += @as(u32, fileBuf) << 16;
            try fileRead(&fileBuf, 1);
            vFileSize += @as(u32, fileBuf) << 24;

            const unpackedFile = try curDir.createFile(slicedFName, .{});
            try writeFile(unpackedFile);
            allocator.free(slicedFName);
        }
    }
}

fn fileRead(dest: *u8, bytesToRead: usize) !void {
    var i: usize = 0;
    while (i < bytesToRead) : (i += 1) {
        dest.* = try fileHandle.reader().readByte();
    }
}

/// TODO: there's probably a wayyyy faster way of doing this
/// please speed this up
fn writeFile(file: std.fs.File) !void {
    var i: usize = 0;
    while (i < vFileSize) : (i += 1) {
        try file.writer().writeByte(try fileHandle.reader().readByte());
    }
}
