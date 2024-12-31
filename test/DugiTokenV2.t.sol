// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {DUGITokenV2} from "../src/DugiTokenV2.sol";

contract DUGITokenV2Test is Test {
    DUGITokenV2 public token;
    address public owner = address(0x8ffBF5c96AD55296E2A1Cac63DC512A94747bE9D);
    address public charityWallet;
    address public burnAdmin;
    address public contractDeployer;
    address public user1;
    address public user2;

    // variables related to permit function testing

    address public sender; // which will be used to sign the permit , he will not pay any gass fee
    address public relayerAccount; // account which will pay the gas fee from the behalf of sendert
    address public receiver; // account which is going to receive the tokens

    uint256 constant SENDER_PRIVATE_KEY = 111;

    event TokensBurned(uint256 indexed amount, uint256 indexed timestamp, uint256 indexed burnCount);
    event TokenBurnAdminChanged(address indexed oldAdmin, address indexed newAdmin);

    function setUp() public {
        charityWallet = makeAddr("charityWallet ");
        burnAdmin = makeAddr("burnAdmin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        contractDeployer = makeAddr("contractDeployer");

        receiver = makeAddr("receiver");
        relayerAccount = makeAddr("relayerAccount");
        sender = vm.addr(SENDER_PRIVATE_KEY);

        vm.deal(contractDeployer, 1 ether);
        vm.startPrank(contractDeployer);
        token = new DUGITokenV2(charityWallet, burnAdmin);
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
        assertEq(token.balanceOf(charityWallet), (token.MAX_SUPPLY() * 5) / 100);
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

        (uint128 burnCounter,, bool burnStarted,) = token.burnState();

        assertEq(token.burnReserve(), initialBurnReserve - expectedBurnAmount);
        assertEq(burnCounter, 1);
        assertTrue(burnStarted);
        assertEq(token.totalSupply(), token.MAX_SUPPLY() - expectedBurnAmount);
        vm.stopPrank();
    }

    function testFail_BurnFromReserveNotAdmin() public {
        vm.startPrank(user1);
        vm.warp(block.timestamp + 30 days);
        token.burnFromReserve();
        vm.stopPrank();
    }

    function testFail_BurnIntervalNotReached() public {
        vm.startPrank(burnAdmin);
        token.burnFromReserve();
        vm.stopPrank();
    }

    function test_BurnCycle() public {
        vm.startPrank(burnAdmin);

        uint256 initialTotalSupply = token.totalSupply();
        uint256 initialBurnReserve = token.burnReserve();
        uint256 burnAmount = (token.MAX_SUPPLY() * 714) / 1_000_000;
        uint256 cumulativeBurned = 0;

        for (uint32 i = 0; i < token.TOTAL_BURN_SLOTS(); i++) {
            vm.warp(block.timestamp + 30 days);

            if (token.burnReserve() > 0) {
                uint256 preSupply = token.totalSupply();
                uint256 preBurnReserve = token.burnReserve();

                token.burnFromReserve();

                (uint128 burnCounter,,,) = token.burnState();

                uint256 actualBurned = preBurnReserve - token.burnReserve();
                cumulativeBurned += actualBurned;

                assertEq(actualBurned, burnAmount <= preBurnReserve ? burnAmount : preBurnReserve);
                assertEq(token.totalSupply(), preSupply - actualBurned);
                assertEq(burnCounter, i + 1);
            }
        }

        (,,, bool burnEnded) = token.burnState();
        assertTrue(burnEnded);
        assertEq(token.burnReserve(), 0);
        assertEq(token.totalSupply(), initialTotalSupply - initialBurnReserve);
        vm.stopPrank();
    }

    function testFuzz_BurnCycle(uint256 initialBurnReservePercentage, uint32 numBurnSlots, uint256 burnInterval)
        public
    {
        // bound inputs
        initialBurnReservePercentage = bound(initialBurnReservePercentage, 1, 100);
        numBurnSlots = uint32(bound(numBurnSlots, 1, token.TOTAL_BURN_SLOTS()));
        burnInterval = bound(burnInterval, 30 days, 365 days);

        vm.startPrank(burnAdmin);

        uint256 initialTotalSupply = token.totalSupply();
        uint256 initialBurnReserve = token.burnReserve();
        uint256 burnAmount = (token.MAX_SUPPLY() * 714) / 1_000_000;
        uint256 cumulativeBurned = 0;
        uint256 lastBurnTime = block.timestamp;

        (,,, bool isBurnEnded) = token.burnState();
        for (uint32 i = 0; i < numBurnSlots && !isBurnEnded; i++) {
            vm.warp(lastBurnTime + burnInterval);

            if (token.burnReserve() > 0) {
                uint256 preSupply = token.totalSupply();
                uint256 preBurnReserve = token.burnReserve();

                token.burnFromReserve();

                (uint128 burnCounter,,,) = token.burnState();
                uint256 actualBurned = preBurnReserve - token.burnReserve();
                cumulativeBurned += actualBurned;

                // Verify each burn operation
                assertTrue(actualBurned > 0 && actualBurned <= burnAmount);
                assertTrue(actualBurned <= preBurnReserve);
                assertEq(token.totalSupply(), preSupply - actualBurned);
                assertEq(burnCounter, i + 1);
            }

            lastBurnTime = block.timestamp;
            (,,, isBurnEnded) = token.burnState();
        }

        // verify final state
        assertTrue(token.totalSupply() <= initialTotalSupply);
        assertTrue(token.totalSupply() >= initialTotalSupply - initialBurnReserve);
        assertTrue(cumulativeBurned <= initialBurnReserve);

        if (numBurnSlots >= token.TOTAL_BURN_SLOTS()) {
            (,,, bool burnEnded) = token.burnState();
            assertTrue(burnEnded);
            assertEq(token.burnReserve(), 0);
        }

        vm.stopPrank();
    }

    function testFuzz_Transfer(uint256 amount) public {
        // bound amount to owner's balance
        amount = bound(amount, 0, token.balanceOf(owner));

        vm.startPrank(owner);
        uint256 ownerInitialBalance = token.balanceOf(owner);
        uint256 user1InitialBalance = token.balanceOf(user1);

        token.transfer(user1, amount);

        assertEq(token.balanceOf(owner), ownerInitialBalance - amount);
        assertEq(token.balanceOf(user1), user1InitialBalance + amount);
        vm.stopPrank();
    }

    function testFuzz_TransferFrom(uint256 amount, address sender, address recipient) public {
        // filter invalid addresses
        vm.assume(sender != address(0) && recipient != address(0));
        vm.assume(sender != recipient);

        // setup initial balance for sender
        vm.startPrank(owner);
        token.transfer(sender, token.MAX_SUPPLY() / 4);
        vm.stopPrank();

        // Bound amount to sender's balance
        amount = bound(amount, 0, token.balanceOf(sender));

        // Approve spender
        vm.startPrank(sender);
        token.approve(address(this), amount);
        vm.stopPrank();

        uint256 senderInitialBalance = token.balanceOf(sender);
        uint256 recipientInitialBalance = token.balanceOf(recipient);

        token.transferFrom(sender, recipient, amount);

        assertEq(token.balanceOf(sender), senderInitialBalance - amount);
        assertEq(token.balanceOf(recipient), recipientInitialBalance + amount);
        assertEq(token.allowance(sender, address(this)), 0);
    }

    function testFail_TransferFromInsufficientAllowance(uint256 amount) public {
        vm.assume(amount > 0);
        vm.startPrank(owner);
        token.approve(user1, amount - 1);
        vm.stopPrank();

        vm.prank(user1);
        token.transferFrom(owner, user2, amount);
    }

    function testFail_TransferInsufficientBalance(uint256 amount) public {
        amount = bound(amount, token.balanceOf(user1) + 1, type(uint256).max);
        vm.prank(user1);
        token.transfer(user2, amount);
    }

    function testPermitFunctionality() public {
        // setup permit parameters
        uint256 deadline = block.timestamp + 60;
        uint256 amount = 100;

        // fund sender with some DUGI Token

        vm.prank(owner);
        token.transfer(sender, 1000);

        assertEq(token.balanceOf(sender), 1000);

        // generate permit signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        sender,
                        relayerAccount,
                        amount,
                        token.nonces(sender),
                        deadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SENDER_PRIVATE_KEY, digest);

        // execute permit
        vm.prank(sender);
        token.permit(sender, relayerAccount, amount, deadline, v, r, s);

        // verify permit
        assertEq(token.allowance(sender, relayerAccount), amount);
        assertEq(token.nonces(sender), 1);

        // test transfer
        vm.prank(relayerAccount);
        token.transferFrom(sender, receiver, amount);

        // verify balances
        assertEq(token.balanceOf(receiver), amount);
        assertEq(token.balanceOf(sender), 1000 - amount);
    }
}
