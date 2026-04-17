// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Import OpenZeppelin libraries
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Bcsecs
import "@openzeppelin/contracts/access/Ownable.sol"; // OnlyOwner
import "@openzeppelin/contracts/security/Pausable.sol"; // to push code in BUG

contract QandellToken is ERC20, Ownable, Pausable {

    // Events - record important actions on blockchain
    event TaxCollected(address indexed from, uint256 amount);
    event TaxWalletChanged(address indexed newTaxWallet);
    event TaxFeeChanged(uint256 newFee);

    // Variables
    uint256 public taxFee = 5;          // 5% tax on transfers
    address public taxWallet;           // Wallet that receives tax

    //maxWalletAmoun
    uint256 public maxAmount = 20000 * 10 ** decimals();


    // Constructor - runs once when deployed
    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
        Ownable(msg.sender)
    {
        taxWallet = msg.sender;         // Set tax wallet to owner
        _mint(msg.sender, 10000000 * 10 ** decimals()); // Mint 10M tokens
    }

    // Hook - runs on every transfer
    function _update(address from, address to, uint256 value) internal override whenNotPaused {

        // max amount function
        if (to != owner()){
            require(
                balanceOf(to) + value <= maxAmount, 
                "Anti whale: max wallet"
            );
        }
        
        // Apply tax only on normal transfers (not mint/burn/owner)
        if (from != address(0) && to != address(0) && from != owner()) {
            
            uint256 tax = (value * taxFee) / 100;      
            uint256 sendAmount = value - tax;   
            
            super._update(from, taxWallet, tax); 
            super._update(from, to, sendAmount); 
            
            emit TaxCollected(from, tax);       
            
        } else {
            super._update(from, to, value);
        }
    }

    // Sys to push the contruct with opeenzepling
    function offContracts() public onlyOwner{
        _pause();
    }
    function onContracts() public onlyOwner{
        _unpause();
    }

    // Owner can change tax percentage (max 10%)
    function setTaxFee(uint256 newFee) public onlyOwner {
        require(newFee <= 10, "Max is 10%");
        taxFee = newFee;
        emit TaxFeeChanged(newFee);
    }

    // Owner can change tax wallet
    function setTaxWallet(address newTaxWallet) public onlyOwner {
        taxWallet = newTaxWallet;
        emit TaxWalletChanged(newTaxWallet);
    }

    // Owner can mint new tokens
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}