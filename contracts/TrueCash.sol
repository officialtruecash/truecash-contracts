// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrueCash is ERC20, ERC20Permit, Ownable {
    mapping(address => bool) private _blacklist;
    
    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);
    
    constructor() ERC20("TrueCash", "TRUECASH") ERC20Permit("TrueCash") Ownable(msg.sender) {
        // Mint 10 Billion TCASH to the deployer (Treasury)
        _mint(msg.sender, 10_000_000_000 * 10 ** decimals());
    }
    
    /**
     * @dev Checks if an address is blacklisted.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }
    
    /**
     * @dev Adds an account to the blacklist. Only callable by owner.
     */
    function blacklist(address account) external onlyOwner {
        require(!_blacklist[account], "TrueCash: Account is already blacklisted");
        _blacklist[account] = true;
        emit Blacklisted(account);
    }
    
    /**
     * @dev Removes an account from the blacklist. Only callable by owner.
     */
    function unBlacklist(address account) external onlyOwner {
        require(_blacklist[account], "TrueCash: Account is not blacklisted");
        _blacklist[account] = false;
        emit UnBlacklisted(account);
    }
    
    /**
     * @dev Overrides the _update function to enforce the blacklist. 
     * Neither sender nor recipient can be blacklisted.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        require(!_blacklist[from], "TrueCash: Sender is blacklisted");
        require(!_blacklist[to], "TrueCash: Recipient is blacklisted");
        super._update(from, to, value);
    }
    
    /**
     * @dev Allows the protocol to burn tokens from its own treasury (e.g., for Adoption Milestone Burns).
     */
    function burnTreasury(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
