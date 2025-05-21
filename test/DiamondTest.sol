// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/libraries/LibDiamond.sol";
import "../src/Facets/DiamondCutFacet.sol";
import "../src/Facets/DiamondLoupeFacet.sol";
import "../src/Facets/OwnershipFacet.sol";
import "../src/upgradeInitializers.sol/DiamondInit.sol";
import "../src/Facets/SimpleFacet.sol";

/// @title DiamondTest
/// @notice This is a test contract called `DiamondTest` that checks if our diamond implementation works correctly.
/// @dev This contract uses Foundry’s testing framework to deploy the diamond, add facets, upgrade facets, and test ownership features. It’s like a quality checker for our diamond!
contract DiamondTest is Test {
    /// @notice This declares a variable to store the address (like a unique ID) of the owner of the diamond. The owner has special permissions, like upgrading the diamond.
    address owner;

    /// @notice This declares a variable to store the `Diamond` contract after we deploy it. It’s the main contract we’re testing.
    Diamond diamond;

    /// @notice This declares a variable to store the `DiamondCutFacet` contract after we deploy it. We’ll use it to upgrade the diamond.
    DiamondCutFacet diamondCutFacet;

    /// @notice This declares a variable to store the `DiamondLoupeFacet` contract after we deploy it. We’ll use it to inspect the diamond.
    DiamondLoupeFacet diamondLoupeFacet;

    /// @notice This declares a variable to store the `OwnershipFacet` contract after we deploy it. We’ll use it to manage ownership.
    OwnershipFacet ownershipFacet;

    /// @notice This declares a variable to store the `DiamondInit` contract after we deploy it. We’ll use it to set up the diamond during deployment.
    DiamondInit diamondInit;

    /// @notice This declares a variable to store the `SimpleFacet` contract after we deploy it. We’ll use it to test adding and upgrading facets.
    SimpleFacet simpleFacet;

    /// @notice This is a special function called `setUp` that Foundry runs before each test. It sets up everything we need for testing, like deploying contracts.
    /// @dev Think of this as preparing the stage before the show: we deploy the diamond and its facets so we can test them.
    function setUp() public {
        /// @notice This sets the owner to the address of this test contract. Since the test contract is running the tests, it will act as the owner.
        /// @dev In Solidity, `address(this)` means “the address of this contract.” So, this test contract will have owner privileges.
        owner = address(this);

        // Deploy facets
        /// @notice This creates a new `DiamondCutFacet` contract and stores it in the `diamondCutFacet` variable.
        /// @dev The `new` keyword deploys a new contract on the blockchain during the test, and we save it so we can use it later.
        diamondCutFacet = new DiamondCutFacet();

        /// @notice This creates a new `DiamondLoupeFacet` contract and stores it in the `diamondLoupeFacet` variable.
        diamondLoupeFacet = new DiamondLoupeFacet();

        /// @notice This creates a new `OwnershipFacet` contract and stores it in the `ownershipFacet` variable.
        ownershipFacet = new OwnershipFacet();

        /// @notice This creates a new `DiamondInit` contract and stores it in the `diamondInit` variable.
        diamondInit = new DiamondInit();

        /// @notice This creates a new `SimpleFacet` contract and stores it in the `simpleFacet` variable.
        /// @dev We don’t add `SimpleFacet` to the diamond yet—we’ll do that in a test later to check if adding facets works.
        simpleFacet = new SimpleFacet();

        // Prepare diamondCut for initial facets
        /// @notice This creates a list (array) of 3 instructions (called `FacetCut`) to tell the diamond which facets to connect to when it’s created.
        /// @dev `FacetCut` is a structure defined in `LibDiamond` that says, “Connect this facet to these functions.”
        LibDiamond.FacetCut[] memory cut = new LibDiamond.FacetCut[](3);

        /// @notice This sets up the first instruction: connect the `DiamondCutFacet` to the diamond with its `diamondCut` function.
        cut[0] = LibDiamond.FacetCut({
            /// @notice This is the address of the `DiamondCutFacet` contract we deployed.
            facetAddress: address(diamondCutFacet),
            /// @notice This says we want to “add” this facet (0 means “Add”). In a basic implementation, we only support adding facets.
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

        // Deploy Diamond
        /// @notice This creates a bundle of setup details (called `DiamondArgs`) to tell the diamond who its owner is and how to set itself up.
        DiamondArgs memory args = DiamondArgs({
            /// @notice This sets the owner to the test contract’s address (so we can act as the owner during tests).
            owner: owner,
            /// @notice This sets the address of the `DiamondInit` contract, which will run setup steps for the diamond.
            init: address(diamondInit),
            /// @notice This prepares the setup instructions for `DiamondInit` by encoding a call to its `init` function.
            /// @dev `abi.encodeWithSelector` creates a message that says, “Call the `init` function on `DiamondInit`.”
            initCalldata: abi.encodeWithSelector(DiamondInit.init.selector)
        });

        /// @notice This creates a new `Diamond` contract with the facets we prepared (`cut`) and the setup details (`args`).
        /// @dev This deploys the diamond, making it ready for testing. It’s like turning on the Swiss Army knife with its first set of tools!
        diamond = new Diamond(cut, args);
    }

    /// @notice This test checks if the diamond deploys correctly and sets up its initial facets and owner.
    /// @dev It’s like checking if the Swiss Army knife opens up with the right tools and knows who its owner is.
    function testDeployment() public {
        // Test ownership
        /// @notice This calls the `owner` function on the diamond to check who the owner is.
        /// @dev We use `call` to send a message to the diamond, asking for the owner. `abi.encodeWithSignature` creates the message for the `owner` function.
        (bool success, bytes memory data) = address(diamond).call(
            abi.encodeWithSignature("owner()")
        );

        /// @notice This checks if the call worked. If it fails, something’s wrong with the diamond, so we stop the test and show an error.
        require(success, "Owner call failed");

        /// @notice This decodes the result of the `owner` call to get the owner’s address.
        /// @dev The diamond sends back the owner’s address as raw data, so we use `abi.decode` to turn it into an address we can read.
        address returnedOwner = abi.decode(data, (address));

        /// @notice This checks if the owner we got back matches the owner we set (this test contract).
        /// @dev `assertEq` is a Foundry tool that says, “Make sure these two things are the same, or the test fails.”
        assertEq(returnedOwner, owner, "Owner not set correctly");

        // Test facets
        /// @notice This calls the `facets` function on the diamond to get a list of all connected facets.
        /// @dev This tests if the diamond knows which facets we added during deployment (like checking the Swiss Army knife’s tools).
        (success, data) = address(diamond).call(
            abi.encodeWithSignature("facets()")
        );

        /// @notice This checks if the call worked. If it fails, something’s wrong with the `facets` function.
        require(success, "Facets call failed");

        /// @notice This decodes the result of the `facets` call to get the list of facets.
        /// @dev `facets` returns a list of `Facet` structures (defined in `DiamondLoupeFacet`), so we decode the data into that format.
        DiamondLoupeFacet.Facet[] memory facets = abi.decode(
            data,
            (DiamondLoupeFacet.Facet[])
        );

        /// @notice This checks if the number of facets is 3, since we added 3 facets during deployment (`DiamondCutFacet`, `DiamondLoupeFacet`, `OwnershipFacet`).
        /// @dev If the number isn’t 3, something went wrong during deployment, and the test will fail.
        assertEq(facets.length, 3, "Incorrect number of facets");
    }

    /// @notice This test checks if we can add a new facet (`SimpleFacet`) to the diamond and use its `sayHello` function.
    /// @dev It’s like adding a new tool to the Swiss Army knife and making sure it works.
    function testAddSimpleFacet() public {
        /// @notice This declares a variable to store whether a call succeeds (true) or fails (false).
        bool success;

        /// @notice This declares a variable to store the data (result) returned by a call.
        bytes memory data;

        // Add SimpleFacet
        /// @notice This creates a list of 1 instruction to add the `SimpleFacet` to the diamond.
        LibDiamond.FacetCut[] memory cut = new LibDiamond.FacetCut[](1);

        /// @notice This sets up the instruction: add the `SimpleFacet` with its `sayHello` function.
        cut[0] = LibDiamond.FacetCut({
            facetAddress: address(simpleFacet),
            action: 0,
            functionSelectors: new bytes4[](1)
        });
        /// @notice This specifies the `sayHello` function to add.
        cut[0].functionSelectors[0] = bytes4(keccak256("sayHello()"));

        /// @notice This calls the `diamondCut` function on the diamond to add the `SimpleFacet`.
        /// @dev Since this test contract is the owner, it’s allowed to call `diamondCut`. We pass the instruction (`cut`), no initializer (`address(0)`), and no setup data (`bytes("")`).
        (success, ) = address(diamond).call(
            abi.encodeWithSignature(
                "diamondCut((address,uint8,bytes4[])[],address,bytes)",
                cut,
                address(0),
                bytes("")
            )
        );

        /// @notice This checks if the call worked. If it fails, we couldn’t add the facet, so the test stops.
        require(success, "Add SimpleFacet failed");

        // Test sayHello
        /// @notice This calls the `sayHello` function on the diamond, which should now be connected to `SimpleFacet`.
        (success, data) = address(diamond).call(
            abi.encodeWithSignature("sayHello()")
        );

        /// @notice This checks if the call worked. If it fails, `sayHello` isn’t working, so the test stops.
        require(success, "sayHello call failed");

        /// @notice This decodes the result of `sayHello` to get the string it returned.
        /// @dev `sayHello` returns a string, so we use `abi.decode` to turn the raw data into a string.
        string memory result = abi.decode(data, (string));

        /// @notice This checks if the result of `sayHello` is “Hello from SimpleFacet!”, which is what `SimpleFacet` should return.
        /// @dev If the result doesn’t match, the test fails, meaning the facet wasn’t added correctly.
        assertEq(
            result,
            "Hello from SimpleFacet!",
            "sayHello returned incorrect value"
        );
    }

    /// @notice This test checks if we can upgrade the diamond by adding a new function (`sayHelloUpgraded`) to `SimpleFacet` and ensure both functions work.
    /// @dev It’s like adding a new feature to an existing tool in the Swiss Army knife and making sure the old feature still works.
    function testUpgradeSimpleFacet() public {
        /// @notice This declares a variable to store whether a call succeeds (true) or fails (false).
        bool success;

        /// @notice This declares a variable to store the data (result) returned by a call.
        bytes memory data;

        // First add sayHello
        /// @notice This creates a list of 1 instruction to add the `SimpleFacet` with its `sayHello` function.
        LibDiamond.FacetCut[] memory cut = new LibDiamond.FacetCut[](1);

        /// @notice This sets up the instruction: add the `SimpleFacet` with `sayHello`.
        cut[0] = LibDiamond.FacetCut({
            facetAddress: address(simpleFacet),
            action: 0,
            functionSelectors: new bytes4[](1)
        });
        cut[0].functionSelectors[0] = bytes4(keccak256("sayHello()"));

        /// @notice This calls `diamondCut` to add `SimpleFacet` with `sayHello`.
        (success, ) = address(diamond).call(
            abi.encodeWithSignature(
                "diamondCut((address,uint8,bytes4[])[],address,bytes)",
                cut,
                address(0),
                bytes("")
            )
        );

        /// @notice This checks if the call worked. If it fails, we couldn’t add the facet.
        require(success, "Add SimpleFacet failed");

        // Upgrade by adding sayHelloUpgraded
        /// @notice This updates the instruction to add the `sayHelloUpgraded` function to `SimpleFacet`.
        /// @dev Since `SimpleFacet` already has `sayHello`, this adds a new function to the same facet, which is how we upgrade in this basic implementation.
        cut[0].functionSelectors[0] = bytes4(keccak256("sayHelloUpgraded()"));

        /// @notice This calls `diamondCut` again to add `sayHelloUpgraded` to the diamond.
        (success, ) = address(diamond).call(
            abi.encodeWithSignature(
                "diamondCut((address,uint8,bytes4[])[],address,bytes)",
                cut,
                address(0),
                bytes("")
            )
        );

        /// @notice This checks if the call worked. If it fails, the upgrade didn’t work.
        require(success, "Upgrade SimpleFacet failed");

        // Test sayHelloUpgraded
        /// @notice This calls the new `sayHelloUpgraded` function to make sure the upgrade worked.
        (success, data) = address(diamond).call(
            abi.encodeWithSignature("sayHelloUpgraded()")
        );

        /// @notice This checks if the call worked. If it fails, `sayHelloUpgraded` isn’t working.
        require(success, "sayHelloUpgraded call failed");

        /// @notice This decodes the result of `sayHelloUpgraded` to get the string it returned.
        string memory result = abi.decode(data, (string));

        /// @notice This checks if the result is “Hello from Upgraded SimpleFacet!”, which `sayHelloUpgraded` should return.
        assertEq(
            result,
            "Hello from Upgraded SimpleFacet!",
            "sayHelloUpgraded returned incorrect value"
        );

        // Test sayHello still works
        /// @notice This calls the original `sayHello` function to make sure it still works after the upgrade.
        (success, data) = address(diamond).call(
            abi.encodeWithSignature("sayHello()")
        );

        /// @notice This checks if the call worked. If it fails, the upgrade broke `sayHello`.
        require(success, "sayHello call failed after upgrade");

        /// @notice This decodes the result of `sayHello` to get the string it returned.
        result = abi.decode(data, (string));

        /// @notice This checks if `sayHello` still returns “Hello from SimpleFacet!”.
        /// @dev This ensures the upgrade didn’t break the existing function, which is important for a reliable diamond.
        assertEq(
            result,
            "Hello from SimpleFacet!",
            "sayHello returned incorrect value after upgrade"
        );
    }

    /// @notice This test checks if the owner can transfer ownership of the diamond to a new address.
    /// @dev It’s like checking if the admin of the Swiss Army knife can give control to someone else.
    function testOwnershipTransfer() public {
        /// @notice This declares a variable to store whether a call succeeds (true) or fails (false).
        bool success;

        /// @notice This declares a variable to store the data (result) returned by a call.
        bytes memory data;

        /// @notice This creates a fake address (0x123) to act as the new owner we’ll transfer ownership to.
        /// @dev In a real scenario, this would be a real address, but for testing, we just use a made-up one.
        address newOwner = address(0x123);

        /// @notice This calls the `transferOwnership` function on the diamond to give ownership to the new address.
        (success, ) = address(diamond).call(
            abi.encodeWithSignature("transferOwnership(address)", newOwner)
        );

        /// @notice This checks if the call worked. If it fails, we couldn’t transfer ownership.
        require(success, "Transfer ownership failed");

        /// @notice This calls the `owner` function to check who the owner is now.
        (success, data) = address(diamond).call(
            abi.encodeWithSignature("owner()")
        );

        /// @notice This checks if the call worked. If it fails, something’s wrong with the `owner` function.
        require(success, "Owner call failed");

        /// @notice This decodes the result to get the owner’s address.
        address returnedOwner = abi.decode(data, (address));

        /// @notice This checks if the new owner matches the address we transferred to (0x123).
        assertEq(
            returnedOwner,
            newOwner,
            "Ownership not transferred correctly"
        );
    }
}
