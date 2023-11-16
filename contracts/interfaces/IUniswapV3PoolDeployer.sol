// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title 合约接口，实现这些接口，就能具备部署pool的功能
/// @dev 这用于避免在pool合约中包含构造函数参数，这让pool的初始化代码哈希保持不变，从而允许在链上廉价地计算pool的 CREATE2 地址
interface IUniswapV3PoolDeployer {
    /// @notice 获取构建pool时使用的参数，在pool创建期间临时设置。
    /// @dev 由pool构建者调用，用于获取pool相关参数
    /// Returns factory factory 地址
    /// Returns token0 
    /// Returns token1 
    /// Returns fee 
    /// Returns tickSpacing 
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing
        );
}
