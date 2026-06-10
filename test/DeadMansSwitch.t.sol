// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DeadMansSwitch.sol";

contract DeadMansSwitchTest is Test {
    DeadMansSwitch dms;
    address owner = address(1);
    address beneficiary1 = address(2);
    address beneficiary2 = address(3);

    function setUp() public {
        // Deploy contract as owner
        vm.prank(owner);
        dms = new DeadMansSwitch(3600, 1800);

        // Give owner some ETH
        vm.deal(owner, 10 ether);
    }

    // ✅ Test 1: checkIn()
    function test_checkIn() public {
        vm.prank(owner);
        dms.checkIn();
        assertEq(uint(dms.status()), 0); // Status.Active = 0
    }

    // ✅ Test 2: triggerGracePeriod()
    function test_triggerGracePeriod() public {
        // Fast forward 1 hour + 1 second
        vm.warp(block.timestamp + 3601);
        dms.triggerGracePeriod();
        assertEq(uint(dms.status()), 1); // Status.GracePeriod = 1
    }

    // ✅ Test 3: claim()
    function test_claim() public {
        // Add beneficiary
        vm.prank(owner);
        dms.addBeneficiary(beneficiary1, 100);

        // Deposit ETH
        vm.prank(owner);
        dms.deposit{value: 1 ether}();

        // Skip past check-in window
        vm.warp(block.timestamp + 3601);
        dms.triggerGracePeriod();

        // Skip past grace period
        vm.warp(block.timestamp + 1801);
        dms.claim();

        // Check status is Triggered
        assertEq(uint(dms.status()), 2); // Status.Triggered = 2

        // Check beneficiary received ETH
        assertEq(beneficiary1.balance, 1 ether);
    }

    // ✅ Test 4: cancel()
    function test_cancel() public {
        // Deposit ETH
        vm.prank(owner);
        dms.deposit{value: 1 ether}();

        uint256 balanceBefore = owner.balance;

        // Cancel as owner
        vm.prank(owner);
        dms.cancel();

        // Check status is Cancelled
        assertEq(uint(dms.status()), 3); // Status.Cancelled = 3

        // Check owner got ETH back
        assertEq(owner.balance, balanceBefore + 1 ether);
    }

    // ✅ Test 5: time-based test with vm.warp
    function test_cannotTriggerBeforeDeadline() public {
        // Only 30 minutes passed — should fail
        vm.warp(block.timestamp + 1800);
        vm.expectRevert("Not overdue yet");
        dms.triggerGracePeriod();
    }
}