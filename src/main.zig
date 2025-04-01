const std = @import("std");
const tb = @import("ToolBox.zig");
const str = @import("strData.zig");
pub fn main() !void {
    //Create options container
    var args = SetUp{};

    //Setup allocator
    const allocator = std.heap.page_allocator;

    //Get argv iterator
    var argv = try std.process.argsWithAllocator(allocator);
    defer argv.deinit();

    //Make a Hashmap of our options
    var options_hash = std.StringArrayHashMap(opt_flags).init(allocator);
    defer options_hash.deinit();
    try options_hash.put("init.lib", .initlib);
    try options_hash.put("initexe", .initexe);
    try options_hash.put("init", .init);
    try options_hash.put("default", .default);
    try options_hash.put("iter", .iter);
    try options_hash.put("quiet", .quiet);
    try options_hash.put("dir", .dir);
    try options_hash.put("-d", .d);
    try options_hash.put("-n", .n);
    try options_hash.put("-i", .i);
    try options_hash.put("-q", .q);
    try options_hash.put("-h", .h);

    //Argv porccessing
    //Extract path and tool(which operation to perform)
    const path = argv.next() orelse return RuntimeError.MissingArgument;
    args.dir_path = tb.strBspaceUntilChar(path, '\\');
    args.module_name = argv.next() orelse return RuntimeError.MissingArgument;
    //Extract options
    while (argv.next()) |arg| {
        switch (options_hash.get(arg) orelse return RuntimeError.UnsuportedArgsError) {
            .d => {
                args.user_dir_path = argv.next() orelse return RuntimeError.MissingArgument;
                args.nqdh |= 0b010;
            },
            .n => {
                args.project_name = argv.next() orelse return RuntimeError.MissingArgument;
            },
            .i => {
                args.iter = try std.fmt.parseInt(usize, argv.next() orelse return RuntimeError.MissingArgument, 10);
            },
            .q => {
                args.nqdh |= 0b100;
            },
            .h => {},
            else => {
                return RuntimeError.UnexpectedInputError;
            },
        }
    }

    //Get writer
    const console_writer = std.io.getStdOut().writer();

    switch (options_hash.get(args.module_name) orelse return RuntimeError.UnexpectedInputError) {
        .init, .initexe, .initlib => {
            if ((args.nqdh & 0b1010) == 0b1010) {
                try console_writer.print("\n-d and -n are mutualy exclusive.", .{});
                return;
            } else {
                try zagInit(args);
            }
        },
        else => {
            try console_writer.print("{s}", .{str.help});
        },
    }
}

//Flags for selecting options
const opt_flags = enum {
    initlib,
    initexe,
    init,
    default,
    iter,
    quiet,
    dir,
    d,
    n,
    i,
    q,
    h,
};

pub fn zagInit(args: SetUp) !void {
    // Get separator
    const sep = [_]u8{std.fs.path.sep};

    //Get correct root and src dir and create them
    var path = tb.PathWritter{};
    var project_name = if (args.nqdh & 0b010 > 0) "" else args.project_name;
    if (tb.isPathValid(args.user_dir_path)) {
        path.write(args.user_dir_path);
        if (args.project_name.len == 0) {
            project_name = path.returnUntilChar(&sep);
        }
    } else {
        path.write(args.dir_path);
        if (args.project_name.len == 0) {
            project_name = path.returnUntilChar(&sep);
        }
    }
    if (args.project_name.len != 0) {
        path.write(&sep);
        path.write(project_name);

        std.fs.makeDirAbsolute(path.value()) catch {};
    } else {
        project_name = path.returnUntilChar(&sep);
        std.fs.makeDirAbsolute(path.value()) catch {};
    }

    //Create flags for file openings
    const create_flags = std.fs.File.CreateFlags{ .exclusive = true, .truncate = true };
    //Build.zig logic for exe and lib
    path.write(&sep);
    path.write("build.zig");
    var build_file = try std.fs.createFileAbsolute(path.value(), create_flags);
    defer build_file.close();
    const build_writer = build_file.writer();

    if (std.mem.eql(u8, args.module_name, "initexe") or std.mem.eql(u8, args.module_name, "init")) {
        try build_writer.print(str.build_exe, .{project_name});
    } else if (std.mem.eql(u8, args.module_name, "initlib")) {
        try build_writer.print(str.build_lib, .{project_name});
    } else {
        return RuntimeError.UnsuportedArgsError;
    }
    path.removeUntilChar(&sep);
    path.write(&sep);

    //Build.zig.zon
    path.write("build.zig.zon");
    const zon_file = try std.fs.createFileAbsolute(path.value(), create_flags);
    defer zon_file.close();
    const zon_writer = zon_file.writer();
    try zon_writer.print(str.zon, .{project_name});
    path.removeUntilChar(&sep);
    path.write(&sep);

    path.write("src");
    try std.fs.makeDirAbsolute(path.value());
    path.write(&sep);

    // main and root branch
    if (std.mem.eql(u8, args.module_name, "initexe") or std.mem.eql(u8, args.module_name, "init")) {
        path.write("main.zig");
        const main_file = try std.fs.createFileAbsolute(path.value(), create_flags);
        defer main_file.close();
        const main_writer = main_file.writer();
        try main_writer.print(str.main_exe, .{});
        path.removeUntilChar(&sep);
    } else if (std.mem.eql(u8, args.module_name, "initlib")) {
        path.write(project_name);
        path.write(".zig");
        const root_file = try std.fs.createFileAbsolute(path.value(), create_flags);
        defer root_file.close();
        const root_writer = root_file.writer();
        try root_writer.print(str.root_lib, .{});
        path.removeUntilChar(&sep);
    } else {
        return RuntimeError.UnsuportedArgsError;
    }
}

//pub fn timer(args: SetUp) !void {}

//Data struct
const SetUp = struct {
    module_name: []const u8 = "",
    dir_path: []const u8 = undefined,
    user_dir_path: []const u8 = "",
    project_name: []const u8 = "",
    iter: usize = 1,
    nqdh: u8 = 0b000,
};

const RuntimeError = error{ ValueError, MissingArgument, MissingIterrator, NOTIMPLEMENTEDError, UnexpectedInputError, UnsuportedArgsError, InvalidPath };
