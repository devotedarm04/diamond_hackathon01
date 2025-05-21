// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title LibDiamond
/// @notice This is a library called `LibDiamond` that provides the core tools (functions and data structures) to manage the diamond’s internal data and upgrades.
/// @dev A library in Solidity is like a toolbox with reusable functions that other contracts (like the diamond) can use. This library helps the diamond keep track of its facets (tools), manage ownership, and handle upgrades, following the EIP-2535 Diamond Standard.
library LibDiamond {
    /// @notice This creates a unique code (called a storage slot) to store the diamond’s data in a specific spot on the blockchain.
    /// @dev `keccak256` creates a unique code (hash) from the string "diamond.standard.diamond.storage". We use this code to make sure the diamond’s data is always stored in the same spot, so all parts of the diamond can find it.
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    /// @notice This defines a structure (like a blueprint) called `FacetAddressAndSelectorPosition` to store two pieces of information about a function in the diamond.
    /// @dev We use this structure to keep track of which facet (tool) has a specific function and where that function is listed in the diamond’s records.
    struct FacetAddressAndSelectorPosition {
        /// @notice This is the address (like a unique ID) of the facet contract that has the function.
        address facetAddress;
        /// @notice This is a number that tells us where the function’s 4-byte code (selector) is stored in a list of all the diamond’s functions.
        /// @dev `uint16` is a small number (0 to 65,535), which is enough because a diamond won’t have that many functions.
        uint16 selectorPosition;
    }

    /// @notice This defines a structure called `DiamondStorage` to hold all the important data for the diamond.
    /// @dev Think of this as a filing cabinet where the diamond keeps its records: which functions it has, where they are, and who owns the diamond.
    struct DiamondStorage {
        /// @notice This is a mapping (like a lookup table) that connects a function’s 4-byte code (selector) to its details: the facet address and its position in the list of functions.
        /// @dev For each function, we can look up where it lives (which facet) and where it’s listed in the diamond’s records.
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        /// @notice This is a list (array) of all the function selectors (4-byte codes) that the diamond knows about.
        /// @dev We keep this list so we can keep track of all the functions the diamond can use, in the order they were added.
        bytes4[] selectors;
        /// @notice This is the address (unique ID) of the person who owns the diamond. The owner has special permissions, like upgrading the diamond.
        address contractOwner;
    }

    /// @notice This defines an event called `OwnershipTransferred` that the diamond sends out when the owner changes.
    /// @dev An event is like a message that the blockchain records to let everyone know something happened. `indexed` means we can search for the old and new owner easily.
    /// @param previousOwner The address of the old owner (before the change).
    /// @param newOwner The address of the new owner (after the change).
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice This defines an event called `DiamondCut` that the diamond sends out when it gets upgraded (like adding or changing facets).
    /// @dev This event tells everyone what changes were made to the diamond, like adding new functions.
    /// @param _diamondCut A list of changes (FacetCut structs) made to the diamond, like which facets and functions were added.
    /// @param _init The address of a setup contract (initializer) that ran after the upgrade, or `address(0)` if there was no setup.
    /// @param _calldata The setup instructions sent to the initializer, or empty if there was no setup.
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice This defines a structure called `FacetCut` to describe a change (like adding a facet) to the diamond during an upgrade.
    /// @dev This structure is like an instruction card that says, “Make this change to the diamond.”
    struct FacetCut {
        /// @notice This is the address of the facet (tool) we’re adding, changing, or removing.
        address facetAddress;
        /// @notice This is a number that says what kind of change to make: 0 means “Add”, 1 means “Replace”, 2 means “Remove”. In this basic version, we only use 0 (Add).
        uint8 action;
        /// @notice This is a list of function selectors (4-byte codes) that we’re adding, changing, or removing for this facet.
        bytes4[] functionSelectors;
    }

    /// @notice This function gets access to the diamond’s data (its filing cabinet) so we can read or change it.
    /// @dev The `internal` keyword means only contracts using this library (like `Diamond.sol`) can call this function. `pure` means it doesn’t change or read the blockchain’s state—it just sets up a pointer.
    /// @return ds A pointer to the diamond’s data, letting us read or change it.
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        /// This gets the unique spot (storage slot) where the diamond’s data lives.
        /// We defined `DIAMOND_STORAGE_POSITION` earlier using `keccak256`, so we always look in the same spot for the diamond’s data.
        bytes32 position = DIAMOND_STORAGE_POSITION;

        // This uses low-level code (assembly) to connect our pointer `ds` to the correct spot in the blockchain’s memory.
        // Assembly is like giving direct instructions to the blockchain. Here, we’re saying, “Make `ds` point to the spot labeled `position`.”
        assembly {
            ds.slot := position
        }
    }

    /// @notice This function sets a new owner for the diamond.
    /// @dev This is called when the diamond is created or when the owner transfers ownership to someone else. It updates the owner and sends out a message (event) to let everyone know.
    /// @param _newOwner The address (unique ID) of the new owner.
    function setContractOwner(address _newOwner) internal {
        /// @notice This checks that the new owner isn’t the “zero address” (a special address that means “nobody”).
        /// @dev If the new owner is `address(0)`, we stop the function and show an error, because the diamond must always have an owner.
        require(
            _newOwner != address(0),
            "LibDiamond: New owner is zero address"
        );

        /// @notice This gets access to the diamond’s data (its filing cabinet) so we can change the owner.
        DiamondStorage storage ds = diamondStorage();

        /// @notice This saves the current owner’s address so we can use it in the event later.
        address previousOwner = ds.contractOwner;

        /// @notice This updates the diamond’s owner to the new address.
        ds.contractOwner = _newOwner;

        /// @notice This sends out a message (event) to tell everyone the owner changed, including the old and new owner’s addresses.
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /// @notice This function gets the current owner of the diamond.
    /// @dev This is used to check who the owner is, like when we need to make sure only the owner can do something (e.g., upgrade the diamond).
    /// @return The address (unique ID) of the current owner.
    function contractOwner() internal view returns (address) {
        /// @notice This gets access to the diamond’s data and returns the owner’s address.
        /// @dev The `view` keyword means this function only reads data and doesn’t change anything on the blockchain.
        return diamondStorage().contractOwner;
    }

    /// @notice This function upgrades the diamond by adding new facets and functions, and optionally running a setup step.
    /// @dev This is the heart of the diamond’s upgradability! It’s like adding new tools to the Swiss Army knife and setting them up.
    /// @param _diamondCut A list of changes (FacetCut structs) to make to the diamond, like adding new facets and functions.
    /// @param _init The address of a setup contract (initializer) to run after the changes, or `address(0)` if there’s no setup.
    /// @param _calldata The setup instructions to send to the initializer, or empty if there’s no setup.
    function diamondCut(
        FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        /// @notice This gets access to the diamond’s data so we can update it with the new facets and functions.
        DiamondStorage storage ds = diamondStorage();

        /// @notice This loops through each change (FacetCut) in the list of changes we’re making to the diamond.
        /// @dev We use a `for` loop to go through each instruction one by one, like following a list of tasks.
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            /// @notice This gets the current change (FacetCut) we’re working on, like “Add this facet with these functions.”
            FacetCut memory cut = _diamondCut[facetIndex];

            /// @notice This checks that the change is an “Add” action (action = 0).
            /// @dev In this basic implementation, we only support adding new functions, not replacing or removing them. If the action isn’t “Add”, we stop and show an error.
            require(cut.action == 0, "LibDiamond: Only Add action supported");

            /// @notice This loops through each function selector (4-byte code) in the current change.
            /// @dev Each `FacetCut` can add multiple functions, so we go through each one to add it to the diamond.
            for (
                uint256 selectorIndex;
                selectorIndex < cut.functionSelectors.length;
                selectorIndex++
            ) {
                /// @notice This gets the current function selector (4-byte code) we’re adding.
                bytes4 selector = cut.functionSelectors[selectorIndex];

                /// @notice This sets the facet address for this function selector in the diamond’s records.
                /// @dev We’re saying, “This function lives in this facet,” so the diamond knows where to find it later.
                ds.facetAddressAndSelectorPosition[selector].facetAddress = cut
                    .facetAddress;

                /// @notice This sets the position of this function selector in the diamond’s list of all selectors.
                /// @dev We store the position so we can keep track of the order of functions. `ds.selectors.length` is the current length of the list, which will be the new selector’s position.
                ds
                    .facetAddressAndSelectorPosition[selector]
                    .selectorPosition = uint16(ds.selectors.length);

                /// @notice This adds the function selector to the diamond’s list of all selectors.
                /// @dev We keep a list of all functions the diamond can use, so we add this new one to the end.
                ds.selectors.push(selector);
            }
        }

        /// @notice This sends out a message (event) to tell everyone about the changes we made to the diamond.
        /// @dev This event includes the list of changes, the setup contract (if any), and the setup instructions (if any).
        emit DiamondCut(_diamondCut, _init, _calldata);

        /// @notice This checks if there’s a setup contract (initializer) to run after the changes.
        /// @dev If `_init` isn’t `address(0)`, it means we have a setup step to do, like running `DiamondInit.init`.
        if (_init != address(0)) {
            /// @notice This runs the setup contract by sending it the setup instructions (`_calldata`) using a special method called `delegatecall`.
            /// @dev `delegatecall` lets the setup contract run its code but use the diamond’s data, like hiring a setup expert to work on the diamond’s storage.
            (bool success, ) = _init.delegatecall(_calldata);

            /// @notice This checks if the setup worked. If it fails, we stop and show an error.
            /// @dev If the setup fails, something went wrong (like the setup contract had an error), so we stop the upgrade to keep the diamond safe.
            require(success, "LibDiamond: Init call failed");
        }
    }
}
