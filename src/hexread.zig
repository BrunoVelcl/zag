const std = @import("std");
const win = std.os.windows;

const Benchmark = @import("types.zig").Benchmark;
const SetUp = @import("types.zig").SetUp;
const opt_flags = @import("types.zig").opt_flags;
const RuntimeError = @import("helpers.zig").RuntimeError;

pub extern "Kernel32" fn GetConsoleScreenBufferInfo(hConsoleOutput: win.HANDLE, lpConsoleScreenBufferInfo: *win.CONSOLE_SCREEN_BUFFER_INFO) callconv(win.WINAPI) win.BOOL;
pub extern "Kernel32" fn ReadConsoleOutputCharacterA(hConsoleOutput: win.HANDLE, lpCharacter: win.LPSTR, nLength: win.DWORD, dwReadCoord: win.COORD, lpNumberOfCharsRead: *win.DWORD) callconv(win.WINAPI) win.BOOL;

pub fn hexRead(args: SetUp, allocator: std.mem.Allocator, writer: anytype) !void {
    const handle = try win.GetStdHandle(win.STD_OUTPUT_HANDLE);
    var buffer_info: win.CONSOLE_SCREEN_BUFFER_INFO = std.mem.zeroes(win.CONSOLE_SCREEN_BUFFER_INFO);
    _ = GetConsoleScreenBufferInfo(handle, &buffer_info);

    const columns = buffer_info.srWindow.Right - buffer_info.srWindow.Left;
    const rows = buffer_info.srWindow.Bottom - buffer_info.srWindow.Top;

    var buffer = try allocator.alloc(u8, @intCast(rows * columns));
    defer allocator.free(buffer);

    var chars_read: u32 = 0;

    _ = ReadConsoleOutputCharacterA(handle, @ptrCast(buffer[0..]), @intCast(buffer.len), .{ .X = 0, .Y = buffer_info.srWindow.Top }, &chars_read);

    //Define separators

    const sep = comptime blk: {
        var bitset = std.bit_set.IntegerBitSet(128).initEmpty();
        bitset.set(',');
        bitset.set(' ');
        bitset.set(':');
        bitset.set('-');
        bitset.set('_');
        bitset.set('x');
        bitset.set('X');
        bitset.set('>');
        break :blk bitset;
    };

    if (buffer.len < 4) return;

    var i: usize = 0;
    if (args.option == .default) {
        while (i <= buffer.len - 1) : (i += 1) {
            const sep_left: bool = if (i == 0) true else sep.isSet(isLower128(buffer[i - 1]));
            const sep_right: bool = if (i + 2 >= buffer.len) true else sep.isSet(isLower128(buffer[i + 2]));
            if ((sep_left == true and sep_right == true) and std.ascii.isHex(buffer[i]) and std.ascii.isHex(buffer[i + 1])) {
                const converted: u8 = (try asciiToInt(buffer[i]) << 4) | try asciiToInt(buffer[i + 1]);
                buffer[i] = ' ';
                buffer[i + 1] = converted;
            }
        }
        try writer.print("{s}\n", .{buffer[0..]});
    } else if (args.option == .word) {
        var compress = try allocator.alloc(u8, buffer.len);
        defer allocator.free(compress);
        var j: usize = 0;
        while (i <= buffer.len - 6) : (i += 1) {
            const sep_left: bool = if (i == 0) true else sep.isSet(isLower128(buffer[i - 1]));
            const sep_right: bool = if (i + 4 >= buffer.len) true else sep.isSet(isLower128(buffer[i + 4]));
            if ((sep_left == true and sep_right == true) and std.ascii.isHex(buffer[i]) and std.ascii.isHex(buffer[i + 1]) and std.ascii.isHex(buffer[i + 2]) and std.ascii.isHex(buffer[i + 3])) {
                var converted: u8 = (try asciiToInt(buffer[i]) << 4) | try asciiToInt(buffer[i + 1]);
                compress[j] = converted;
                converted = (try asciiToInt(buffer[i + 2]) << 4) | try asciiToInt(buffer[i + 3]);
                compress[j + 1] = converted;
                j += 2;
            }
        }
        try writer.print("{s}\n", .{compress[0..j]});
    } else {
        return RuntimeError.OptionError;
    }
}

pub fn asciiToInt(char: u8) !u8 {
    if (char >= '0' and char <= '9') {
        return char - 48;
    } else if (char >= 'A' and char <= 'F') {
        return char - 55;
    } else if (char >= 'a' and char <= 'f') {
        return char - 87;
    } else {
        return error.ProgramError;
    }
}

pub const ProgramError = error{ValueError};
//Return zero if number is out of range, prevents values higher than the bitset to be fed into it, so 0 just defaults it to false.
pub fn isLower128(num: u8) u8 {
    if (num > 127) return 0;
    return num;
}
