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
    try options_hash.put("initlib", .initlib);
    try options_hash.put("initexe", .initexe);
    try options_hash.put("init", .init);
    try options_hash.put("default", .default);
    try options_hash.put("dir", .dir);
    try options_hash.put("-i", .i);
    try options_hash.put("-q", .q);
    try options_hash.put("-h", .h);

    //Argv porccessing
    //Extract path and tool(which operation to perform)
    const path = argv.next() orelse return RuntimeError.MissingArgument;
    args.dir_path = tb.strBspaceUntilChar(path, '\\');
    //Extract options
    while (argv.next()) |arg| {
        const hashed_arg = options_hash.get(arg) orelse return RuntimeError.UnsuportedArgsError;
        switch (hashed_arg) {
            .init, .initexe, .initlib => {
                args.module_name = hashed_arg;
                args.project_name = argv.next() orelse break;
            },
            .i => {
                args.iter = try std.fmt.parseInt(usize, argv.next() orelse return RuntimeError.MissingArgument, 10);
            },
            .q => {
                args.quiet = .q;
            },
            .h => {},
            else => {
                return RuntimeError.UnexpectedInputError;
            },
        }
    }

    //Get writer
    const console_writer = std.io.getStdOut().writer();

    switch (args.module_name) {
        .init, .initexe, .initlib => {
            try zagInit(args);
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
    i,
    q,
    h,
};

pub fn zagInit(args: SetUp) !void {
    // Get separator
    const sep = [_]u8{std.fs.path.sep};

    //Get correct root and src dir and create them
    var path = tb.PathWritter{};

    path.write(args.dir_path);

    const project_name = if (args.project_name.len != 0) args.project_name else path.returnUntilChar(&sep);
    path.write(&sep);
    path.write(project_name);
    std.fs.makeDirAbsolute(path.value()) catch {};

    //Create flags for file openings
    const create_flags = std.fs.File.CreateFlags{ .exclusive = true, .truncate = true };
    //Build.zig logic for exe and lib
    path.write(&sep);
    path.write("build.zig");
    var build_file = try std.fs.createFileAbsolute(path.value(), create_flags);
    defer build_file.close();
    const build_writer = build_file.writer();

    switch (args.module_name) {
        .init, .initexe => {
            try build_writer.print(str.build_exe, .{project_name});
        },
        .initlib => {
            try build_writer.print(str.build_lib, .{project_name});
        },
        else => {
            return RuntimeError.UnsuportedArgsError;
        },
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
    switch (args.module_name) {
        .init, .initexe => {
            path.write("main.zig");
            const main_file = try std.fs.createFileAbsolute(path.value(), create_flags);
            defer main_file.close();
            const main_writer = main_file.writer();
            try main_writer.print(str.main_exe, .{});
            path.removeUntilChar(&sep);
        },
        .initlib => {
            path.write(project_name);
            path.write(".zig");
            const root_file = try std.fs.createFileAbsolute(path.value(), create_flags);
            defer root_file.close();
            const root_writer = root_file.writer();
            try root_writer.print(str.root_lib, .{});
            path.removeUntilChar(&sep);
        },
        else => {
            return RuntimeError.UnsuportedArgsError;
        },
    }
}

//pub fn timer(args: SetUp) !void {}

//Data struct
const SetUp = struct {
    module_name: opt_flags = .default,
    dir_path: []const u8 = undefined,
    project_name: []const u8 = "",
    iter: usize = 1,
    quiet: opt_flags = .default,
};

const RuntimeError = error{ ValueError, MissingArgument, MissingIterrator, NOTIMPLEMENTEDError, UnexpectedInputError, UnsuportedArgsError, InvalidPath };
