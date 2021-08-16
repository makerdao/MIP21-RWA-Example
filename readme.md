# equipment for off-chain asset backed lending in MakerDAO

## components:

- `RwaLiquidationOracle`: which acts as a liquidation beacon for an off-chain enforcer.
- `RwaUrn`: which facilitates borrowing of DAI, delivering to a designated account.
- `RwaOutputConduit` and `RwaInputConduit`: which disburse and repay DAI
- `RwaSpell`: which deploys and activates a new collateral type
- `RwaToken`: which represents the RWA collateral in the system

## spells:

The following can be found in `src/RwaSpell.sol`:
- `RwaSpell`: which deploys and configures the RWA collateral in MakerDAO in accordance with MIP21 

The following can be found in `src/test/RwaSpell.t.sol`:

- `TellSpell`: which allows MakerDAO governance to initiate liquidation proceedings.
- `CureSpell`: which allows MakerDAO governance to dismiss liquidation proceedings.
- `CullSpell`: which allows MakerDAO governance to write off a loan which was in liquidation.

## deploy

### kovan
```
make deploy-kovan
```

### goerli
```
make deploy-goerli
```

### mainnet
```
make deploy-mainnet
```
