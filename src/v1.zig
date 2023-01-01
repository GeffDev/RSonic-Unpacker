const std = @import("std");

const Directories = struct {
    dir_offset: u64,
    dir_name: []const u8,
};

var v_file_size: u64 = 0;
var virtual_file_offset: u64 = 0;

pub var file_handle: std.fs.File = undefined;
pub var cwd: std.fs.Dir = undefined;

pub fn unpackV1DataFile() !void {
    var file = std.fs.cwd().openFile("Data.bin", .{}) catch {
        std.log.err("could not open data file!", .{});
        return;
    };
    file_handle = file;
    const stat = try file.stat();
    std.log.info("{}", .{stat.size});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    cwd = std.fs.cwd();

    var file_buf: u8 = 0;
    // dirOffset? idk lol
    var dir_thing: u32 = 0;
    var dir_amount: u8 = 0;
    var file_header: usize = 0;

    try file_handle.seekTo(0);

    try fileRead(&file_buf, 1);
    dir_thing = file_buf;
    try fileRead(&file_buf, 1);
    dir_thing += @as(u32, file_buf) << 8;
    try fileRead(&file_buf, 1);
    dir_thing += @as(u32, file_buf) << 16;
    try fileRead(&file_buf, 1);
    dir_thing += @as(u32, file_buf) << 24;
    try fileRead(&dir_amount, 1);

    // array length must be comptime known so lets just
    // set this to 64 i guess
    var directories: [64]Directories = std.mem.zeroes([64]Directories);

    var i: usize = 0;
    while (i < dir_amount) : (i += 1) {
        var dir_read: [64]u8 = std.mem.zeroes([64]u8);
        var dir_name_len: u8 = 0;
        try fileRead(&dir_name_len, 1);

        var dir_index: u8 = 0;
        while (dir_index < dir_name_len) : (dir_index += 1) {
            try fileRead(&dir_read[dir_index], 1);
        }

        const sliced_dir = try allocator.dupe(u8, dir_read[0..dir_name_len]);
        directories[i].dir_name = sliced_dir;

        try fileRead(&file_buf, 1);
        file_header = file_buf;
        try fileRead(&file_buf, 1);
        file_header += @as(u32, file_buf) << 8;
        try fileRead(&file_buf, 1);
        file_header += @as(u32, file_buf) << 16;
        try fileRead(&file_buf, 1);
        file_header += @as(u32, file_buf) << 24;

        virtual_file_offset = file_header + dir_thing;
        directories[i].dir_offset = virtual_file_offset;
    }

    i = 0;
    var cur_dir: std.fs.Dir = undefined;
    while (i < dir_amount) : (i += 1) {
        cur_dir = try cwd.makeOpenPath(directories[i].dir_name, .{});
        try file.seekTo(directories[i].dir_offset);

        while (try file.getPos() != directories[i + 1].dir_offset) {
            var f_name: [64]u8 = std.mem.zeroes([64]u8);
            var f_name_len: u8 = 0;
            fileRead(&f_name_len, 1) catch |err| {
                if (err == error.EndOfStream) {
                    std.log.info("unpacked all files", .{});
                }
                return;
            };

            var f_len_index: usize = 0;
            while (f_len_index < f_name_len) : (f_len_index += 1) {
                try fileRead(&f_name[f_len_index], 1);
            }

            // getting away with not using an allocator :smirk:
            std.log.info("unpacking file: {s}{s}", .{ directories[i].dir_name, f_name });

            const sliced_f_name = try allocator.dupe(u8, f_name[0..f_name_len]);

            try fileRead(&file_buf, 1);
            v_file_size = file_buf;
            try fileRead(&file_buf, 1);
            v_file_size += @as(u32, file_buf) << 8;
            try fileRead(&file_buf, 1);
            v_file_size += @as(u32, file_buf) << 16;
            try fileRead(&file_buf, 1);
            v_file_size += @as(u32, file_buf) << 24;

            const unpacked_file = try cur_dir.createFile(sliced_f_name, .{});
            try writeFile(unpacked_file, allocator);
            allocator.free(sliced_f_name);
        }
    }
}

fn fileRead(dest: *u8, bytes_to_read: usize) !void {
    var i: usize = 0;
    while (i < bytes_to_read) : (i += 1) {
        dest.* = try file_handle.reader().readByte();
    }
}

/// TODO: there's probably a wayyyy faster way of doing this
/// please speed this up
fn writeFile(file: std.fs.File, allocator: std.mem.Allocator) !void {
    var i: usize = 0;
    var fileData = try allocator.alloc(u8, v_file_size);
    while (i < v_file_size) : (i += 1) {
        fileData[i] = try file_handle.reader().readByte();
    }
    _ = try file.write(fileData);
    allocator.free(fileData);
}
