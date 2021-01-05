pragma solidity 0.5.16;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/ownership/Ownable.sol";
import "./FlashWETH.sol";

contract Borrower is Ownable {

    FlashWETH fWETH = FlashWETH(0xf7705C1413CffCE6CfC0fcEfe3F3A12F38CB29dA); // address of FlashWETH contract

    // required to receive ETH in case you want to `withdraw` some fWETH for real ETH during `executeOnFlashMint`
    function () external payable {}

    // call this function to fire off your flash mint
    function beginFlashMint(uint256 amount) public onlyOwner {
        fWETH.flashMint(amount);
    }

    // this is what executes during your flash mint
    function executeOnFlashMint(uint256 amount) external {
        require(msg.sender == address(fWETH), "only FlashWETH can execute");

        // When this executes, this contract will have `amount` more fWETH tokens.
        // Do whatever you want with those tokens here.
        // You can even redeem them for ETH by calling `fWETH.withdraw(someAmount)`
        // But you must make sure this contract holds at least `amount` fWETH before this function finishes executing
        // or else the transaction will be reverted by the `FlashWETH.flashMint` function.
    }
}