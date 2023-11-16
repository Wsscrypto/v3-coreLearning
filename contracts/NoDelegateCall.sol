// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

/// @title 用于禁止对某合约功能进行委托调用
/// @notice 用于禁止对某合约功能进行委托调用
abstract contract NoDelegateCall {
    /// @dev 合约的原始部署地址，赋值后不可更改
    address private immutable original;

    constructor() {
        original = address(this);
    }

    /// @dev 要求调用函数的主体必须是合约自己
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice 禁止委托调用的修饰器
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}
