# equipment for off-chain asset backed lending in MakerDAO

## components:

- `RwaLiquidationOracle`: which acts as a liquidation beacon for an off-chain enforcer.
- `RwaFlipper`: which acts as a dummy liquidation module in the event of write-offs.
- `RwaUrn`: which facilitates borrowing of DAI, delivering to a designated account.

## todo:

- `RwaInitSpell`: which deploys and activates a new collateral type
- intermediary wallet contracts for handling disbursement and repayment of DAI.
- `RwaLiquidateSpell`: which allows MakerDAO governance to initiate liquidation proceedings.
- `RwaRemedySpell`: which allows MakerDAO governance to dismiss liquidation proceedings.
- `RwaWriteoffSpell`: which allows MakerDAO governance to write off a loan which was in liquidation.
- ???

## deploy

### kovan
```
make deploy-kovan
```

### mainnet
```
make deploy-mainnet
```
