const std = @import("std");
const win = std.os.windows;

//Flags for selecting options
pub const opt_flags = enum { initlib, initexe, init, time, default, iter, quiet, dir, h, i, q, hex, word, int };

//Data struct
pub const SetUp = struct {
    module_name: opt_flags = .default,
    option: opt_flags = .default,
    dir_path: []const u8 = undefined,
    project_name: []const u8 = "",
    utf16: []u16 = undefined,
    iter: usize = 1,
    quiet: opt_flags = .default,
};

pub const Benchmark = struct {
    freq: f64 = undefined,
    result: u64 = undefined,
    start: u64 = undefined,
    end: u64 = undefined,
    accumulator: u64 = 0,
    worst: usize = 0,
    best: usize = 0xFFFFFFFFFFFFFFFF,
    peak_mem: usize = 0,
    counter: usize = 0,

    pub fn startTimer(self: *Benchmark) void {
        self.start = win.QueryPerformanceCounter();
    }

    pub fn endTimer(self: *Benchmark) void {
        self.end = win.QueryPerformanceCounter();
        self.result = self.end - self.start;
        self.accumulator += self.result;
        if (self.result < self.best) self.best = self.result;
        if (self.result > self.worst) self.worst = self.result;
        self.counter += 1;
    }

    pub fn storeIfMaxMem(self: *Benchmark, mem: usize) void {
        if (self.peak_mem < mem) self.peak_mem = mem;
    }

    pub fn getResult(self: *Benchmark) f64 {
        return (@as(f64, @floatFromInt(self.result)) / self.freq);
    }

    pub fn getBest(self: *Benchmark) f64 {
        return (@as(f64, @floatFromInt(self.best)) / self.freq);
    }

    pub fn getWorst(self: *Benchmark) f64 {
        return (@as(f64, @floatFromInt(self.worst)) / self.freq);
    }

    pub fn getAverage(self: *Benchmark) f64 {
        return ((@as(f64, @floatFromInt(self.accumulator)) / @as(f64, @floatFromInt(self.counter))) / self.freq);
    }
};
