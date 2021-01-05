pragma solidity 0.5.16;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/ownership/Ownable.sol";
import "./FlashMintableERC20.sol";

contract Borrower is Ownable {

    FlashERC20 fERC20 = FlashERC20(address(0x0)); // address of FlashERC20 contract

    function beginFlashMint(uint256 amount) public onlyOwner {
        fERC20.flashMint(amount);
    }

    function executeOnFlashMint(uint256 amount) external {
        require(msg.sender == address(fERC20), "only FlashERC20 can execute");

        // When this executes, this contract will have `amount` more fERC20 tokens.
        // Do whatever you want with those tokens here.
        // You can even redeem them for the underlying by calling `fERC20.withdraw(someAmount)`
        // But you must make sure this contract holds at least `amount` fERC20 tokens before this function
        // finishes executing or else the transaction will be reverted by the `FlashERC20.flashMint` function.
    }
}
