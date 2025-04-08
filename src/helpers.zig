pub const RuntimeError = error{ ValueError, MissingArgument, MissingIterrator, UnexpectedInputError, UnsuportedArgsError, UnknownError, ToolError, OptionError, LowIterator };

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
    const option = "Error: Option does not exist, use -h for help.";
    const file = "Error: Program/File not found. Check if it exists or if you misspelled it.";
    const iter_below_1 = "Error: Iterator value (-i) can't be less than 1.";

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
        error.OptionError => {
            try writer.print(option, .{});
        },
        error.FileNotFound => {
            try writer.print(file, .{});
        },
        error.LowIterator, error.OverflowError, error.ParseIntError => {
            try writer.print(iter_below_1, .{});
        },
        else => {
            try writer.print(unknown, .{});
        },
    }
}
