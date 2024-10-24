# Emergency Withdraw Tests

This repository contains tests that call the function `emergencyWithdraw()` on Yearn V3 strategies. The tests are organized by the protocol that the strategy is using. If the protocol is forked, it will be in the same file as the original protocol, e.g. `Spark` is forked from `Aave`, so the tests for both are in `AaveEmergencyWithdrawTest.t.sol`.

## Getting Started

First, check if the `.env` file is set up correctly. See the `.env.example` file for an example.

To run all tests use:

```sh
forge test
```

## Strategies Tested

- [Aave V3](./test/AaveEmergencyWithdrawTest.t.sol) on mainnet, arbitrum and polygon
- [Spark](./test/AaveEmergencyWithdrawTest.t.sol) on mainnet
- [Across](./test/AcrossEmergencyWithdrawTest.t.sol) on mainnet
- [Gearbox](./test/Base4626EmergencyWithdrawTest.t.sol) on mainnet
- [Sturdy](./test/Base4626EmergencyWithdrawTest.t.sol) on mainnet
- [Compound V3](./test/CompoundEmergencyWithdrawTest.t.sol) on mainnet, arbitrum and polygon
- [Maker & Sky](./test/MakerEmergencyWithdrawTest.t.sol) on mainnet
- [Pendle](./test/PendleEmergencyWithdrawTest.t.sol) on mainnet and arbitrum
- [Silo](./test/SiloEmergencyWithdrawTest.t.sol) on arbitrum

### Strategies Failing

Some of them are reverting on emergencyWithdraw(uint256.max):

- [AaveV3 DAI Lender](https://polygonscan.com/address/0xf4f9d5697341b4c9b0cc8151413e05a90f7dc24f)

Here are the simulations of reverts on Tenderly:

- Aave DAI - https://dashboard.tenderly.co/yearn/sam/fork/485126d4-9252-4a88-9f94-8389acc5f65c/simulation/531845d2-0b19-4f03-953e-1cc4b4e9f044?trace=0.0.7.1.2.0.2.0.3.24.2

Emergency admin is not set for the following strategies:

- mainnet crvusd aave v3 lender: https://etherscan.io/address/0x27ffA71dBB25A7C52A3Da74C6eED8C94c9A43E0d#readProxyContract#F11
- arbitrum usdt aave v3 lender: https://arbiscan.io/address/0x4ae5ce819e7d678b07e8d0f483d351e2c8e8b8d3#readProxyContract#F12
- polygon usdc aave v3: https://polygonscan.com/address/0x52367C8E381EDFb068E9fBa1e7E9B2C847042897#readProxyContract#F12
- mainnet crv sturdy: https://etherscan.io/address/0x05329AAb081B125eEF7FbbC8b857428D478E692B#readProxyContract#F11
