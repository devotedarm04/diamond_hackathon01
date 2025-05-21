## Diamond-1 Implementation (EIP-2535)

This project is a basic implementation of the EIP-2535 Diamond Standard, a modular smart contract design pattern that allows a single contract (the "Diamond") to use multiple smaller contracts (called "facets") to perform different tasks. 

The EIP-2535 Diamond Standard allows a smart contract (the Diamond) to delegate function calls to smaller contracts (facets), making the contract upgradeable and modular. Instead of having one big contract with all the code, the Diamond can:

- Use multiple facets to handle different tasks (e.g., upgrading, ownership, inspection).

- Add, replace, or remove functions over time without redeploying the entire contract.

- Stay under the Ethereum contract size limit (24 KB) by splitting code into smaller pieces.


## Folder Structure ->  
```
diamond-1/
├── src/
│   ├── Diamond.sol                  # Main Diamond contract
│   ├── libraries/
│   │   └── LibDiamond.sol           # Internal library for Diamond storage and logic
│   ├── Facets/
│   │   ├── DiamondCutFacet.sol      # Enables upgrades to the Diamond (cut function)
│   │   ├── DiamondLoupeFacet.sol    # View functions to inspect Diamond facets/functions
│   │   ├── OwnershipFacet.sol       # Handles contract ownership and access control
│   │   └── SimpleFacet.sol          # Sample/test facet for adding external functions
│   └── upgradeInitializers/
│       └── DiamondInit.sol          # Initialization logic run on deployment or upgrade
├── test/
│   ├── DiamondTest.t.sol            # Unit tests for Diamond functionality
│   └── DiamondDeploymentTest.t.sol # Tests for deployment and initialization
├── script/
│   └── Diamond.s.sol                # Deployment script using Foundry
└── README.md                        # Project documentation (this file)
```

# How the Diamond 1 Implementation Works? 
![diamond working](https://github.com/user-attachments/assets/b7910eec-1711-4687-8f6a-7b640b880338)


