//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("base64_lib");

pub fn main() !void {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, World!\n", .{});

    const base64 = Base64.init();

    const input = "Hello, Zig!";
    const encoded = try base64.encode(allocator, input);
    defer allocator.free(encoded);
    try stdout.print("Encoded: {s}\n", .{encoded});
}

const Base64 = struct {
    // Base64 encoding table
    _table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symb = "0123456789+/";
        return Base64{
            ._table = upper ++ lower ++ numbers_symb,
        };
    }

    // Get character at index from Base64 table
    fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }

    fn _char_index(self: Base64, char: u8) u8 {
        if (char == '=')
            return 64;
        var index: u8 = 0;
        for (0..63) |i| {
            if (self._char_at(i) == char)
                break;
            index += 1;
        }

        return index;
    }

    // Encode input bytes to Base64 string
    pub fn encode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const n_out = try _calc_encode_length(input);
        var out = try allocator.alloc(u8, n_out);
        var buf = [3]u8{ 0, 0, 0 };
        var count: u8 = 0;
        var iout: u64 = 0;

        for (input, 0..) |_, i| {
            buf[count] = input[i];
            count += 1;
            if (count == 3) {
                out[iout] = self._char_at(buf[0] >> 2);
                out[iout + 1] = self._char_at(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
                out[iout + 2] = self._char_at(((buf[1] & 0x0f) << 2) + (buf[2] >> 6));
                out[iout + 3] = self._char_at(buf[2] & 0x3f);
                iout += 4;
                count = 0;
            }
        }

        if (count == 1) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at((buf[0] & 0x03) << 4);
            out[iout + 2] = '=';
            out[iout + 3] = '=';
        }

        if (count == 2) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
            out[iout + 2] = self._char_at((buf[1] & 0x0f) << 2);
            out[iout + 3] = '=';
            iout += 4;
        }

        return out;
    }

    // Decode Base64 string to bytes
    pub fn decode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }
        const n_output = try _calc_decode_length(input);
        var output = try allocator.alloc(u8, n_output);
        var count: u8 = 0;
        var iout: u64 = 0;
        var buf = [4]u8{ 0, 0, 0, 0 };

        for (0..input.len) |i| {
            buf[count] = self._char_at(input[i]);
            count += 1;
            if (count == 4) {
                output[iout] = (buf[0] << 2) + (buf[1] >> 4);
                if (buf[2] != 64) {
                    output[iout + 1] = (buf[1] << 4) + (buf[2] >> 2);
                }
                if (buf[3] != 64) {
                    output[iout + 2] = (buf[2] << 6) + buf[3];
                }
                iout += 3;
                count = 0;
            }
        }

        return output;
    }
};

// Calculate the length of the encoded output
// 每3个字节编码为4个字符 ceil((input_len + 2) / 3) * 4）
fn _calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }
    // 除以3向上取整
    // 每3个字节编码为4个字符
    const n_groups: usize = try std.math.divCeil(usize, input.len, 3);
    return n_groups * 4;
}

// Calculate the length of the decoded output
// 每4个字符解码为3个字节
// ceil(input_len / 4) * 3 - padding_count
fn _calc_decode_length(input: []const u8) !usize {
    if (input.len < 4) {
        return 3;
    }
    // 除以4向下取整
    // 每4个字符解码为3个字节
    // '='填充不计入解码长度
    const n_groups: usize = try std.math.divFloor(usize, input.len, 4);
    var multiple_groups: usize = n_groups * 3;
    var i: usize = input.len - 1;
    while (i > 0) : (i -= 1) {
        if (input[i] == '=') {
            multiple_groups -= 1;
        } else {
            break;
        }
    }

    return multiple_groups;
}

test "use base64 table" {
    const base64 = Base64.init();
    try std.testing.expectEqual('c', base64._char_at(28));
    try std.testing.expectEqual('T', base64._char_at(19));
    try std.testing.expectEqual('W', base64._char_at(22));
    try std.testing.expectEqual('F', base64._char_at(5));
    try std.testing.expectEqual('u', base64._char_at(46));
}

test "calculate encoded length" {
    const input = "Man";
    const encoded_len = try _calc_encode_length(input);
    try std.testing.expectEqual(4, encoded_len);
}

test "calculate decoded length" {
    const input = "TWFu";
    const decoded_len = try _calc_decode_length(input);
    try std.testing.expectEqual(3, decoded_len);
}

test "test bit move" {
    const input = "Hi";
    // 'H' = 72 = 01001000
    // 'i' = 105 = 01101001
    // 01001000 >> 2 = 00010010 = 18
    try std.testing.expectEqual(18, input[0] >> 2);
}

test "test base64 encode" {
    const input = "Man";
    const allocator = std.testing.allocator;
    const base64 = Base64.init();
    const encoded = try base64.encode(allocator, input);
    defer allocator.free(encoded);
    try std.testing.expectEqualSlices(u8, "TWFu", encoded);
}

test "test base64 decode" {
    const input = "TWFu";
    const allocator = std.testing.allocator;
    const base64 = Base64.init();
    const decoded = try base64.decode(allocator, input);
    defer allocator.free(decoded);
    try std.testing.expectEqualSlices(u8, "Man", decoded);
}

test "test base64 encode with padding" {
    const input = "Ma";
    const allocator = std.testing.allocator;
    const base64 = Base64.init();
    const encoded = try base64.encode(allocator, input);
    defer allocator.free(encoded);
    try std.testing.expectEqualSlices(u8, "TWE=", encoded);
}

test "test base64 decode with padding" {
    const input = "TWE=";
    const allocator = std.testing.allocator;
    const base64 = Base64.init();
    const decoded = try base64.decode(allocator, input);
    defer allocator.free(decoded);
    try std.testing.expectEqualSlices(u8, "Ma", decoded);
}

test "test base64 encode with single char" {
    const input = "M";
    const allocator = std.testing.allocator;
    const base64 = Base64.init();
    const encoded = try base64.encode(allocator, input);
    defer allocator.free(encoded);
    try std.testing.expectEqualSlices(u8, "TQ==", encoded);
}

test "test base64 decode with single char" {
    const input = "TQ==";
    const allocator = std.testing.allocator;
    const base64 = Base64.init();
    const decoded = try base64.decode(allocator, input);
    defer allocator.free(decoded);
    try std.testing.expectEqualSlices(u8, "M", decoded);
}
