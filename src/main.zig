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
// 每3个字节编码为4个字符 ceil(input_len / 3) * 4）
fn _calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }
    // 除以3向上取整
    // 每3个字节编码为4个字符
    const n_groups: usize = try std.math.divCeil(usize, input.len, 3);
    return n_groups * 4;
}

test "use base64 table" {
    const base64 = Base64.init();
    try std.testing.expectEqual('c', base64._char_at(28));
}

test "calculate encoded length" {
    const input = "hello";
    const encoded_len = try _calc_encode_length(input);
    try std.testing.expectEqual(8, encoded_len);
}
