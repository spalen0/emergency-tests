// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface IAcrossStrategy is ITokenizedStrategy {
    function balanceOfLp() external view returns (uint256);
    function balanceOfStake() external view returns (uint256);
}

contract AcrossEmergencyWithdrawTest is Test {
    function test_accross_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address acrossWeth = 0x9861708f2ad2BD1ed8D4D12436C0d8EB1ED36f1c;
        verifyEmergencyExit(acrossWeth);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        IAcrossStrategy strategy = IAcrossStrategy(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        // uint256 balanceOfBase = ERC20(strategy.comet()).balanceOf(address(strategy));

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        assertNotEq(admin, address(0), "emergencyAdmin not set");
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all withdrawable assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        // all funds are either staked or it was withdrawn
        assertLt(strategy.balanceOfLp(), 10, "balanceOfStake not zero");
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");
        // verify strategy has recovered all assets or maximum possible
        assertGe(strategyBalance, Math.min(assets, maxWithdrawAmount), "strategy didn't recover all asset");
    }
}
