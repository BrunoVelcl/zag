pub const build_exe =
    \\const std = @import("std");
    \\
    \\pub fn build(b: *std.Build) void {{
    \\    const target = b.standardTargetOptions(.{{}});
    \\
    \\    const optimize = b.standardOptimizeOption(.{{}});
    \\
    \\    const exe = b.addExecutable(.{{
    \\        .name = "{s}",
    \\        .root_source_file = b.path("src/main.zig"),
    \\        .target = target,
    \\        .optimize = optimize,
    \\    }});
    \\
    \\    b.installArtifact(exe);
    \\
    \\    const run_cmd = b.addRunArtifact(exe);
    \\
    \\    run_cmd.step.dependOn(b.getInstallStep());
    \\
    \\    if (b.args) |args| {{
    \\        run_cmd.addArgs(args);
    \\    }}
    \\
    \\    const run_step = b.step("run", "Run the app");
    \\    run_step.dependOn(&run_cmd.step);
    \\
    \\    const exe_unit_tests = b.addTest(.{{
    \\        .root_source_file = b.path("src/main.zig"),
    \\        .target = target,
    \\        .optimize = optimize,
    \\    }});
    \\
    \\    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    \\
    \\    const test_step = b.step("test", "Run unit tests");
    \\    test_step.dependOn(&run_exe_unit_tests.step);
    \\}}
; // provide name when printing!!!

pub const main_exe =
    \\const std = @import("std");
    \\
    \\pub fn main() !void {{
    \\
    \\}}
;

pub const build_lib =
    \\const std = @import("std");
    \\
    \\pub fn build(b: *std.Build) void {{
    \\    const target = b.standardTargetOptions(.{{}});
    \\
    \\    const optimize = b.standardOptimizeOption(.{{}});
    \\
    \\    const lib = b.addStaticLibrary(.{{
    \\        .name = "{s}",
    \\        .root_source_file = b.path("src/ToolBox.zig"),
    \\        .target = target,
    \\        .optimize = optimize,
    \\    }});
    \\
    \\    b.installArtifact(lib);
    \\
    \\    const lib_unit_tests = b.addTest(.{{
    \\        .root_source_file = b.path("src/ToolBox.zig"),
    \\        .target = target,
    \\        .optimize = optimize,
    \\    }});
    \\
    \\    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    \\
    \\    const test_step = b.step("test", "Run unit tests");
    \\    test_step.dependOn(&run_lib_unit_tests.step);
    \\}}
; // provide name when printing!!!

pub const root_lib =
    \\const std = @import("std");
    \\const testing = std.testing;
;

pub const zon =
    \\.{{
    \\    .name = "{s}",
    \\
    \\    .version = "0.0.0",
    \\
    \\    .dependencies = .{{
    \\
    \\    }},
    \\
    \\    .paths = .{{
    \\        "build.zig",
    \\        "build.zig.zon",
    \\        "src",
    \\    }},
    \\}}
; // provide name when printing!!!

pub const help =
    \\Usage: zag tool [options]
    \\
    \\Tools:
    \\  init, initexe   Sets up empty zig template for building executables.
    \\  initlib         Sets up empty zig template for building libraries.
    \\
    \\  Options: -n <project_name> Sets up a new folder and files to reflect this.  
;
