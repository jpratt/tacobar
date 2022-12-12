solidity ^0.8.11;

contract DepositAndEarn {
  address public salsaTradingWallet;
  address public marketingWallet;
  mapping (address => uint256) public deposits;
  mapping (address => uint256) public earned;
  mapping (address => uint256) public lastCompoundTime;

  constructor(address _salsaTradingWallet, address _marketingWallet) public {
    salsaTradingWallet = _salsaTradingWallet;
    marketingWallet = _marketingWallet;
  }

  // User makes a deposit
  function deposit() public payable {
    // Calculate referral bonus
    address referrer = msg.sender.call(abi.encodePacked("referrer"));
    if (referrer != address(0)) {
      uint256 referralBonus = (deposits[msg.sender] * 3) / 100;
      referrer.transfer(referralBonus);
    }

    // Calculate development/marketing fee
    uint256 devMarketingFee = (msg.value * 3) / 100;
    marketingWallet.transfer(devMarketingFee);

    // Calculate trading fee
    uint256 tradingFee = (msg.value * 25) / 100;
    salsaTradingWallet.transfer(tradingFee);

    // Update user deposit and earned amounts
    deposits[msg.sender] += msg.value;
    earned[msg.sender] += (deposits[msg.sender] * 0.25) / 100;
  }

  /**
  TODO
  User compounds
   */
}