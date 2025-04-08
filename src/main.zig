const std = @import("std");
const tb = @import("ToolBox.zig");
const str = @import("strData.zig");
const win = std.os.windows;

const Benchmark = @import("types.zig").Benchmark;
const SetUp = @import("types.zig").SetUp;
const opt_flags = @import("types.zig").opt_flags;
const RuntimeError = @import("helpers.zig").RuntimeError;

const zagInit = @import("zagInit.zig").zagInit;
const timer = @import("timer.zig").timer;
const errorHandler = @import("helpers.zig").errorHandler;

pub fn main() !void {

    //Setup allocator
    const allocator = std.heap.page_allocator;

    //Create options container
    var args = SetUp{};
    defer allocator.free(args.utf16); //This is freed here since it needs to have mains scope

    //Get writer
    const console_writer = std.io.getStdOut().writer();

    //Get argv iterator
    var argv = try std.process.argsWithAllocator(allocator);
    defer argv.deinit();

    //Comptime hashmap for argv parsing
    var options_hash = std.StaticStringMap(opt_flags).initComptime(
        .{
            .{ "initlib", .initlib },
            .{ "initexe", .initexe },
            .{ "init", .init },
            .{ "time", .time },
            .{ "timer", .time },
            .{ "-h", .h },
        },
    );

    var timer_hash = std.StaticStringMap(opt_flags).initComptime(.{
        .{ "-i", .i },
        .{ "-q", .q },
    });

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
            .time => {
                args.module_name = hashed_arg;
                while (argv.next()) |time_arg| {
                    const time_options_hash = timer_hash.get(time_arg) orelse .default;
                    switch (time_options_hash) {
                        .i => {
                            args.iter = std.fmt.parseInt(usize, argv.next() orelse return errorHandler(RuntimeError.MissingIterrator, console_writer), 10) catch |err| {
                                try errorHandler(err, console_writer);
                                return;
                            };
                        },
                        .q => {
                            args.quiet = .q;
                        },
                        .default => {
                            args.utf16 = tb.gatherArgvToUTF16(&argv, allocator, time_arg) catch |err| {
                                try errorHandler(err, console_writer);
                                return;
                            };
                            if (args.utf16.len == 0) {
                                try errorHandler(RuntimeError.MissingArgument, console_writer);
                            }
                        },
                        else => {
                            unreachable;
                        },
                    }
                }
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
        .time => {
            timer(args, console_writer) catch |err| {
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
