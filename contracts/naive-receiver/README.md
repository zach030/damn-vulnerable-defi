# Solution
## Background
FlashLoanReceiver实现了IERC3156FlashBorrower协议，定义了`inFlashLoan`方法，可以触发闪电贷作为回调

NaiveReceiverLenderPool实现了IERC3156FlashLender接口，支持支持闪电贷

测试脚本首先部署了NaiveReceiverLenderPool，并向合约转账`ETHER_IN_POOL (1000eth)`，均可用于闪电贷，见`maxFlashLoan`方法
```solidity
    function maxFlashLoan(address token) external view returns (uint256) {
        if (token == ETH) {
            return address(this).balance;
        }
        return 0;
    }
```

再部署FlashLoanReceiver合约，并向该合约转账`ETHER_IN_RECEIVER (10eth)`

在执行待填写代码之后，需要使得FlashLoanReceiver合约的余额为0，NaiveReceiverLenderPool合约的余额为:1000+10 eth