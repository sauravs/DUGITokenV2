// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {DUGITokenV2} from "../src/DugiTokenV2.sol";

contract DUGITokenV2Test is Test {
    DUGITokenV2 public token;
    address public owner = address(0x1e364a3634289Bc315a6DFF4e5fD018B5C6B3ef6);
    address public donationWallet;
    address public burnAdmin;
    address public contractDeployer;
    address public user1;
    address public user2;

    event TokensBurned(uint256 indexed amount, uint256 indexed timestamp, uint256 indexed burnCount);
    event TokenBurnAdminChanged(address indexed oldAdmin, address indexed newAdmin);

    function setUp() public {
        donationWallet = makeAddr("donationWallet");
        burnAdmin = makeAddr("burnAdmin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        contractDeployer = makeAddr("contractDeployer");

        vm.deal(contractDeployer, 1 ether);
        vm.startPrank(contractDeployer);
        token = new DUGITokenV2(donationWallet, burnAdmin);
        vm.stopPrank();
    }

    function test_InitialSetup() public {
        assertEq(token.name(), "DUGI Token");
        assertEq(token.symbol(), "DUGI");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
        assertEq(token.tokenBurnAdmin(), burnAdmin);
        assertEq(token.totalSupply(), token.MAX_SUPPLY());
    }

    function test_InitialDistribution() public {
        assertEq(token.balanceOf(donationWallet), (token.MAX_SUPPLY() * 5) / 100);
        assertEq(token.balanceOf(owner), (token.MAX_SUPPLY() * 85) / 100);
        assertEq(token.balanceOf(address(token)), (token.MAX_SUPPLY() * 10) / 100);
        assertEq(token.burnReserve(), (token.MAX_SUPPLY() * 10) / 100);
    }

    function testFail_ZeroAddressConstructor() public {
        vm.startPrank(contractDeployer);
        token = new DUGITokenV2(address(0), burnAdmin);
        vm.stopPrank();
    }

    function test_SetTokenBurnAdmin() public {
        vm.startPrank(owner);
        token.setTokenBurnAdmin(user1);
        assertEq(token.tokenBurnAdmin(), user1);
        vm.stopPrank();
    }


      function testFail_SetTokenBurnAdminNotOwner() public {
        vm.startPrank(user1);
        token.setTokenBurnAdmin(user2);
        vm.stopPrank();
    }




    function test_TransferOwnership() public {
        vm.startPrank(owner);
        token.transferOwnership(user1);
        assertEq(token.owner(), user1);
        vm.stopPrank();
    }

    function testFail_TransferOwnershipNotOwner() public {
        vm.startPrank(user1);
        token.transferOwnership(user2);
        vm.stopPrank();
    }

    function testFail_TransferOwnershipZeroAddress() public {
        vm.startPrank(owner);
        token.transferOwnership(address(0));
        vm.stopPrank();
    }


    function test_RenounceOwnership() public {
        vm.startPrank(owner);
        token.renounceOwnership();
        assertEq(token.owner(), address(0));
        vm.stopPrank();
    }

    function testFail_RenounceOwnershipNotOwner() public {
        vm.startPrank(user1);
        token.renounceOwnership();
        vm.stopPrank();
    }


    function test_Transfer() public {
        vm.startPrank(owner);
        token.transfer(user1, 1000);
        assertEq(token.balanceOf(user1), 1000);
        vm.stopPrank();
    }

   


    function test_TransferFrom() public {
        vm.prank(owner);
        token.approve(user1, 1000);
        vm.prank(user1);
        token.transferFrom(owner, user2, 1000);
        assertEq(token.balanceOf(user2), 1000);
    }

   



    function test_BurnFromReserve() public {
        vm.startPrank(burnAdmin);
        vm.warp(block.timestamp + 30 days);
        
        uint256 expectedBurnAmount = (token.MAX_SUPPLY() * 714) / 1_000_000;
        uint256 initialBurnReserve = token.burnReserve();
        
        token.burnFromReserve();
        
        assertEq(token.burnReserve(), initialBurnReserve - expectedBurnAmount);
        assertEq(token.burnCounter(), 1);
        assertTrue(token.burnStarted());
        vm.stopPrank();
    }

    // function testFail_BurnFromReserveNotAdmin() public {
    //     vm.startPrank(user1);
    //     vm.warp(block.timestamp + 30 days);
    //     token.burnFromReserve();
    //     vm.stopPrank();
    // }

    // function testFail_BurnIntervalNotReached() public {
    //     vm.startPrank(burnAdmin);
    //     token.burnFromReserve();
    //     vm.stopPrank();
    // }

    

  


    // function test_BurnCycle() public {
    //     vm.startPrank(burnAdmin);
        
    //     for(uint32 i = 0; i < token.TOTAL_BURN_SLOTS(); i++) {
    //         vm.warp(block.timestamp + 30 days);
    //         if(token.burnReserve() > 0) {
    //             token.burnFromReserve();
    //         }
    //     }
        
    //     assertTrue(token.burnEnded());
    //     vm.stopPrank();
    // }
}