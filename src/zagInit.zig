const std = @import("std");
const tb = @import("ToolBox.zig");
const str = @import("strData.zig");
const win = std.os.windows;

const Benchmark = @import("types.zig").Benchmark;
const SetUp = @import("types.zig").SetUp;
const opt_flags = @import("types.zig").opt_flags;

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
            try path.writeNoSep(".zig");
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
    path.removeUntilSep(); // This is now the projects dir
    try writer.print("Successfully created project in: {s}", .{path.value()});
}
