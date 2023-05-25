# Solution
UnstoppableVault 是一个存储DVT token的金库合约，实现了ERC4626 IERC3156FlashLender协议
ReceiverUnstoppable 是触发闪电贷的合约，需要执行闪电贷的回调还款逻辑
## ERC4626
ERC4626合约采用了Valut创建过程，并将其标准化，支持多签，包含以下资产概念：
- asset：valut管理的底层资产代币
- share：valut的股权代币，在铸造/存取款/赎回时与资产都有一定的比率兑换，通过股权的比例来分摊金库资产

## IERC3156FlashLender & IERC3156FlashBorrower
IERC3156FlashLender是由以太坊ERC3156定义的闪电借贷器接口
主要包括以下函数：
- maxFlashLoan(): 返回对应token可闪电贷的最大数量，如果对应token不支持闪电贷，那么返回0

- flashFee（）返回对应token闪电贷金额所需要收取的手续费

- flashLoan(): 用来接收闪电借贷请求。借贷方需要在此函数里实现还款逻辑,该函数必须包括对IERC3156FlashBorrower合约中onFlashLoan（）的回调

```solidity
interface IERC3156FlashBorrower { 
    function onFlashLoan( 
        address initiator, 
        address token, 
        uint256 amount, 
        uint256 fee, 
        bytes calldata data 
    ) external returns (bytes32); 
}
```

## 攻击方法
重点看UnstoppableVault实现IERC3156FlashLender的`flashLoan`方法
- receiver：触发闪电贷的合约地址（实现IERC3156FlashBorrower协议）
- _token: 闪电贷的目标资产
- amount：目标闪电贷金额
- data: 执行参数
```solidity
    /**
     * @inheritdoc IERC3156FlashLender
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address _token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        if (amount == 0) revert InvalidAmount(0); // 校验amount
        if (address(asset) != _token) revert UnsupportedCurrency(); // 校验闪电贷的目标资产与金库内的资产是否一致
        uint256 balanceBefore = totalAssets(); // 获取当前资产总额
        if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); // 判断当前股权数是否与总金额一致（股权与资产1:1）
        uint256 fee = flashFee(_token, amount); // 计算闪电贷的费用
        // transfer tokens out + execute callback on receiver
        ERC20(_token).safeTransfer(address(receiver), amount); // 执行闪电贷预先转款
        // callback must return magic value, otherwise assume it failed
        if (receiver.onFlashLoan(msg.sender, address(asset), amount, fee, data) != keccak256("IERC3156FlashBorrower.onFlashLoan")) // 调用onFlashLoan 执行闪电贷操作
            revert CallbackFailed();
        // pull amount + fee from receiver, then pay the fee to the recipient
        ERC20(_token).safeTransferFrom(address(receiver), address(this), amount + fee); // 还款到本金库
        ERC20(_token).safeTransfer(feeRecipient, fee); // 还款到recipient合约
        return true;
    }
```

重点看方法内的这一判断条件：
`if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance();`

- `balanceBefore`由`totalAssets()`计算得出，是记录的当前合约持有的ERC20即DVT Token数目
- `totalSupply`为DVT Token的ERC20合约方法

这里约束的条件是asset与share 1:1，只有用户存入asset时才会`_mint`出相应的share，取出时`_burn`


