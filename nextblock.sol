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

    event BetReceived(address sender, uint256 value, uint256 balance);
    event GivingBackTheRest(address sender, uint256 value, uint256 rest);
    event BetExecuted(address sender, uint256 bet, uint256 value);
    event Balance(uint256 value);
    event LogStr(string value);
    event JackPot(address winner);
    event LogMiner(address miner);
    event LogUint(uint256 value);

    //If this is set to false contract will not receive funds
    bool isBetEnabled = true;
    //How many guesses you will need in a row to win and get money.
    uint8 public requiredGuessCount = 1;
    //How many percent can take owners from every win.
    uint8 public ownerProfitPercent = 10;
    //Next Jackpot starting balance percent
    uint8 public nextJackpotBalancePercent = 20;
    //Bonus reward for same(jackpot) block beters
    uint8 public bonusRewardPercent = 10;
    //Winners Jackpot percent
    uint8 public winnersJackpotPercent = 60;
    //Exacly how much percent of available balance you can bet. Neither less nor more.
    //If you bet more contract will give you back the rest. If less transaction will be reverted.
    uint256 public allowedBetAmount = 10000000000000000; // 0.01 ETH
    //Map of guesses, here is stored who how many time guessed.
    //After every wrong guess counter goes to 0.
    uint256 public blockedBalance = 0;

    // Players struct
    struct PlayerData {
        uint256 balance;
        uint256[] winningBlocks;
    }
    // Players data
    mapping(address => PlayerData) public PlayersData;

    mapping(address => uint8) public playersGuessCounts;
    //Wining Table stores everything to execute win and give reward everywon who won.
    struct WiningTable {
        bool isCalled;
        bool executed;
        uint256 balance;
        address[] jackPotWinners;
        address[] blockBetters;
    }

    //Winners Mapping
    mapping (uint256 => WiningTable) public wTables;


    //Contract owner address
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier notLess() {
        require(msg.value >= allowedBetAmount);
        _;
    }

    modifier notMore() {
        if(msg.value > allowedBetAmount) {
            GivingBackTheRest(msg.sender, msg.value, msg.value - allowedBetAmount);
            msg.sender.transfer(msg.value - allowedBetAmount);
        }
        _;
    }

    modifier onlyWhenBetIsEnabled() {
        require(isBetEnabled);
        _;
    }

    modifier onlyWhenGuessed(address miner) {
        if(block.coinbase == miner){
            _;
        }else{
            if(playerExistsInGuesCountMap(msg.sender)) {
                playersGuessCounts[msg.sender] = 0;
            }
        }
    }

    function TheNextBlock() public {
        owner = msg.sender;
        LogStr("Congratulations Contract Created!");
    }

    //This is left for donations
    function () public payable { }

    function playerExistsInGuesCountMap(address player) public view returns(bool) {
        return playersGuessCounts[player] != address(0x0);
    }

    function placeBet(address _miner)
        public
        payable
        onlyWhenBetIsEnabled
        notLess
        notMore
        onlyWhenGuessed(_miner) {
            BetReceived(msg.sender, msg.value, this.balance);
            LogMiner(block.coinbase);
            playersGuessCounts[msg.sender] += 1;
            // if player reached winning count
            if(playersGuessCounts[msg.sender] == requiredGuessCount) {
                LogUint(wTables[block.number].balance);
                if(wTables[block.number].balance == 0 ) {
                    LogStr("First Jackpot Winner !!! ");
                    wTables[block.number].executed = false;
                    wTables[block.number].balance = this.balance - blockedBalance;
                    wTables[block.number].jackPotWinners.push(msg.sender);
                    blockedBalance += this.balance - blockedBalance;
                } else {
                    LogStr("First Jackpot Winner !!! ");
                    wTables[block.number].jackPotWinners.push(msg.sender);
                }

                // reset winners count
                playersGuessCounts[msg.sender] = 0;


                //Here contracts needs to make call to itself which will be executed in next block.
                //Call is made to a function which will execute wining table and send funds.
                if(!wTables[block.number].isCalled) {
                    wTables[block.number].isCalled = true;
                    LogStr('call execute Function');
                    //address(this).call(bytes4(sha3("executeWinnigTable(uint256)")), block.number);
                    executeWinnigTable(block.number);
                }
            }
    }

    function executeWinnigTable(uint256  blockNumber) public {

        LogUint(block.number);
        LogStr("Executing Winning Function .....");

        if(wTables[blockNumber].executed == false) {

            WiningTable memory winningTable = wTables[blockNumber];

            LogStr("Log Calculations ");

            uint256 balance = winningTable.balance;
            uint256 houseProfit = (balance * ownerProfitPercent)/100;
            LogUint(houseProfit);
            uint256 nextJackpotBalance = (balance * nextJackpotBalancePercent)/100;
            LogUint(nextJackpotBalance);
            uint256 jackPotWinnerAmount = (balance - houseProfit - nextJackpotBalance) / winningTable.jackPotWinners.length;
            LogUint(jackPotWinnerAmount);

            for(uint256 i=0; i < winningTable.jackPotWinners.length; i++ ) {
                LogUint(jackPotWinnerAmount);
                PlayersData[winningTable.jackPotWinners[i]].balance += jackPotWinnerAmount;
            }

            blockedBalance -= winningTable.balance;
        }
    }

    function getJackpotWinnersByBlockNumber(uint256 blockNumber) public view returns(address[]) {
        return wTables[blockNumber].jackPotWinners;
    }


    function getBalance() public view returns(uint256) {
        return this.balance;
    }

}
