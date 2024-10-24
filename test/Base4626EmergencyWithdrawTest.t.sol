// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import "src/IVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

interface IBase4626Compounder is ITokenizedStrategy {
    function vault() external view returns (address);

    function balanceOfAsset() external view returns (uint256);

    function balanceOfVault() external view returns (uint256);

    function balanceOfStake() external view returns (uint256);

    function valueOfVault() external view returns (uint256);

    function vaultsMaxWithdraw() external view returns (uint256);

    function staking() external view returns (address);
}

interface ISturdy {
    function pair() external view returns (address);
}

contract Base4626EmergencyWithdrawTest is Test {
    function test_gearbox_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address gearboxWeth = 0xe92ade9eE76681f96C8BB0b352d5410ca5b35D70;
        address gearboxCrv = 0xbf2e5BeD692C09aF8B39677e315F36aDF39bD685;
        verifyGearboxEmergencyExit(gearboxWeth);
        verifyGearboxEmergencyExit(gearboxCrv);
    }

    function test_sturdy_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address sturdyCrvCompounder = 0x05329AAb081B125eEF7FbbC8b857428D478E692B;
        address sturdyWeth = 0x5f76526390d9cd9944d65C605C5006480FA1bFcB;
        verifyEmergencyExit(sturdyCrvCompounder);
        verifyEmergencyExit(sturdyWeth);
    }

    function verifyGearboxEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        // assertNotEq(admin, address(0), "emergencyAdmin not set"); // TODO: enable when emergencyAdmin is set
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        // IMPORTANT: need to override this: https://github.com/yearn/yearn-strategies/issues/642#issuecomment-2402732907
        IERC4626 vault = IERC4626(strategy.vault());
        uint256 maxWithdrawAmount =
            vault.convertToAssets(Math.min(vault.maxRedeem(strategy.staking()), strategy.balanceOfStake()));
        maxWithdrawAmount += strategy.balanceOfAsset();
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertLt(strategy.balanceOfStake(), 10, "balanceOfStake not zero");
        assertLt(strategy.valueOfVault(), 10, "vaule still in vault"); // allow some dust
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");
        // verify strategy has recovered all assets or maximum possible
        assertGe(strategyBalance, Math.min(assets, maxWithdrawAmount), "strategy didn't recover all asset");
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        // assertNotEq(admin, address(0), "emergencyAdmin not set"); // TODO: enable when emergencyAdmin is set
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        IVault vault = IVault(strategy.vault());
        ISturdy sturdy = ISturdy(vault.default_queue(0));
        address pair = sturdy.pair();
        uint256 maxWithdrawAmount =
            Math.min(strategy.availableWithdrawLimit(address(0)), ERC20(strategy.asset()).balanceOf(pair));
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertLt(strategy.balanceOfStake(), 10, "balanceOfStake not zero");
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");

        // study strategy has some rounding error because of converting assets to shares
        uint256 roundingError = 3;
        // verify strategy has recovered all assets or maximum possible
        assertGe(strategyBalance + roundingError, Math.min(assets, maxWithdrawAmount), "strategy didn't recover all asset");
    }
}
