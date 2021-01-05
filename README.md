# Flashloan and Flash-mintable Asset-backed Tokens

"Anyone can be rich for an instant." or "Perfect credit from atomicity."



## Warning

The contracts are simple but have not been audited. Be careful.

## What are flash-mintable tokens (FMTs)?

Flash-mintable token (FMTs) are ERC20-compliant tokens that allow _flash minting_: the ability for anyone to mint an arbitrary number of new tokens into their account, as long as they also burn the same number of tokens from their account before the end of the same transaction.

A minimal example FMT can be seen here:

```
pragma solidity 0.5.16;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";

interface IBorrower {
    function executeOnFlashMint(uint256 amount) external;
}

contract FlashMintableToken is ERC20 {

    function flashMint(uint256 amount) public {
        // mint tokens
        _mint(msg.sender, amount);

        // hand control to borrower
        IBorrower(msg.sender).executeOnFlashMint(amount);

        // burn tokens
        _burn(msg.sender, amount); // reverts if `msg.sender` does not have enough units of the FMT
    }

}
```

Any contract that implements the `IBorrower` interface can mint as many FMTs as they want, use them however they want (e.g.: for arbitrage or liquidating CDPs), so long as the same number of FMTs get burned from their account by the end of the transaction.

You can think of FMTs as "credit tokens". Flash-minting FMTs is like "running up a tab", and burning the tokens at the end of the transaction is "paying off your tab". If you don't pay off your tab by the end of the transaction, then the transaction is reverted, and it is as if you never ran up a tab to begin with.

Flash-minting is a powerful idea, but only if the tokens themselves have some value.

## What are asset-backed tokens?

Asset-backed tokens are ERC20-compliant tokens that are 1-to-1 backed and trustlessly redeemable for some other asset. The canonical example is Wrapped Ether (WETH).

Here is a minimal example of an asset-backed token (this is equivalent to WETH):

```
pragma solidity 0.5.16;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        _burn(msg.sender, wad);
        msg.sender.transfer(wad);
    }
}
```

As you can see, anyone can send an asset (ETH in this case) to the contract and receive one WETH token in return. The WETH token can be transferred and sold to anyone, just like any other ERC20 token.

More importantly, anyone who holds a WETH token can instantly and trustlessly redeem it for one ETH by sending it back to the contract. This is what makes WETH an asset-backed token.

The most important thing to know about asset-backed tokens is that **they have exactly the same market value as their underlying asset**. One WETH will always be worth exactly one ETH, and vice versa.

## Flash-mintable asset-backed tokens

A flash-mintable asset-backed token is exactly what it sounds like: an ERC20-compliant token that is:

1. Asset-backed, so everyone can accept them at full face value knowing that they can always trustlessly redeem them for the underlying asset.

2. Flash-mintable, so anyone can mint arbitrarily many unbacked-tokens and spend them at full face value, so long as they destroy all the unbacked tokens (and therefore restore the backing) before the end of the transaction.


Here is a minimal example using ETH as the underlying asset:

```
pragma solidity 0.5.16;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/token/ERC20/ERC20.sol";

interface IBorrower {
    function executeOnFlashMint(uint256 amount) external;
}

contract BasicFlashWETH is ERC20 { // Flash-mintable WETH (fWETH)

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        _burn(msg.sender, wad);
        msg.sender.transfer(wad);
    }

    function flashMint(uint256 amount) public {
        // mint tokens
        _mint(msg.sender, amount);

        // hand control to borrower
        IBorrower(msg.sender).executeOnFlashMint(amount);

        // burn tokens
        _burn(msg.sender, amount); // reverts if `msg.sender` does not have enough fWETH

        // txn can never succeed unless all tokens are fully backed by ETH
        assert(address(this).balance >= totalSupply());
    }

}
```

Notice that it is impossible for a transaction to end with any fWETH tokens being unbacked by ETH.

This means that the only time the fWETH are ever unbacked is during the execution of a `flashMint`. To see that the fWETH tokens maintain their market value even during a `flashMint` -- when they are not all backed by ETH -- consider the following thought experiment.

Suppose you receive an fWETH token during a `flashMint` and consider the following cases:

#### Case 1: You try to redeem the fWETH during the `flashMint`
If you try to redeem the fWETH for ETH by calling `withdraw()` during the execution of `flashMint` one of two things will happen:

##### Case 1a: Your redeem succeeds
If your attempt succeeds then you got exactly what the fWETH was worth (1 ETH). No problem here.

##### Case 1b: Your redeem fails
Then the transaction will revert, and it will be as though you never received the fWETH in the first place. No harm done. You are not left "holding a bag".

#### Case 2: You do not try to redeem the fWETH during the `flashMint`
If you do not try to redeem the fWETH for ETH during the same `flashMint` transaction, then either:

##### Case 2a: The `flashMint` transaction goes on to succeed
If the `flashMint` goes on to succeed, then the unbacked tokens all got burned, and so the fWETH token you are holding is fully backed. No problem here.

##### Case 2b: The `flashMint` transaction goes on to fail
If the `flashMint` goes on to fail, then the transaction will be reverted, and it will be as though you never accepted the fWETH to begin with. No harm done.


In short, everyone can always accept fWETH at full face value because either it is instantly redeemable for ETH whenever they want, or else the EVM will revert and they'll have never accepted it in the first place.

## Why integrate `FlashWETH` into your project?
Imagine if *all* of your users where whales.

Integrating `FlashWETH` into your project lets all of your users act like whales. They can have access to as much money as they need to do whatever they want on your platform. If your project makes fees on volume, this is a no-brainer.

Instead of sending them off to some flash-lending pool somewhere, you can serve them directly. Save them gas and fees. Give them access to a virtually unbounded amount of money. Completely remove their dependence on third-party flash-lending platforms.

Other platforms are using the "trustlessness of atomicity" to extend credit to your users via flash-loans, often charging them for the privilege. You can cut out those middlemen and give your users credit directly. And you can do it with no additional code. All you have to do is accept fWETH the same way you already accept WETH.

Note that fWETH doesn't require liquidity pools like flash-loans do. Anything users can do on your platform using a $100M flash-loan from a third-party, they can also do using fWETH once you've integrate it -- even if the `FlashWETH` contract isn't holding very much ETH. Flash-mintable asset-backed tokens are _powerful_.

## How to integrate `FlashWETH` into your project

The `FlashWETH` contract has been made to be a drop-in replacement for Wrapped Ether. If your project already has support for WETH you can use the exact same code for `FlashWETH`. The APIs are exactly the same. You do not need to make any modifications to your code. Just point to the `FlashWETH` contract instead of the `WETH9` contract.

If you want to use an ERC20 token as the asset that backs the token, check out the `FlashERC20` contract.

