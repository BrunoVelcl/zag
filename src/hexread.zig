const std = @import("std");
const win = std.os.windows;

const Benchmark = @import("types.zig").Benchmark;
const SetUp = @import("types.zig").SetUp;
const opt_flags = @import("types.zig").opt_flags;
const RuntimeError = @import("helpers.zig").RuntimeError;

pub extern "Kernel32" fn GetConsoleScreenBufferInfo(hConsoleOutput: win.HANDLE, lpConsoleScreenBufferInfo: *win.CONSOLE_SCREEN_BUFFER_INFO) callconv(win.WINAPI) win.BOOL;
pub extern "Kernel32" fn ReadConsoleOutputCharacterA(hConsoleOutput: win.HANDLE, lpCharacter: win.LPSTR, nLength: win.DWORD, dwReadCoord: win.COORD, lpNumberOfCharsRead: *win.DWORD) callconv(win.WINAPI) win.BOOL;

pub fn hexRead(args: SetUp, allocator: std.mem.Allocator, writer: anytype) !void {
    const input_switch: bool = if (std.mem.eql(u8, args.project_name, "")) true else false; //If true read from cmd screen buffer, if false proccess user submited data

    //Conditionally read data and copy to buffer(cmd output, or user input)
    var buffer = blk: {
        var mem: []u8 = undefined;
        if (input_switch) {
            const handle = try win.GetStdHandle(win.STD_OUTPUT_HANDLE);
            var buffer_info: win.CONSOLE_SCREEN_BUFFER_INFO = std.mem.zeroes(win.CONSOLE_SCREEN_BUFFER_INFO);
            _ = GetConsoleScreenBufferInfo(handle, &buffer_info);
            const columns = buffer_info.srWindow.Right - buffer_info.srWindow.Left;
            const rows = buffer_info.srWindow.Bottom - buffer_info.srWindow.Top;
            mem = try allocator.alloc(u8, @intCast(rows * columns));
            var chars_read: u32 = 0;
            _ = ReadConsoleOutputCharacterA(handle, @ptrCast(mem[0..]), @intCast(mem.len), .{ .X = 0, .Y = buffer_info.srWindow.Top }, &chars_read);
        } else {
            mem = try allocator.alloc(u8, args.project_name.len);
            @memcpy(mem, args.project_name);
        }
        break :blk mem;
    };
    defer allocator.free(buffer);

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

    //Based on selected options select and run the algorithm on the buffer
    var i: usize = 0;
    var j: usize = 0;
    switch (args.option) {
        .default => {
            //Byte wide scan algorithm (eg. 48 65 6c 6c 6f 20 57 6f 72 6c 64 21 20 54 68 69 73 20 69 73 20 6d 79 20 68 65 78 64 75 6d 70 20 72 65 61 64 65 72 20 74 6f 6f 6c 2e)
            while (i <= buffer.len - 1) : (i += 1) {
                const sep_left: bool = if (i == 0) true else sep.isSet(isLower128(buffer[i - 1]));
                const sep_right: bool = if (i + 2 >= buffer.len) true else sep.isSet(isLower128(buffer[i + 2]));
                if ((sep_left == true and sep_right == true) and std.ascii.isHex(buffer[i]) and std.ascii.isHex(buffer[i + 1])) {
                    const converted: u8 = (try asciiToInt(buffer[i]) << 4) | try asciiToInt(buffer[i + 1]);
                    if (input_switch) {
                        buffer[i] = ' ';
                        buffer[i + 1] = converted;
                    } else {
                        buffer[j] = converted;
                        j += 1;
                    }
                }
            }
            if (input_switch) {
                try writer.print("{s}\n", .{buffer[0..]});
            } else {
                try writer.print("{s}\n", .{buffer[0..j]});
            }
        },
        .word => {
            //Word wide scan alorithm (eg. 4865 6c6c 6f20 576f 726c 6421 2054 6869 7320 6973 206d 7920 6865 7864 756d 7020 7265 6164 6572 2074 6f6f 6c2e)
            var compress = try allocator.alloc(u8, buffer.len);
            defer allocator.free(compress);
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
        },
        .int => {
            //Integer conversion
            var str_buf = [_]u8{0} ** 3;
            var str_buf_cnt: u2 = 0;
            var int: u8 = 0;
            while (i < buffer.len) : (i += 1) {
                if (std.ascii.isDigit(buffer[i]) and str_buf_cnt < 3) {
                    str_buf[str_buf_cnt] = buffer[i];
                    str_buf_cnt += 1;
                } else if (std.ascii.isDigit(buffer[i])) {
                    continue;
                } else if (str_buf_cnt > 1 and str_buf_cnt < 4) {
                    if (input_switch) {
                        int = std.fmt.parseInt(u8, str_buf[0..str_buf_cnt], 10) catch {
                            str_buf_cnt = 0;
                            @memset(str_buf[0..], 0);
                            continue;
                        };
                        if (int > 31 and int < 127) { //Exclude control sequences and non ascii chars
                            buffer[i - 1] = int;

                            while (str_buf_cnt > 1) : (str_buf_cnt -= 1) {
                                buffer[i - str_buf_cnt] = ' ';
                            }
                            str_buf_cnt = 0;
                            @memset(str_buf[0..], 0);
                        }
                    } else {
                        buffer[j] = try std.fmt.parseInt(u8, str_buf[0..str_buf_cnt], 10);
                        j += 1;
                        @memset(str_buf[0..], 0);
                        str_buf_cnt = 0;
                    }
                } else {
                    @memset(str_buf[0..], 0);
                    str_buf_cnt = 0;
                }
            }
            if (input_switch) {
                try writer.print("{s}\n", .{buffer[0..]});
            } else {
                try writer.print("{s}\n", .{buffer[0..j]});
            }
        },
        else => {
            return RuntimeError.OptionError;
        },
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
