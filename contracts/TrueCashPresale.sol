// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrueCashPresale is Ownable {
    IERC20 public truecash;
    enum Phase { CLOSED, PHASE1, PHASE2 }
    Phase public currentPhase = Phase.CLOSED;

    // Fixed Rates: How many TRUECASH per 1 BNB
    uint256 public constant PHASE1_RATE = 100000; // 1 BNB = 100,000 TCASH
    uint256 public constant PHASE2_RATE = 66666;  // 1 BNB = 66,666 TCASH

    uint256 public totalBnbRaised;
    uint256 public totalTokensSold;

    event TokensPurchased(address indexed buyer, uint256 bnbSpent, uint256 tokensReceived);
    event PhaseChanged(Phase newPhase);

    constructor(address _truecash) Ownable(msg.sender) {
        truecash = IERC20(_truecash);
    }

    function setPhase(Phase _phase) external onlyOwner {
        currentPhase = _phase;
        emit PhaseChanged(_phase);
    }

    function buyTokens() external payable {
        require(currentPhase != Phase.CLOSED, "Presale is currently closed");
        require(msg.value > 0, "Must send BNB");

        uint256 rate = (currentPhase == Phase.PHASE1) ? PHASE1_RATE : PHASE2_RATE;
        
        // Calculate TRUECASH amount to give to user
        // msg.value is in wei (18 decimals), and TCASH has 18 decimals.
        // So (msg.value * rate) yields the correct TCASH in wei.
        uint256 tokensToGive = msg.value * rate;

        require(truecash.balanceOf(address(this)) >= tokensToGive, "Not enough TRUECASH in presale contract");

        // Transfer TRUECASH to buyer
        require(truecash.transfer(msg.sender, tokensToGive), "TRUECASH transfer failed");

        totalBnbRaised += msg.value;
        totalTokensSold += tokensToGive;

        emit TokensPurchased(msg.sender, msg.value, tokensToGive);
    }

    // Owner can withdraw the BNB raised to seed the liquidity pool
    function withdrawBNB() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No BNB to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "BNB transfer failed");
    }

    // Owner can withdraw unsold tokens when presale ends
    function withdrawUnsoldTokens() external onlyOwner {
        uint256 balance = truecash.balanceOf(address(this));
        require(balance > 0, "No TRUECASH left");
        truecash.transfer(owner(), balance);
    }
}
