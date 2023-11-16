// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title 不可更改的pool状态变量
/// @notice 这些参数永远不会变
interface IUniswapV3PoolImmutables {
    /// @notice 部署这个pool的factory合约地址
    /// @return factory合约地址
    function factory() external view returns (address);

    /// @notice pool对中地址较小的合约token0
    /// @return token0地址
    function token0() external view returns (address);

    /// @notice pool对中地址较大的合约token1
    /// @return token1地址
    function token1() external view returns (address);

    /// @notice 费率，0.0001为基数
    /// @return 返回费率水平
    function fee() external view returns (uint24);

    /// @notice tickspacing
    /// @dev 最小为1的正数，如 tickspacing为3，则tick只能取3的倍数如 -6 -3 0 3 6 ......
    /// @return tickspacing
    function tickSpacing() external view returns (int24);

    /// @notice 价格位于任意tick时，可以使用的或可以填加的流动性的最大值
    /// @dev 避免数值溢出 uint128
    /// @return tick中流动性最大值
    function maxLiquidityPerTick() external view returns (uint128);
}
