// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0 <0.8.0;

import './FullMath.sol';
import './FixedPoint128.sol';
import './LiquidityMath.sol';

/// @title 某个地址在某个区间的头寸：tickL 到 tickU 中间的区间
/// @notice Positions 代表 某个地址在某个区间的头寸：tickL 到 tickU 中间的区间
/// @dev Positions 也存放了这个区间拥有的swap费用收益
library Position {
    // Position 的信息
    struct Info {
        uint128 liquidity; // 在这个头寸拥有的流动性
        uint256 feeGrowthInside0LastX128; // 每单位流动性具有的费用收益
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;// 用token形式表示的费用收益
        uint128 tokensOwed1;
    }

    /// @notice 获取某个address的头寸信息
    /// @param self 存放所有用户头寸信息的数据
    /// @param owner 用户地址
    /// @param tickLower tickL
    /// @param tickUpper tickU
    /// @return position 用户拥有的相应头寸信息
    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (Position.Info storage position) {
        position = self[keccak256(abi.encodePacked(owner, tickLower, tickUpper))];
    }

    /// @notice 将累计费用计入用户头寸中；更新头寸的流动性和可取回代币，注意，该方法只会在mint和burn时被触发，swap并不会更新头寸信息。
    /// @param self 某个position info
    /// @param liquidityDelta 头寸更新导致的流动性变化
    /// @param feeGrowthInside0X128 每单位流动性新费率
    /// @param feeGrowthInside1X128 每单位流动性新费率
    function update(
        Info storage self,
        int128 liquidityDelta,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128
    ) internal {
        Info memory _self = self;

        // 计算新的流动性余额
        uint128 liquidityNext;
        if (liquidityDelta == 0) {
            require(_self.liquidity > 0, 'NP'); // disallow pokes for 0 liquidity positions
            liquidityNext = _self.liquidity;
        } else {
            liquidityNext = LiquidityMath.addDelta(_self.liquidity, liquidityDelta);
        }

        // 计算新费率下应该增加的流动性费用是多少
        uint128 tokensOwed0 =
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside0X128 - _self.feeGrowthInside0LastX128,
                    _self.liquidity,
                    FixedPoint128.Q128
                )
            );
        uint128 tokensOwed1 =
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside1X128 - _self.feeGrowthInside1LastX128,
                    _self.liquidity,
                    FixedPoint128.Q128
                )
            );

        // 更新流动性余额、费率、token费余额
        if (liquidityDelta != 0) self.liquidity = liquidityNext;
        self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
        self.feeGrowthInside1LastX128 = feeGrowthInside1X128;
        if (tokensOwed0 > 0 || tokensOwed1 > 0) {
            // 可能溢出，所以要定期取出流动性费用收益
            self.tokensOwed0 += tokensOwed0;
            self.tokensOwed1 += tokensOwed1;
        }
    }
}
