//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("base64_lib");

pub fn main() !void {}

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
    pub fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }
};

// Calculate the length of the encoded output
// 每3个字节编码为4个字符 ceil((input_len + 2) / 3) * 4）
fn _calc_encode_length(input: []const u8) !usize {
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
