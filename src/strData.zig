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
    \\Usage: zag <tool> [arguments]
    \\
    \\Tools:
    \\  init, initexe   Set up an empty Zig template for building executables.
    \\  initlib         Set up an empty Zig template for building libraries.
    \\  time            Measure the execution time of a program.
    \\  hex             Decyphers hexadecimal values into ascii characters
    \\  int             Decyphers integers into ascii characters
    \\
    \\Use 'zag -h <tool>' for tool-specific help.
    \\
;

pub const help_init =
    \\Usage: zag {s} [name]
    \\
    \\Creates a new Zig {s} project.
    \\
    \\Behavior:
    \\  - If no name is provided, the project is initialized in the current directory.
    \\  - If a name is provided, a new directory with that name is created, and the project is set up inside it.
    \\
; //Provide the tool teh user requested and if its a exe or lib

pub const help_time =
    \\Usage: zag time [options] <program to test> [program's options]
    \\
    \\Measures a program's execution speed. Note that it doesn't stop timing on child program "pause" events.
    \\Only relevant measurements can be done on programs that execute without user input.
    \\
    \\Options:
    \\  -i n   Set the number of times (n) you want to test the program.
    \\  -q     "quiet" - Prevents the child program from outputting to the console.
;

pub const help_hex =
    \\Usage: zag hex [options] "Optional input"
    \\
    \\Modes:
    \\  1. Input mode: If you provide hexadecimal values inside quotation marks,
    \\     the program will decipher them and combine the resulting characters.
    \\  2. Console mode: Without direct input, the program will decipher the hex 
    \\     values currently displayed in your console window and replace them in place.
    \\
    \\Options:
    \\  -w      Use this option to decipher 16-bit clusters (e.g., "4865 6c6c 6f20 576f 726c 6421").
    \\          By default, the program deciphers 8-bit clusters (e.g., "48 65 6c 6c 6f 20 57 6f 72 6c 64 21").
;
pub const help_int =
    \\Usage: zag int [options] "Optional input"
    \\
    \\Modes:
    \\  1. Input mode: If you provide integer values inside quotation marks,
    \\     the program will decipher them and combine the resulting characters.
    \\  2. Console mode: Without direct input, the program will decipher the integer
    \\     values from your console window and replace them in place.
;
