// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IUniswapV3Factory.sol';

import './UniswapV3PoolDeployer.sol';
import './NoDelegateCall.sol';

import './UniswapV3Pool.sol';

/// @title uniswapV3 factory合约
/// @notice 用于部署uniswap pool 合约及控制费率
contract UniswapV3Factory is IUniswapV3Factory, UniswapV3PoolDeployer, NoDelegateCall {
    /// @inheritdoc IUniswapV3Factory
    address public override owner; //factory合约所有者

    /// @inheritdoc IUniswapV3Factory
    mapping(uint24 => int24) public override feeAmountTickSpacing;//fee 和 tickspacing 对
    /// @inheritdoc IUniswapV3Factory
    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;//用两个token地址及其费率获取pool合约地址

    constructor() {
        owner = msg.sender; //初始化factory合约所有者
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[500] = 10;//以下是初始化三个fee 和 tickspacing 对
        emit FeeAmountEnabled(500, 10);// 0.05%  10
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);// 0.3%  60
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);// 1%  200
    }

    /// @inheritdoc IUniswapV3Factory 创建 pool 的函数
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override noDelegateCall returns (address pool) {
        require(tokenA != tokenB); //要求 tokenA 和 tokenB 不能一样
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //tokenA和tokenB 排序，小的在前大的在后
        require(token0 != address(0));//两个token不能有 0 地址
        int24 tickSpacing = feeAmountTickSpacing[fee]; //获取当前费率的 tickspacing
        require(tickSpacing != 0);//需要 tickspacing 不能为0
        require(getPool[token0][token1][fee] == address(0));//本次创建的pool未被创建过
        pool = deploy(address(this), token0, token1, fee, tickSpacing); //部署pool合约
        getPool[token0][token1][fee] = pool;//记录pool合约
        getPool[token1][token0][fee] = pool;//两个方向都记录，可以免排序查询，减少gas费
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc IUniswapV3Factory 设置合约所有者
    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IUniswapV3Factory 设置新的 fee 和 tickspacing对
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner);//只允许 factory 合约所有者调用
        require(fee < 1000000);//费用小于100%
        require(tickSpacing > 0 && tickSpacing < 16384);// tickspacing 设置为小于16384避免数据溢出
        require(feeAmountTickSpacing[fee] == 0); //当前要添加的费率要之前没创建过的

        feeAmountTickSpacing[fee] = tickSpacing; //将费率加入factory中
        emit FeeAmountEnabled(fee, tickSpacing);
    }
}
