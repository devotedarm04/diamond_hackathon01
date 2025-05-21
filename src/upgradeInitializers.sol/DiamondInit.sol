// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title DiamondInit
/// @notice This is a contract called `DiamondInit` that helps set up the diamond when it’s first created or upgraded.
/// @dev Think of this contract as a setup wizard that runs once to get the diamond ready. In the EIP-2535 Diamond Standard, an initializer like this is used to set starting values or conditions for the diamond.
contract DiamondInit {
    /// @notice This is a function called `init` that runs when the diamond is created or upgraded.
    /// @dev The `external` keyword means this function can only be called from outside the contract (like by the diamond). In the diamond pattern, the diamond calls this function using a special method called `delegatecall`, which lets `DiamondInit` set up the diamond’s data.
    function init() external {
        /// @dev In a basic implementation, we leave this empty to keep things simple. In a more advanced version, this function might set up things like initial settings, roles, or data for the diamond. For example, it could set a starting value, like “the diamond starts with 100 points,” or configure who can use it.
        // Empty for basic implementation
    }
}
