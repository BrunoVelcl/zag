const std = @import("std");
const win = std.os.windows;
pub extern "Kernel32" fn GetConsoleScreenBufferInfo(hConsoleOutput: win.HANDLE, lpConsoleScreenBufferInfo: *win.CONSOLE_SCREEN_BUFFER_INFO) callconv(win.WINAPI) win.BOOL;
pub extern "Kernel32" fn ReadConsoleOutputCharacterA(hConsoleOutput: win.HANDLE, lpCharacter: win.LPSTR, nLength: win.DWORD, dwReadCoord: win.COORD, lpNumberOfCharsRead: *win.DWORD) callconv(win.WINAPI) win.BOOL;

pub fn hexRead(allocator: std.mem.Allocator, writer: anytype) !void {
    const handle = try win.GetStdHandle(win.STD_OUTPUT_HANDLE);
    var buffer_info: win.CONSOLE_SCREEN_BUFFER_INFO = std.mem.zeroes(win.CONSOLE_SCREEN_BUFFER_INFO);
    _ = GetConsoleScreenBufferInfo(handle, &buffer_info);

    const columns = buffer_info.srWindow.Right - buffer_info.srWindow.Left;
    const rows = buffer_info.srWindow.Bottom - buffer_info.srWindow.Top;

    var buff = try allocator.alloc(u8, @intCast(rows * columns));
    defer allocator.free(buff);

    var chars_read: u32 = 0;

    _ = ReadConsoleOutputCharacterA(handle, @ptrCast(buff[0..]), @intCast(buff.len), .{ .X = 0, .Y = buffer_info.srWindow.Top }, &chars_read);
    try scanner(buff[0..]);
    try writer.print("------------------------------------------------------\n", .{});
    try writer.print("{s}\n", .{buff[0..]});
}

pub fn scanner(buffer: []u8) !void {
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

    while (i <= buffer.len - 1) : (i += 1) {
        const sep_left: bool = if (i == 0) true else sep.isSet(isLower128(buffer[i - 1]));
        const sep_right: bool = if (i + 2 >= buffer.len) true else sep.isSet(isLower128(buffer[i + 2]));
        if ((sep_left == true and sep_right == true) and std.ascii.isHex(buffer[i]) and std.ascii.isHex(buffer[i + 1])) {
            const converted: u8 = (try asciiToInt(buffer[i]) << 4) | try asciiToInt(buffer[i + 1]);
            buffer[i] = ' ';
            buffer[i + 1] = converted;
        }
    }
}

pub fn asciiToInt(char: u8) !u8 {
    if (char >= '0' and char <= '9') {
        return char - 48;
    } else if (char >= 'A' and char <= 'F') {
        return char - 55;
    } else if (char >= 'a' and char <= 'f') {
        return char - 87;
    } else return error.ProgramError;
}

pub const ProgramError = error{ValueError};
//Return zero if number is out of range, prevents values higher than the bitset to be fed into it, so 0 just defaults it to false.
pub fn isLower128(num: u8) u8 {
    if (num > 128) return 0;
    return num;
}
