// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0 <0.8.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './TickMath.sol';
import './LiquidityMath.sol';

/// @title Tick
/// @notice Tick 处理和相关的计算方法
library Tick {
    using LowGasSafeMath for int256;
    using SafeCast for int256;

    // 存储初始化后的某个 Tick 自己的信息
    struct Info {
        // 所有和本 Tick 相关的流动性，不单单是以本 Tick 为边界的头寸
        uint128 liquidityGross;
        // 以本 Tick 为边界的流动性，穿越这个 Tick 则会新增或减少流动性
        int128 liquidityNet;
        // 本 Tick 以外的流动性费用
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        // oracle 相关变量；用预言机的 tickCumulative 减去价格区间两边 tick 上的该变量，除以做市时长，就能得出该区间平均的做市价格（tick 序号）
        int56 tickCumulativeOutside;
        // oracle 相关变量； 用预言机的 secondsPerLiquidityCumulative 减去价格区间两边 tick 上的该变量，就是该区间内的每单位流动性的做市时长（使用该结果乘以你的流动性数量，得出你的流动性参与的做市时长，这个时长比上 1 的结果，就是你在该区间赚取的手续费比例）。
        uint160 secondsPerLiquidityOutsideX128;
        // oracle 相关变量；用池子创建以来的总时间减去价格区间两边 tick 上的该变量，就能得出该区间做市的总时长
        uint32 secondsOutside;
        // 是否初始化
        bool initialized;
    }

    /// @notice 指定 Tickspcing 下，每个 tick 的最大流动性
    /// @dev 在 pool 初始化时调用
    /// @param tickSpacing 
    /// @return 每个 tick 的最大流动性
    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns (uint128) {
        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
        return type(uint128).max / numTicks;
    }

    /// @notice 获取tickL 和 tickU 之间的 费用数据
    /// @param self 包含所有初始化的 tick 的 Info
    /// @param tickLower tickL 
    /// @param tickUpper tickU
    /// @param tickCurrent 现在价格所对应的 tick 位置
    /// @param feeGrowthGlobal0X128 token0的费用总数
    /// @param feeGrowthGlobal1X128 token1的费用总数
    /// @return feeGrowthInside0X128 流动性区间内，token0的费用
    /// @return feeGrowthInside1X128 流动性区间内，token1的费用
    function getFeeGrowthInside(
        mapping(int24 => Tick.Info) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        Info storage lower = self[tickLower];
        Info storage upper = self[tickUpper];

        // calculate fee growth below
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (tickCurrent >= tickLower) {
            feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
        } else {
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
        }

        // calculate fee growth above
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (tickCurrent < tickUpper) {
            feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
        } else {
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
    }

    /// @notice 更新 tick 信息，如果 tick 的初始化状态发生改变，则返回 true
    /// @param self 包含所有初始化的 tick 的 Info
    /// @param tick 将要更新信息的 tick
    /// @param tickCurrent 现在价格所对应的 tick
    /// @param liquidityDelta tick本次流动性变化量
    /// @param feeGrowthGlobal0X128 总的token0流动性费率
    /// @param feeGrowthGlobal1X128 总的token1流动性费率
    /// @param secondsPerLiquidityCumulativeX128 全局每个流动性的做市时间
    /// @param tickCumulative 全局tick时间累加值
    /// @param time 现在的区块时间戳
    /// @param upper 如果更新的是 tickU 则为 true，tickL 则为 false
    /// @param maxLiquidity 单个 tick 的最大流动性
    /// @return flipped 是否发送初始化状态的改变，是则返回 true
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {
        Tick.Info storage info = self[tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(liquidityGrossBefore, liquidityDelta);

        require(liquidityGrossAfter <= maxLiquidity, 'LO');

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= tickCurrent) {
                info.feeGrowthOutside0X128 = feeGrowthGlobal0X128;
                info.feeGrowthOutside1X128 = feeGrowthGlobal1X128;
                info.secondsPerLiquidityOutsideX128 = secondsPerLiquidityCumulativeX128;
                info.tickCumulativeOutside = tickCumulative;
                info.secondsOutside = time;
            }
            info.initialized = true;
        }

        info.liquidityGross = liquidityGrossAfter;

        // liquidityNet 代表穿越tick时产生的总体流动性变化量
        info.liquidityNet = upper
            ? int256(info.liquidityNet).sub(liquidityDelta).toInt128()
            : int256(info.liquidityNet).add(liquidityDelta).toInt128();
    }

    /// @notice 清空某个 tick 的初始化Info
    /// @param self 包含所有初始化的 tick 的 Info
    /// @param tick 要清空的 tick
    function clear(mapping(int24 => Tick.Info) storage self, int24 tick) internal {
        delete self[tick];
    }

    /// @notice 穿过下个 tick
    /// @param self 包含所有初始化的 tick 的 Info
    /// @param tick 要穿过的 tick
    /// @param feeGrowthGlobal0X128 token0总体费用
    /// @param feeGrowthGlobal1X128 token0总体费用
    /// @param secondsPerLiquidityCumulativeX128 The current seconds per liquidity
    /// @param tickCumulative The tick * time elapsed since the pool was first initialized
    /// @param time 现在的区块时间戳
    /// @return liquidityNet 流动性在这个 tick 的变化量
    function cross(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time
    ) internal returns (int128 liquidityNet) {
        Tick.Info storage info = self[tick];
        info.feeGrowthOutside0X128 = feeGrowthGlobal0X128 - info.feeGrowthOutside0X128;
        info.feeGrowthOutside1X128 = feeGrowthGlobal1X128 - info.feeGrowthOutside1X128;
        info.secondsPerLiquidityOutsideX128 = secondsPerLiquidityCumulativeX128 - info.secondsPerLiquidityOutsideX128;
        info.tickCumulativeOutside = tickCumulative - info.tickCumulativeOutside;
        info.secondsOutside = time - info.secondsOutside;
        liquidityNet = info.liquidityNet;
    }
}
