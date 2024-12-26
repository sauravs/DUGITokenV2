// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {DUGITokenV2} from "../../src/DugiTokenV2.sol";

contract FVTest is Test {

  DUGITokenV2 public token;

    address public owner = address(0x1e364a3634289Bc315a6DFF4e5fD018B5C6B3ef6);
    address public donationWallet = address(0x4921B6a8Ce3eF0c443518F964f9D06763823601E);
    address public burnAdmin = address(0xa5570A1B859401D53FB66f4aa1e250867803a408);

    address public userA = address(0x6);
    address public userB = address(0x7);
    address public newOwner = address(0x8);

    function setUp() public {
          token = new DUGITokenV2(donationWallet, burnAdmin);
    }



function check_transfer(address sender, address receiver, uint256 amount) public {
    // specify input conditions
    vm.assume(receiver != address(0));
    vm.assume(token.balanceOf(sender) >= amount);

    // record the current balance of sender and receiver
    uint256 balanceOfSender = token.balanceOf(sender);
    uint256 balanceOfReceiver = token.balanceOf(receiver);

    // call target contract
    vm.prank(sender);
    token.transfer(receiver, amount);

    // check output state
    assert(token.balanceOf(sender) == balanceOfSender - amount);
    assert(token.balanceOf(receiver) == balanceOfReceiver + amount);
}




