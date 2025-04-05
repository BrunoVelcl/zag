const std = @import("std");
const tb = @import("ToolBox.zig");
const str = @import("strData.zig");
pub fn main() !void {
    //Create options container
    var args = SetUp{};

    //Get writer
    const console_writer = std.io.getStdOut().writer();

    //Setup allocator
    const allocator = std.heap.page_allocator;

    //Get argv iterator
    var argv = try std.process.argsWithAllocator(allocator);
    defer argv.deinit();

    //Comptime hashmap for argv parsing
    var options_hash = std.StaticStringMap(opt_flags).initComptime(
        .{
            .{ "initlib", .initlib },
            .{ "initexe", .initexe },
            .{ "init", .init },
            .{ "default", .default },
            .{ "dir", .dir },
            .{ "-i", .i },
            .{ "-q", .q },
            .{ "-h", .h },
        },
    );

    //Argv porccessing
    //Extract path and tool(which operation to perform)
    args.dir_path = argv.next() orelse unreachable;

    //Extract options
    while (argv.next()) |arg| {
        const hashed_arg = options_hash.get(arg) orelse {
            try errorHandler(RuntimeError.ToolError, console_writer);
            return;
        };
        switch (hashed_arg) {
            .init, .initexe, .initlib => {
                args.module_name = hashed_arg;
                args.project_name = argv.next() orelse break;
            },
            .i => {
                args.iter = std.fmt.parseInt(usize, argv.next() orelse return errorHandler(RuntimeError.MissingIterrator, console_writer), 10) catch |err| {
                    try errorHandler(err, console_writer);
                    return;
                };
            },
            .q => {
                args.quiet = .q;
            },
            .h => {
                args.module_name = hashed_arg;
                args.option = options_hash.get(argv.next() orelse "default") orelse .default;
            },
            else => {
                unreachable;
            },
        }
    }

    switch (args.module_name) {
        .init, .initexe, .initlib => {
            zagInit(args, console_writer) catch |err| {
                try errorHandler(err, console_writer);
                return;
            };
        },
        .h => {
            switch (args.option) {
                .default => {
                    try console_writer.print("No such option:\n\n", .{});
                    try console_writer.print(str.help, .{});
                },
                .init, .initexe => {
                    try console_writer.print(str.help_init, .{ "init", "executable" });
                },
                .initlib => {
                    try console_writer.print(str.help_init, .{ "initlib", "library" });
                },
                else => {
                    unreachable;
                },
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
    i,
    q,
    h,
};

pub fn zagInit(args: SetUp, writer: anytype) !void {
    //Get correct root and src dir and create them
    var path = tb.PathWritter{};

    path.write(args.dir_path) catch unreachable;
    path.removeUntilSep(); //Remove the filename from our path
    const project_name = if (args.project_name.len != 0) args.project_name else path.returnUntilSep();
    path.write(project_name) catch unreachable;
    try std.fs.makeDirAbsolute(path.value());

    //Create flags for file openings
    const create_flags = std.fs.File.CreateFlags{ .exclusive = true, .truncate = true };
    //Build.zig logic for exe and lib
    try path.write("build.zig");
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
            unreachable;
        },
    }
    path.removeUntilSep();

    //Build.zig.zon
    try path.write("build.zig.zon");
    const zon_file = try std.fs.createFileAbsolute(path.value(), create_flags);
    defer zon_file.close();
    const zon_writer = zon_file.writer();
    try zon_writer.print(str.zon, .{project_name});
    path.removeUntilSep();

    try path.write("src");
    try std.fs.makeDirAbsolute(path.value());

    // main and root branch
    switch (args.module_name) {
        .init, .initexe => {
            try path.write("main.zig");
            const main_file = try std.fs.createFileAbsolute(path.value(), create_flags);
            defer main_file.close();
            const main_writer = main_file.writer();
            try main_writer.print(str.main_exe, .{});
            path.removeUntilSep();
        },
        .initlib => {
            try path.write(project_name);
            try path.write(".zig");
            const root_file = try std.fs.createFileAbsolute(path.value(), create_flags);
            defer root_file.close();
            const root_writer = root_file.writer();
            try root_writer.print(str.root_lib, .{});
            path.removeUntilSep();
        },
        else => {
            unreachable;
        },
    }
    path.removeUntilSep(); // This is now the cwd
    try writer.print("Successfully created project in: {s}", .{path.value()});
}

//pub fn timer(args: SetUp) !void {}

//Data struct
const SetUp = struct {
    module_name: opt_flags = .default,
    option: opt_flags = .default,
    dir_path: []const u8 = undefined,
    project_name: []const u8 = "",
    iter: usize = 1,
    quiet: opt_flags = .default,
};

const RuntimeError = error{ ValueError, MissingArgument, MissingIterrator, UnexpectedInputError, UnsuportedArgsError, UnknownError, ToolError };

pub fn errorHandler(err: anyerror, writer: anytype) !void {

    //const allocation_failure = "Error: Failed to write to memory, exiting program.";
    //const not_int = "Error: entered argument is not a valid integer.";
    const value = "Error: Invalid input value.";
    const margument = "Error: Missing argument after option, use -h for help.";
    const miter = "Error: Missing iterator value.";
    const unexpected = "Error: Unexpected user input, use -h for help.";
    const unsupported = "Error: Unsupported tool entered, use -h for help.";
    const unknown = "Error: An unknown error occurred.";
    const mkdir = "Error: Directory creation failed. Check that it dosen't already exist.";
    const tool = "Error: Tool dosen't exist, use -h for help.";
    const not_int = "Error: Value provided after -i is not a valid integer.";

    switch (err) {
        error.ValueError => {
            try writer.print(value, .{});
        },
        error.MissingArgument => {
            try writer.print(margument, .{});
        },
        error.MissingIterrator => {
            try writer.print(miter, .{});
        },
        error.UnexpectedInputError => {
            try writer.print(unexpected, .{});
        },
        error.UnsuportedArgsError => {
            try writer.print(unsupported, .{});
        },
        error.PathAlreadyExists => {
            try writer.print(mkdir, .{});
        },
        error.InvalidCharacter => {
            try writer.print(not_int, .{});
        },
        error.ToolError => {
            try writer.print(tool, .{});
        },
        else => {
            try writer.print(unknown, .{});
        },
    }
}
