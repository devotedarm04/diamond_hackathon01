## Diamond-1 Implementation (EIP-2535)

This project is a basic implementation of the EIP-2535 Diamond Standard, a modular smart contract design pattern that allows a single contract (the "Diamond") to use multiple smaller contracts (called "facets") to perform different tasks. 

The EIP-2535 Diamond Standard allows a smart contract (the Diamond) to delegate function calls to smaller contracts (facets), making the contract upgradeable and modular. Instead of having one big contract with all the code, the Diamond can:

- Use multiple facets to handle different tasks (e.g., upgrading, ownership, inspection).

- Add, replace, or remove functions over time without redeploying the entire contract.

- Stay under the Ethereum contract size limit (24 KB) by splitting code into smaller pieces.


## Folder Structure ->  

diamond-1/
 ├── src/
 │   ├── Diamond.sol              # The main Diamond contract
 │   ├── libraries/
 │   │   └── LibDiamond.sol       # Library for managing the Diamond’s data
 │   ├── Facets/
 │   │   ├── DiamondCutFacet.sol  # Facet for upgrading the Diamond
 │   │   ├── DiamondLoupeFacet.sol # Facet for inspecting the Diamond
 │   │   ├── OwnershipFacet.sol   # Facet for managing ownership
 │   │   └── SimpleFacet.sol      # A test facet for adding/upgrading functions
 │   └── upgradeInitializers/
 │       └── DiamondInit.sol      # Contract for initializing the Diamond
 ├── test/
 │   ├── DiamondTest.t.sol        # Tests for the Diamond’s functionality
 │   └── DiamondDeploymentTest.t.sol # Tests for the deployment script
 ├── script/
 │   └── Diamond.s.sol            # Deployment script for the Diamond
 └── README.md                    # This file


## How the Diamond 1 Implementation Works ? 






















## Foundry 

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
