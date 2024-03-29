// wow. this code is terrible lmao

const std = @import("std");

const Directory = struct {
    dir_offset: u64,
    dir_name: []const u8,
};

var virtual_file_offset: u64 = 0;

pub var file_handle: std.fs.File = undefined;
pub var cwd: std.fs.Dir = undefined;

pub fn unpackV1DataFile(file_name: ?[:0]const u8) !void {
    var file = std.fs.cwd().openFile(file_name.?, .{}) catch {
        std.log.err("could not open data file {s}!", .{file_name.?});
        return;
    };
    file_handle = file;

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
    var directories: [64]Directory = std.mem.zeroes([64]Directory);
    var v_file_size: u64 = 0;

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

        file_header = try file_handle.reader().readInt(u32, .little);

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
                    for (directories) |dir| {
                        allocator.free(dir.dir_name);
                    }
                    std.log.info("unpacked all files", .{});
                    const leak = gpa.deinit();
                    std.log.info("allocator leak = {}", .{leak});
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

            v_file_size = try file_handle.reader().readInt(u32, .little);

            const unpacked_file = try cur_dir.createFile(sliced_f_name, .{});
            try writeFile(unpacked_file, v_file_size, allocator);
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

fn writeFile(file: std.fs.File, bytes_to_read: u64, allocator: std.mem.Allocator) !void {
    const file_data = try allocator.alloc(u8, bytes_to_read);
    _ = try file_handle.reader().readAll(file_data);
    _ = try file.write(file_data);
    allocator.free(file_data);
}
