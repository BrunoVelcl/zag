const std = @import("std");
const tb = @import("ToolBox.zig");
const str = @import("strData.zig");
const win = std.os.windows;
const Benchmark = @import("types.zig").Benchmark;
const SetUp = @import("types.zig").SetUp;
const opt_flags = @import("types.zig").opt_flags;
pub extern "kernel32" fn SetConsoleMode(Handle: win.HANDLE, Mode: win.DWORD) callconv(win.WINAPI) win.BOOL;
pub extern "kernel32" fn GetConsoleMode(Handle: win.HANDLE, lpMode: *win.DWORD) callconv(win.WINAPI) win.BOOL;

pub fn timer(args: SetUp, writer: anytype) !void {
    //Create a struct for recording data
    var data = Benchmark{};
    data.freq = @floatFromInt(win.QueryPerformanceFrequency());
    //StartupInfo
    var start_up_info: win.STARTUPINFOW = std.mem.zeroes(win.STARTUPINFOW);
    start_up_info.cb = @sizeOf(win.STARTUPINFOW);
    start_up_info.dwFlags = win.STARTF_USESHOWWINDOW;
    start_up_info.wShowWindow = 0;
    //ProccessInfo
    var process_info: win.PROCESS_INFORMATION = std.mem.zeroes(win.PROCESS_INFORMATION);
    //Set window to show or hide
    const creation_flags: u32 = if (args.quiet == .default) 0 else 0x00000010;

    //ProgresBar setup*******************************************
    const max: f64 = @floatFromInt(args.iter);
    var acc: f64 = 0;
    const one_whole: f64 = 100;
    var step: f64 = undefined;
    var row_cnt: f64 = 1;

    var progressB = ProggressBar{};
    if (args.quiet == .q and args.iter > 1) {
        try progressB.init(writer);
        //try writer.print("0% ---------------------------------------------------------------------------------------------------- 100%\r", .{});
        //try writer.print("\x1b[105D", .{});
        if (max < one_whole) {
            step = max / one_whole;
        } else {
            step = one_whole / max;
            row_cnt = 0;
        }
    }

    //*******************************************

    //Main Loop
    var i: u64 = 0;
    while (i < args.iter) : (i += 1) {
        //Zero proccessinfo on every iteration
        process_info = std.mem.zeroes(win.PROCESS_INFORMATION);
        //Child Program timing and execution*********
        data.startTimer();
        try std.os.windows.CreateProcessW(null, @ptrCast(args.utf16), null, null, 0, creation_flags, null, null, &start_up_info, &process_info);
        try win.WaitForSingleObject(process_info.hProcess, win.INFINITE);
        data.endTimer();
        //*******************************************
        const memory_info = try win.GetProcessMemoryInfo(process_info.hProcess);
        data.storeIfMaxMem(memory_info.PeakWorkingSetSize);
        //Progressbar update*******************************************
        if (args.quiet == .q and args.iter > 1) {
            if (max >= one_whole and acc >= row_cnt) {
                try progressB.update(writer);
                acc += step;
                row_cnt += 1;
            } else if (max >= one_whole) {
                acc += step;
            } else if (max < one_whole) {
                while (acc < row_cnt) : (acc += step) {
                    try progressB.update(writer);
                }
                row_cnt += 1;
            }
        }
        //*******************************************

    }
    try progressB.deinit(writer);
    try BenchmarkParser(&data, writer);
}

pub fn BenchmarkParser(bench_data: *Benchmark, writer: anytype) !void {
    const avg_flag = timeConverter(bench_data.getAverage());

    const time_index: []const u8 = switch (avg_flag.flag) {
        0 => "ms",
        1 => "sec",
        2 => "min",
        else => unreachable,
    };

    if (bench_data.counter == 1) {
        try writer.print("Result: {d:0>.3} {s}  ||  MaxMemoryUsage: {d:0>.3} MB\n\n", .{ avg_flag.time, time_index, bytesToMB(bench_data.peak_mem) });
    } else {
        try writer.print("Avg: {d:0>.3} {s}  ||  Best: {d:0>.3} {s} ||  Worst: {d:0>.3} {s}  ||  MaxMemoryUsage: {d:0>.3} MB\n\n", .{ avg_flag.time, time_index, timeConverter(bench_data.getBest()).time, time_index, timeConverter(bench_data.getWorst()).time, time_index, bytesToMB(bench_data.peak_mem) });
    }
}

pub fn timeConverter(time: f64) struct { time: f64, flag: u2 } {
    const ms_conv: f64 = 1000;
    const mn_conv: f64 = 60;
    if (time < 1) {
        return .{ .time = time * ms_conv, .flag = 0b00 };
    } else if (time > mn_conv) {
        return .{ .time = time / mn_conv, .flag = 0b01 };
    } else return .{ .time = time, .flag = 0b10 };
}

pub fn bytesToMB(bytes: usize) f64 {
    return @as(f64, @floatFromInt(bytes)) / 1048576;
}

pub const ProggressBar = struct {
    base: []const u8 = "Testing: 0%   ---------------------------------------------------------------------------------------------------   100%",
    offset: u8 = 13,
    handle: *anyopaque = undefined,
    live: u1 = 0,

    pub fn init(self: *ProggressBar, writer: anytype) !void {
        self.handle = try win.GetStdHandle(win.STD_OUTPUT_HANDLE);
        var mode: win.DWORD = 0;
        _ = GetConsoleMode(self.handle, &mode);
        _ = SetConsoleMode(self.handle, mode | win.ENABLE_VIRTUAL_TERMINAL_PROCESSING);
        try writer.print("\x1b[?25l", .{}); //Hides cursor
        try writer.print("{s}", .{self.base});
        try writer.print("\x1b[{d}D", .{self.base.len - self.offset});
        _ = try win.SetConsoleTextAttribute(self.handle, win.FOREGROUND_GREEN);
        self.live = 1;
    }

    pub fn update(self: ProggressBar, writer: anytype) !void {
        _ = self;
        try writer.print(">", .{});
    }

    pub fn deinit(self: ProggressBar, writer: anytype) !void {
        if (self.live == 0) return;
        try writer.print("\x1b[2K\x1b[{d}DTESTING COMPLETE\n", .{self.base.len / 2 + 8});
        _ = try win.SetConsoleTextAttribute(self.handle, win.FOREGROUND_BLUE | win.FOREGROUND_GREEN | win.FOREGROUND_RED);
        try writer.print("\x1b[?25h\r", .{});
    }
};
