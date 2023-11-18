// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './BitMath.sol';

/// @title Packed tick initialized state library
/// @notice 存放tick与其对应的初始化信息
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice 计算某个 tick 在bitmap中的数据存储位置
    /// @param tick 需要计算的tick
    /// @return wordPos 存储 word 的位置
    /// @return bitPos 存储 bit 的位置
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(tick % 256);
    }

    /// @notice 翻转初始化状态：初始化与未初始化
    /// @param self 要翻转标志所在的数据
    /// @param tick 
    /// @param tickSpacing 
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        require(tick % tickSpacing == 0); // tick 能被 tickspacing 整除
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos; // 1* 2** bitpos
        self[wordPos] ^= mask;
    }

    /// @notice 返回下一个初始化的 tick ，先从同一个 word 中寻找，没有再找其他 word
    /// @param self 存在下个 tick 的数据
    /// @param tick 从这个 tick 开始找
    /// @param tickSpacing 
    /// @param lte 从左边开始找
    /// @return next 如果存在已初始化的tick，则需要定位到masked中最高位的1；如果不存在，则返回当前方向最后一个tick
    /// @return initialized 是否返回的 next 是初始化过的
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing; //取 tick / tickspacing 后的值

        if (tick < 0 && tick % tickSpacing != 0) compressed--; //开始的 tick 可能不是合法的，向负无穷的方向舍入

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos); //把小于等于 bitpos 的位全部置为1
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
                : (compressed - int24(bitPos)) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing
                : (compressed + 1 + int24(type(uint8).max - bitPos)) * tickSpacing;
        }
    }
}
