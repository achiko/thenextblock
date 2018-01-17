pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TheNextBlock {

    event BetReceived(address sender, uint256 value, address betOnMiner, address miner, uint256 balance);
    event GivingBackTheRest(address sender, uint256 value, uint256 rest);
    event Jackpot(address winner);
    event LogStr(string value);
    event LogUint(uint256 value);
    event LogAddress(address value);
    
    //Contract owner address
    struct Owner {
        uint256 balance;
        address addr;
    }
    
    
    Owner owner;
    //If this is set to false contract will not receive funds
    bool public isBetEnabled = true;
    //Exacly how much percent of available balance you can bet. Neither less nor more.
    //If you bet more contract will give you back the rest. If less transaction will be reverted.
    uint256 public allowedBetAmount = 10000000000000000; // 0.01 ETH
    //How many guesses you will need in a row to win and get money.
    uint8 public requiredGuessCount = 2;
    //How many percent can take owners from every win.
    uint8 public ownerProfitPercent = 10;
    //Winners Jackpot percent
    uint8 public jackpotPercent = 90;
    //Here will be accumulated jackpot
    uint256 pot = 0;
    // Players struct
    struct Player {
        uint256 balance;
        uint256[] wonBlocks;
    }
    // Players data
    mapping(address => Player) private playersStorage;
    // Counter for players guesses
    mapping(address => uint8) private playersGuessCounts;
    
    modifier onlyOwner() {
        require(msg.sender == owner.addr);
        _;
    }

    modifier notLess() {
        require(msg.value >= allowedBetAmount);
        _;
    }

    modifier notMore() {
        if(msg.value > allowedBetAmount) {
            GivingBackTheRest(msg.sender, msg.value, msg.value - allowedBetAmount);
            msg.sender.transfer( SafeMath.sub(msg.value, allowedBetAmount) );
        }
        _;
    }
    
    modifier onlyWhenBetIsEnabled() {
        require(isBetEnabled);
        _; 
    }
    
    function safeGetPercent(uint256 amount, uint8 percent) private pure returns(uint256) {
        // ((amount - amount%100)/100)*percent
        return SafeMath.mul( SafeMath.div( SafeMath.sub(amount, amount%100), 100), percent);
    }
    
    function TheNextBlock() public {
        owner.addr = msg.sender;
        LogStr("Congrats! Contract Created!");
    }

    //This is left for donations
    function () public payable { }

    function placeBet(address _miner) 
        public
        payable
        onlyWhenBetIsEnabled
        notLess
        notMore {
            
            BetReceived(msg.sender, msg.value, _miner, block.coinbase,  this.balance);

            owner.balance += safeGetPercent(allowedBetAmount, ownerProfitPercent);
            pot += safeGetPercent(allowedBetAmount, jackpotPercent);

            if(_miner == block.coinbase) {
                //Increase guess counter
                playersGuessCounts[msg.sender]++;
                //Jackpot
                if(playersGuessCounts[msg.sender] == requiredGuessCount) {
                    Jackpot(msg.sender);
                    
                    //Store players lucky blocks.
                    playersStorage[msg.sender].wonBlocks.push(block.number);

                    if(pot >= allowedBetAmount) {
                        //Give money to player
                        playersStorage[msg.sender].balance += pot;
                        //Empty everything
                        pot = 0;
                        playersGuessCounts[msg.sender] = 0;
                    } else {
                        //Decrease by one if player won and contract has nothing to give.
                        //This is required for game to be fair.
                        playersGuessCounts[msg.sender]--;
                    }
                }
            } else {
                //Reset on lose
                playersGuessCounts[msg.sender] = 0;
            }
            
    }
    //This is duplicated functionality.
    //After choosing right style half will be deleted.
    function getPlayersBalance(address playerAddr) public view returns(uint256) {
        return playersStorage[playerAddr].balance;
    }
    
    function getPlayersGuessCount(address playerAddr) public view returns(uint8) {
        return playersGuessCounts[playerAddr];
    }
    
    function getPlayersWonBlocks(address playerAddr) public view returns(uint256[]) {
        return playersStorage[playerAddr].wonBlocks;
    }
    
    function getMyBalance() public view returns(uint256) {
        return playersStorage[msg.sender].balance;
    }
    
    function getMyGuessCount() public view returns(uint8) {
        return playersGuessCounts[msg.sender];
    }
    
    function getMyWonBlocks() public view returns(uint256[]) {
        return playersStorage[msg.sender].wonBlocks;
    }
    
    function withdrawMyFunds() public {
        uint256 balance = playersStorage[msg.sender].balance;
        if(balance != 0) {
            playersStorage[msg.sender].balance = 0;
            msg.sender.transfer(balance);
        }
    }
    
    function withdrawOwnersFunds() public onlyOwner {
        owner.addr.transfer(owner.balance);
        owner.balance = 0;
    }
    
    function getOwnersBalance() public view returns(uint256) {
        return owner.balance;
    }
    
    function getPot() public view returns(uint256) {
        return pot;
    }
    
    function getBalance() public view returns(uint256) {
        return this.balance;
    }
}
