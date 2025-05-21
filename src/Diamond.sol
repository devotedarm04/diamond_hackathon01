// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @notice `LibDiamond` helps manage the diamond's internal data and logic.
import {LibDiamond} from "./libraries/LibDiamond.sol";

/// @notice This defines custom error called 'FunctionNotFound'.
/// @param _functionSelector This is 4-byte code that identifies which function was called but couldn't be found in the diamond.
error FunctionNotFound(bytes4 _functionSelector);

/// @notice This defines a structure called 'DiamondArgs' to hold 3 pieces of info needed when creating the diamond.
/// @dev We use struct to bundle together so we don’t have too many arguments in the constructor, which can cause errors in Solidity.
struct DiamondArgs {
    /// @notice This is address (like a unique ID) of the person who will own the diamond. The owner has special permissions, like upgrading the diamond.
    address owner;
    /// @notice This is address of a special contract (called an initializer) that sets up the diamond’s starting settings.
    address init;
    /// @notice The data (instructions) to send to the initializer contract, telling it what to do during setup.
    bytes initCalldata;
}

contract Diamond {
    /// @notice This is the constructor, a special function that runs only once when the diamond is created (deployed) on the blockchain.
    /// @param _diamondCut A list of instructions (FacetCut structs from LibDiamond) that tell the diamond which other contracts (facets) to connect to and which functions to use from them.
    /// @param _args A bundle of setup details (DiamondArgs) that includes the owner’s address, the initializer contract’s address, and the setup instructions for the initializer.
    /// @dev The `payable` keyword means this constructor can receive Ether (the cryptocurrency used on Ethereum) during deployment.
    constructor(
        LibDiamond.FacetCut[] memory _diamondCut,
        DiamondArgs memory _args
    ) payable {
        /// @notice This sets the owner of the diamond by calling a function in the LibDiamond library.
        LibDiamond.setContractOwner(_args.owner);
        /// @notice This connects the diamond to the facets listed in `_diamondCut` and runs the initializer if one is provided.
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);
    }

    /// @notice This is a special function called `fallback`. It runs whenever someone tries to call a function on the diamond that doesn’t exist directly in this contract.
    /// @dev The diamond uses this to “redirect” calls to other contracts (facets) that have the right function.
    fallback() external payable {
        /// @notice This creates a storage pointer to the diamond’s internal data, which is stored in a special structure defined in LibDiamond.
        /// @dev We need this to look up which facet (other contract) has the function being called.
        LibDiamond.DiamondStorage storage ds;
        /// @notice This gets the exact location (a unique slot) where the diamond’s data is stored in the blockchain’s memory.
        /// @dev `DIAMOND_STORAGE_POSITION` is a fixed code (hash) that ensures we always look in the right spot for the diamond’s data.
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // This uses low-level code (assembly) to connect our storage pointer `ds` to the correct location in memory.
        // Making `ds` point to the spot labeled `position`.
        assembly {
            ds.slot := position
        }
        /// @notice This looks up which facet (other contract) has the function being called by checking the function’s 4-byte code (called a selector).
        /// @dev `msg.sig` is the 4-byte code of the function being called (e.g., the fingerprint of the function). We look it up in the diamond’s data to find the facet’s address.
        address facet = ds
            .facetAddressAndSelectorPosition[msg.sig]
            .facetAddress;
        /// @notice This checks if we found a facet for the function. If not (i.e., the address is 0), something went wrong.
        /// @dev If no facet is found, it means the function doesn’t exist in the diamond, so we stop and show an error.
        if (facet == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        // This block uses low-level code (assembly) to “forward” the call to the facet we found.
        // We’re telling the blockchain to run the function on the facet contract instead of here, and then return the result to the caller.
        assembly {
            // This copies the data of the call (the function and its arguments) into the blockchain’s memory starting at position 0.
            // Its as if writing down the caller’s instructions so we can pass them to the facet.
            calldatacopy(0, 0, calldatasize())
            // This forwards the call to the facet using a special command called `delegatecall`.
            // `delegatecall` runs the facet’s code but uses the diamond’s storage, so it’s like the facet is working on the diamond’s data. We send all available gas (energy) to the facet.
            //  The `0, calldatasize(), 0, 0` parts tell the blockchain where to find the call data and that we’ll handle the result manually.
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            //  This copies the result (or error) from the facet back into memory starting at position 0.
            // After the facet runs, we need to grab whatever it returns (like an answer or an error message) so we can send it back to the caller.
            returndatacopy(0, 0, returndatasize())
            // This checks if the facet’s call was successful (`result` is 1) or failed (`result` is 0).
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @notice This is a special function called `receive`. It runs automatically if someone sends Ether (cryptocurrency) to the diamond without calling a specific function.
    receive() external payable {}
}
