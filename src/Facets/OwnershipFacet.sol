// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {LibDiamond} from "../libraries/LibDiamond.sol";

/// @notice This imports the `LibDiamond` library, which contains the tools (functions and data structures) to manage the diamond’s data, including ownership.
/// @dev `LibDiamond` is like a toolbox that holds the diamond’s records, like who the owner is. We need it to check and update the owner.

/// @title OwnershipFacet
/// @notice This is a contract called `OwnershipFacet` that lets you see who owns the diamond and allows the owner to transfer ownership to someone else.
/// @dev In the EIP-2535 Diamond Standard, a facet is a small contract that the diamond uses to do specific jobs. This facet is like the “admin controls” for the diamond—it manages who has the power to make big changes, like upgrading the diamond.
contract OwnershipFacet {
    /// @notice This function returns the address (unique ID) of the diamond’s current owner.
    /// @dev This is like asking, “Who’s in charge of this Swiss Army knife?” It’s “view” because it only reads data, not changes anything.
    /// @return The address of the current owner.
    function owner() external view returns (address) {
        /// @notice This calls a function in `LibDiamond` to get the owner’s address from the diamond’s records.
        /// @dev `LibDiamond.contractOwner()` looks in the diamond’s filing cabinet (its storage) and tells us who the owner is.
        return LibDiamond.contractOwner();
    }

    /// @notice This function lets the current owner transfer ownership of the diamond to a new address.
    /// @dev This is like the admin of the Swiss Army knife giving control to someone else. Only the current owner can do this.
    /// @param _newOwner The address (unique ID) of the new owner who will take control of the diamond.
    function transferOwnership(address _newOwner) external {
        /// @notice This checks that the person calling this function (`msg.sender`) is the current owner of the diamond.
        /// @dev `msg.sender` is the address of whoever is calling the function (like the caller’s ID). `LibDiamond.contractOwner()` gets the diamond’s owner. If they don’t match, we stop and show an error.
        require(
            msg.sender == LibDiamond.contractOwner(),
            "OwnershipFacet: Not owner"
        );

        /// @notice This calls a function in `LibDiamond` to update the owner to the new address.
        /// @dev `LibDiamond.setContractOwner` updates the diamond’s records to set the new owner and sends out a message (event) to let everyone know the owner changed.
        LibDiamond.setContractOwner(_newOwner);
    }
}
