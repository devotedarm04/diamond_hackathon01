// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibDiamond} from "../libraries/LibDiamond.sol";

/// @notice This imports the `LibDiamond` library, which contains the tools (functions and data structures) to manage the diamond’s data and upgrades.
/// @dev `LibDiamond` is like a toolbox that helps the diamond keep track of its facets (tools), manage ownership, and handle upgrades. We need it to check the owner and perform the upgrade.

/// @title DiamondCutFacet
/// @notice This is a contract called `DiamondCutFacet` that lets the owner upgrade the diamond by adding new facets (tools) and functions.
/// @dev In the EIP-2535 Diamond Standard, a facet is a small contract that the diamond uses to do specific jobs. This facet is like the “upgrade manager” for the diamond—it controls how new tools are added.
contract DiamondCutFacet {
    /// @notice This function upgrades the diamond by adding new facets and functions, and optionally running a setup step.
    /// @dev This is the main function that lets the owner change the diamond, like adding new tools to a Swiss Army knife. Only the owner can call this function.
    /// @param _diamondCut A list of changes (FacetCut structs from `LibDiamond`) to make to the diamond, like adding new facets and functions.
    /// @param _init The address of a setup contract (initializer) to run after the changes, or `address(0)` if there’s no setup.
    /// @param _calldata The setup instructions to send to the initializer, or empty if there’s no setup.
    function diamondCut(
        LibDiamond.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external {
        /// @notice This checks that the person calling this function (`msg.sender`) is the owner of the diamond.
        /// @dev `msg.sender` is the address of whoever is calling the function (like the caller’s ID). `LibDiamond.contractOwner()` gets the diamond’s owner. If they don’t match, we stop and show an error.
        require(
            msg.sender == LibDiamond.contractOwner(),
            "DiamondCutFacet: Not owner"
        );

        /// @notice This calls the `diamondCut` function in `LibDiamond` to do the actual upgrade.
        /// @dev We’ve already checked that the caller is the owner, so now we let `LibDiamond` handle the upgrade. It will add the new facets and functions, and run the setup step if needed (using `_init` and `_calldata`).
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}
