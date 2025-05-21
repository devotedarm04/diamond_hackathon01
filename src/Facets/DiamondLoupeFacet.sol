// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibDiamond} from "../libraries/LibDiamond.sol";

/// @notice This imports the `LibDiamond` library, which contains the tools (functions and data structures) to manage the diamond’s data.
/// @dev `LibDiamond` is like a toolbox that holds the diamond’s records, like a list of all its functions and which facets (tools) they belong to. We need it to inspect the diamond’s setup.

/// @title DiamondLoupeFacet
/// @notice This is a contract called `DiamondLoupeFacet` that lets anyone see which facets (tools) and functions the diamond has.
/// @dev In the EIP-2535 Diamond Standard, a facet is a small contract that the diamond uses to do specific jobs. This facet is like a magnifying glass (a “loupe”) that lets you inspect the diamond to see what tools it has and where they are.
contract DiamondLoupeFacet {
    /// @notice This defines a structure (like a blueprint) called `Facet` to hold information about a facet and its functions.
    /// @dev We use this structure to organize the information we’ll return, like a report card that says, “This facet has these functions.”
    struct Facet {
        /// @notice This is the address (like a unique ID) of the facet contract.
        address facetAddress;
        /// @notice This is a list (array) of function selectors (4-byte codes) that this facet has.
        /// @dev Each function in a facet has a unique 4-byte code, like a phone number for the function.
        bytes4[] functionSelectors;
    }

    /// @notice This function returns a list of all facets and their functions in the diamond.
    /// @dev This is the main function of the loupe—it’s like looking through a magnifying glass to see what tools the Swiss Army knife has. It’s “view” because it only reads data, not changes anything.
    /// @return facets_ A list (array) of `Facet` structures, where each one describes a facet and its functions.
    function facets() external view returns (Facet[] memory facets_) {
        /// @notice This gets access to the diamond’s data (its filing cabinet) using `LibDiamond`.
        /// @dev `diamondStorage` gives us a pointer to the diamond’s records, where we can see all its functions and which facets they belong to.
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        /// @notice This creates a list (array) to hold the facets we find, with enough space for all the functions in the diamond.
        /// @dev We start by making a list as big as the total number of functions (`ds.selectors.length`), but we’ll shrink it later because some functions belong to the same facet.
        facets_ = new Facet[](ds.selectors.length);

        /// @notice This keeps track of how many unique facets we’ve found as we go through the list.
        /// @dev We’ll use this to know where to put the next facet in the `facets_` list.
        uint256 facetIndex;

        /// @notice This loops through each function selector (4-byte code) in the diamond’s list of functions.
        /// @dev We go through every function the diamond knows about to see which facet it belongs to.
        for (
            uint256 selectorIndex;
            selectorIndex < ds.selectors.length;
            selectorIndex++
        ) {
            /// @notice This gets the current function selector we’re looking at.
            bytes4 selector = ds.selectors[selectorIndex];

            /// @notice This looks up which facet has this function by checking the diamond’s records.
            /// @dev `facetAddressAndSelectorPosition` is a mapping in `LibDiamond` that tells us which facet (address) has this function.
            address facetAddress = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;

            /// @notice This checks if we’ve found a new facet (either it’s the first function, or the facet address is different from the last one we saw).
            /// @dev If this function belongs to a new facet, we need to start a new entry in our `facets_` list.
            if (
                selectorIndex == 0 ||
                facets_[facetIndex].facetAddress != facetAddress
            ) {
                /// @notice If this isn’t the first function (selectorIndex != 0), we move to the next spot in our list because we’ve found a new facet.
                /// @dev We don’t increment `facetIndex` for the first function (selectorIndex == 0) because we’re already at the first spot (0).
                if (selectorIndex != 0) facetIndex++;

                /// @notice This sets the address of the new facet in our list.
                facets_[facetIndex].facetAddress = facetAddress;
            }

            /// @notice This counts how many functions this facet has by looking at all the selectors in the diamond.
            /// @dev We need to know how many functions this facet has so we can make a list of the right size to store them.
            uint256 selectorCount = 0;

            /// @notice This loops through all the selectors in the diamond again to count how many belong to this facet.
            for (uint256 i; i < ds.selectors.length; i++) {
                /// @notice This checks if the current selector (at position `i`) belongs to the same facet we’re looking at.
                if (
                    ds
                        .facetAddressAndSelectorPosition[ds.selectors[i]]
                        .facetAddress == facetAddress
                ) {
                    /// @notice If this selector belongs to the facet, we increase the count.
                    selectorCount++;
                }
            }

            /// @notice This creates a list to hold all the function selectors for this facet, with the right size based on the count we just found.
            facets_[facetIndex].functionSelectors = new bytes4[](selectorCount);

            /// @notice This keeps track of where we are in the list of selectors for this facet as we add them.
            uint256 selectorPosition = 0;

            /// @notice This loops through all the selectors in the diamond again to add the ones that belong to this facet to our list.
            for (uint256 i; i < ds.selectors.length; i++) {
                /// @notice This checks if the current selector (at position `i`) belongs to the same facet.
                if (
                    ds
                        .facetAddressAndSelectorPosition[ds.selectors[i]]
                        .facetAddress == facetAddress
                ) {
                    /// @notice This adds the selector to the facet’s list of functions at the current position.
                    facets_[facetIndex].functionSelectors[selectorPosition] = ds
                        .selectors[i];

                    /// @notice This moves to the next position in the list so we can add the next selector.
                    selectorPosition++;
                }
            }
        }

        // @notice This uses low-level code (assembly) to set the final size of our `facets_` list.
        // @dev When we created `facets_`, we made it as big as the total number of selectors, but we only used some of those spots (one for each unique facet). We use `mstore` to set the correct length (`facetIndex + 1`, because `facetIndex` starts at 0).
        assembly {
            mstore(facets_, add(facetIndex, 1))
        }
    }
}
