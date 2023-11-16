// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Uniswap V3 Factory 合约接口文件
/// @notice 用于创建pool，并设置费用
interface IUniswapV3Factory {
    /// @notice 当Factory的所有者变更时，发出此事件提示
    /// @param oldOwner 变更前地址
    /// @param newOwner 变更后地址
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Factory创建Pool的时候，发出此事件提示
    /// @param token0 经过排序后的 token0
    /// @param token1 经过排序后的 token1
    /// @param fee 每次swap都要收的费用，基数是 0.0001 即万分之一，若收0.3%费用，则这里为3000
    /// @param tickSpacing 两个tick之间的最小间隔
    /// @param pool pool部署地址
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice 当允许设置新的费用类型时，发出此事件提示
    /// @param fee 费用，基数是 0.0001
    /// @param tickSpacing 两个tick之间的最小间隔
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice 返回当前Factory的所有者
    /// @dev 更换Factory所有者
    /// @return 所有者地址
    function owner() external view returns (address);

    /// @notice 返回某个费用下，tickspacing大小，如果为0，说明给的fee参数是不合法的
    /// @dev 费用和tickspacing值是不能改变的
    /// @param 费用
    /// @return tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice 返回 两个token在某个费率下的 pool 地址
    /// @dev tokenA 和 B 可能是未经排序的，排序后一般标记为 token0 和 token1
    /// @param tokenA 
    /// @param tokenB
    /// @param 费用
    /// @return pool 地址
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice 为 tokenA tokenB 在 fee 费率下创建一个 pool
    /// @param tokenA
    /// @param tokenB
    /// @param fee
    /// @dev tokenA 和 tokenB 未经排序
    /// @return 新创建的pool地址
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice 更新Factory的所有者
    /// @dev 必须由当前所有者调用
    /// @param _owner 新的所有者地址
    function setOwner(address _owner) external;

    /// @notice 设置新的 fee 和 tickspacing 对
    /// @dev 一旦设置新的费率，则无法删除
    /// @param fee
    /// @param tickSpacing 
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}
