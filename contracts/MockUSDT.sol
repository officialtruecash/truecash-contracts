// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDT is ERC20 {
    constructor() ERC20("Mock Tether", "USDT") {
        // Mint 1 Million USDT to deployer for testing
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    // Allow anyone to mint for testing purposes
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
