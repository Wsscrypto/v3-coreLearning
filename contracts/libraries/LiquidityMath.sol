// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title 流动性计算函数
library LiquidityMath {
    /// @notice 加一个流动性变化量上去，有符号的，可能为负数；不允许数值溢出
    /// @param x 加法前的流动性
    /// @param y 把这个值加到x上去
    /// @return z 加法返回值
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
}
