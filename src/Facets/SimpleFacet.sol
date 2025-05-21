// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title SimpleFacet
/// @notice This is a contract called `SimpleFacet` that provides two simple functions to demonstrate how facets work in the diamond pattern.
/// @dev In the EIP-2535 Diamond Standard, a facet is a small contract that the diamond uses to do specific jobs. This facet is like a practice tool—it has two functions (`sayHello` and `sayHelloUpgraded`) that we use to test adding and upgrading facets in the diamond.
contract SimpleFacet {
    /// @notice This function returns a simple greeting message to show that the facet is working.
    /// @dev This is a basic function that doesn’t read or change anything on the blockchain—it just returns a message. It’s “pure” because it doesn’t touch the blockchain at all.
    /// @return A string message saying "Hello from SimpleFacet!".
    function sayHello() external pure returns (string memory) {
        /// @notice This returns the greeting message as a string.
        /// @dev The `string memory` part means we’re creating a temporary string that lives in memory (not saved on the blockchain). This is a simple way to test that the facet works when added to the diamond.
        return "Hello from SimpleFacet!";
    }

    /// @notice This function returns an upgraded greeting message to show that the facet can be upgraded with new functionality.
    /// @dev This is similar to `sayHello`, but it’s a new function we add later to test the diamond’s upgrade process. It’s also “pure” because it doesn’t touch the blockchain.
    /// @return A string message saying "Hello from Upgraded SimpleFacet!".
    function sayHelloUpgraded() external pure returns (string memory) {
        /// @notice This returns the upgraded greeting message as a string.
        /// @dev This function is used to test that the diamond can add new functions to an existing facet without breaking the old ones (like `sayHello`).
        return "Hello from Upgraded SimpleFacet!";
    }
}
