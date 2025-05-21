// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Diamond.sol";
import "../src/libraries/LibDiamond.sol";
import "../src/Facets/DiamondCutFacet.sol";
import "../src/Facets/DiamondLoupeFacet.sol";
import "../src/Facets/OwnershipFacet.sol";
import "../src/upgradeInitializers.sol/DiamondInit.sol";

/// @title DiamondDeploymentScript
/// @notice This is a script called `DiamondDeploymentScript` that deploys the Diamond-1 contract and its initial facets.
/// @dev This script uses Foundry’s scripting tools to deploy the diamond on a pretend blockchain (like a test network). It’s like a recipe for setting up the Swiss Army knife with its first set of tools!
contract DiamondDeploymentScript is Script {
    /// @notice This declares a variable to store the `Diamond` contract after we deploy it.
    /// @dev We’ll use this to interact with the diamond after deployment.
    Diamond diamond;

    /// @notice This is the main function that Foundry calls to run the deployment script.
    /// @dev The `run` function is like the “start” button for the script—it sets up everything we need to deploy the diamond.
    function run() external {
        /// @notice This starts a pretend transaction so we can deploy contracts.
        /// @dev `vm.startBroadcast` is a Foundry tool that simulates sending transactions to the blockchain, like pressing “record” to start deploying.
        vm.startBroadcast();

        /// @notice This deploys the `DiamondCutFacet` contract, which will let the owner upgrade the diamond.
        /// @dev The `new` keyword deploys a new contract on the blockchain, and we save it so we can use it later.
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        /// @notice This deploys the `DiamondLoupeFacet` contract, which will let us inspect the diamond.
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();

        /// @notice This deploys the `OwnershipFacet` contract, which will manage who owns the diamond.
        OwnershipFacet ownershipFacet = new OwnershipFacet();

        /// @notice This deploys the `DiamondInit` contract, which will set up the diamond during deployment.
        DiamondInit diamondInit = new DiamondInit();

        /// @notice This creates a list (array) of 3 instructions (called `FacetCut`) to tell the diamond which facets to connect to when it’s created.
        /// @dev `FacetCut` is a structure defined in `LibDiamond` that says, “Connect this facet to these functions.” We’re setting up 3 facets: `DiamondCutFacet`, `DiamondLoupeFacet`, and `OwnershipFacet`.
        LibDiamond.FacetCut[] memory cut = new LibDiamond.FacetCut[](3);

        /// @notice This sets up the first instruction: connect the `DiamondCutFacet` to the diamond with its `diamondCut` function.
        cut[0] = LibDiamond.FacetCut({
            /// @notice This is the address of the `DiamondCutFacet` contract we deployed.
            facetAddress: address(diamondCutFacet),
            /// @notice This says we want to “add” this facet (0 means “Add”). In this basic implementation, we only support adding facets.
            action: 0,
            /// @notice This creates a list of 1 function to connect from `DiamondCutFacet`.
            functionSelectors: new bytes4[](1)
        });
        /// @notice This sets the function to connect: the `diamondCut` function, identified by its 4-byte code (selector).
        /// @dev `keccak256` creates a unique code for the function’s name and arguments, and `bytes4` takes the first 4 bytes of that code.
        cut[0].functionSelectors[0] = bytes4(
            keccak256("diamondCut((address,uint8,bytes4[])[],address,bytes)")
        );

        /// @notice This sets up the second instruction: connect the `DiamondLoupeFacet` with its `facets` function.
        cut[1] = LibDiamond.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: 0,
            functionSelectors: new bytes4[](1)
        });
        /// @notice This connects the `facets` function, which lets us inspect the diamond.
        cut[1].functionSelectors[0] = bytes4(keccak256("facets()"));

        /// @notice This sets up the third instruction: connect the `OwnershipFacet` with its `owner` and `transferOwnership` functions.
        cut[2] = LibDiamond.FacetCut({
            facetAddress: address(ownershipFacet),
            action: 0,
            functionSelectors: new bytes4[](2)
        });
        /// @notice This connects the `owner` function, which tells us who owns the diamond.
        cut[2].functionSelectors[0] = bytes4(keccak256("owner()"));
        /// @notice This connects the `transferOwnership` function, which lets the owner give ownership to someone else.
        cut[2].functionSelectors[1] = bytes4(
            keccak256("transferOwnership(address)")
        );

        /// @notice This creates a bundle of setup details (called `DiamondArgs`) to tell the diamond who its owner is and how to set itself up.
        /// @dev We’re setting the owner to the person running this script (`msg.sender`) and telling the diamond to use `DiamondInit` for setup.
        DiamondArgs memory args = DiamondArgs({
            /// @notice This sets the owner to the person running the script (the deployer).
            owner: msg.sender,
            /// @notice This sets the address of the `DiamondInit` contract, which will run setup steps for the diamond.
            init: address(diamondInit),
            /// @notice This prepares the setup instructions for `DiamondInit` by encoding a call to its `init` function.
            /// @dev `abi.encodeWithSelector` creates a message that says, “Call the `init` function on `DiamondInit`.”
            initCalldata: abi.encodeWithSelector(DiamondInit.init.selector)
        });

        /// @notice This deploys the `Diamond` contract with the facets we prepared (`cut`) and the setup details (`args`).
        /// @dev This is the main step—it creates the diamond, making it ready to use with its first set of tools (facets).
        diamond = new Diamond(cut, args);

        /// @notice This stops the pretend transaction after we’ve deployed everything.
        /// @dev `vm.stopBroadcast` is like pressing “stop” on the recording—it finishes the deployment process.
        vm.stopBroadcast();

        /// @notice This logs the address of the deployed diamond so we can use it later.
        /// @dev `console.log` is a Foundry tool that prints information to the terminal, like a note saying, “Here’s where your diamond lives!”
        console.log("Diamond deployed at:", address(diamond));
    }
}
