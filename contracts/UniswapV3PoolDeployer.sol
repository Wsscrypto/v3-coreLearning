// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IUniswapV3PoolDeployer.sol';

import './UniswapV3Pool.sol';

contract UniswapV3PoolDeployer is IUniswapV3PoolDeployer {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
    }

    /// @inheritdoc IUniswapV3PoolDeployer
    /// 直接用一个struct代替function做接口
    Parameters public override parameters; 

    /// @dev 用输入的参数部署pool，部署完删除参数
    /// @param factory 
    /// @param token0 
    /// @param token1 
    /// @param fee 
    /// @param tickSpacing 
    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) internal returns (address pool) {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
        //salt 用于预计算地址，详情可见：https://ethereum.stackexchange.com/questions/125555/what-does-keyword-salt-mean-in-solidity
        pool = address(new UniswapV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}());
        delete parameters;
    }
}
