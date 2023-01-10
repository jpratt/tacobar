pragma solidity 0.8.11;

contract DailyReturns {
    // struct to hold user account information
    struct User {
        address referrer;
        uint256 initialDeposit;
        uint256 lastCompoundTime;
        uint256 rewards;
        bool isEligibleForRewards;
    }

    // mapping to hold user account information
    mapping(address => User) public users;

    // salsa pool information
    address payable salsaPool;
    mapping(address => uint256) public salsaShares;

    // lottery information
    address lotteryWinner;
    uint256 lotteryPool;
    uint256 lotteryTicketPrice;

    constructor() public {
        salsaPool = address(0x0);
        lotteryTicketPrice = 10 ether;
    }

    // function to deposit funds and set referrer if applicable
    function deposit(address payable _referrer) public payable {
        // get user account information
        User storage user = users[msg.sender];

        // if user has no initial deposit, set referrer and initial deposit
        if (user.initialDeposit == 0) {
            user.referrer = _referrer;
            user.initialDeposit = msg.value;
        }

        // add deposit to user rewards
        user.rewards += msg.value * (1 - 0.03 - 0.03);

        // add referral bonus to referrer
        if (_referrer != address(0x0)) {
            User storage referrer = users[_referrer];
            referrer.rewards += msg.value * 0.03;
        }

        // add deposit to salsa pool
        salsaShares[msg.sender] += msg.value * 0.25;
    }

    // function to compound rewards
    function compound() public {
        // get user account information
        User storage user = users[msg.sender];

        // check if user is eligible for compounding
        if (user.isEligibleForRewards && user.lastCompoundTime + 24 hours <= now) {
            // add rewards to deposit
            user.initialDeposit += user.rewards;

            // reset rewards and update last compound time
            user.rewards = 0;
            user.lastCompoundTime = now;
        }
    }

    // function to withdraw rewards
    function withdraw() public {
        // get user account information
        User storage user = users[msg.sender];

        // check if user is eligible for withdrawal
        if (user.isEligibleForRewards && user.lastCompoundTime + 30 hours <= now) {
            // transfer rewards to user
            require(user.rewards > 0, "No rewards to withdraw.");
            msg.sender.transfer(user.rewards);

            // reset rewards and set ineligibility for rewards
            user.rewards = 0;
            user.isEligibleForRewards = false;
        }
    }

    function AddSalsa() public payable {
        require(msg.value > 0, "Invalid deposit amount.");
        salsaPool.transfer(msg.value);
    }

      
    function distributionSalsa() public {
        require(salsaPool.balance > 0, "No rewards to distribute.");

        // calculate total shares in salsa pool
        uint256 totalShares = 0;
        for (address user in salsaShares) {
            totalShares += salsaShares[user];
        }

        // distribute rewards to users
        for (address user in salsaShares) {
            uint256 share = salsaShares[user] / totalShares;
            uint256 rewards = salsaPool.balance * share;
            users[user].rewards += rewards;
            salsaShares[user] = 0;
        }

        // transfer 1% of rewards to owner's wallet
        address owner = msg.sender;
        owner.transfer(salsaPool.balance * 0.01);
        salsaPool.transfer(salsaPool.balance * 0.99);
    }

    // function to buy lottery ticket
    function buyLotteryTicket() public payable {
        require(msg.value == lotteryTicketPrice, "Invalid ticket price.");

        // add ticket price to lottery pool
        lotteryPool += msg.value;

        // if lottery pool has enough tickets for a draw
        if (lotteryPool >= 10 * lotteryTicketPrice) {
            // select winner
            lotteryWinner = address(uint160(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % lotteryPool);

            // transfer winnings to winner
            lotteryWinner.transfer(lotteryPool / 2);

            // reset lottery pool
            lotteryPool = 0;
        }
    }
}
