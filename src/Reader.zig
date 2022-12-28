const std = @import("std");

var readPos: u64 = 0;
var fileSize: u64 = 0;
var vFileSize: u64 = 0;
var bufferPosition: u64 = 0;
var readSize: u64 = 0;
var fileBuffer: [8192]u8 = std.mem.zeroes([8192]u8);

pub var fileHandle: std.fs.File = undefined;

pub fn unpackV1DataFile() !void {
    var file = std.fs.cwd().openFile("Data.bin", .{}) catch {
        std.log.err("could not open data file!", .{});
        return;
    };
    fileHandle = file;

    const stat = try file.stat();
    fileSize = stat.size;

    var fileBuf: u8 = 0;
    // TODO: give this a name LOL
    var dirThing: u32 = 0;
    var dirAmount: u8 = 0;
    var dirLen: u8 = 0;
    var dirRead: [64]u8 = std.mem.zeroes([64]u8);
    // Is this named correctly?
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
    
    var i: usize = 0;
    while (i < dirAmount) : (i += 1) {
        try fileRead(&dirLen, 1); 
        var nameIndex: usize = 0;

        while (nameIndex < dirLen) : (nameIndex += 1) {
            try fileRead(&dirRead[nameIndex], 1);
        }

        try fileRead(&fileBuf, 1);
        fileHeader = fileBuf;
        try fileRead(&fileBuf, 1);
        fileHeader += @as(u32, fileBuf) << 8;
        try fileRead(&fileBuf, 1);
        fileHeader += @as(u32, fileBuf) << 16;
        try fileRead(&fileBuf, 1);
        fileHeader += @as(u32, fileBuf) << 24;
    }
}

pub fn fileRead(dest: *u8, bytesToRead: usize) !void {
    var i: usize = 0;
    if (readPos < fileSize) {
        while (i < bytesToRead) : (i += 1) {
            dest.* = try fileHandle.reader().readByte();
            readPos += 1;
        }
    }
}