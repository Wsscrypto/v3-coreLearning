// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title 需授权的操作
/// @notice 可能只有pool所有者可以执行的操作
interface IUniswapV3PoolOwnerActions {
    /// @notice 协议收费占swap中的百分比
    /// @param feeProtocol0 token0的协议费百分比
    /// @param feeProtocol1 token1的协议费百分比
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice 收取pool中的协议费用
    /// @param recipient 协议费用接收地址
    /// @param amount0Requested 需要收取多少token0，可以为0则只收token1，也可以为一个很大的值然后收取所有可收的费用
    /// @param amount1Requested 同上，收取token1协议费用
    /// @return amount0 实际收取的token0数量
    /// @return amount1 实际收取的token1数量
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}
