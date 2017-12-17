pragma solidity ^0.4.19;

contract TheNextBlock {

    bool isBetEnabled = true; 

    //How many guesses you will need in a row to win and get money.
    uint8 public requiredGuessCount = 5;
    //How many percent owners take from every win.
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
    mapping(address => uint8) playersGuessCounts;
        
    struct Winner {
        address addr;
    }
    
    //Winners Mapping
    mapping (uint256 => Winner[] ) winners;
        
    event BetReceived(uint256 sender, uint256 value, uint256 balance);
    event BetIsLess(uint256 sender, uint256 value, uint256 balance);
    event BetIsMore(uint256 sender, uint256 value, uint256 balance);
    event GivingBackTheRest(address sender, uint256 value, uint256 rest);
    event BetExecuted(address sender, uint256 bet, uint256 value);
    event Balance(uint256 value);
    event Log(string value);
    event JackPot(address winner);
    event LogMiner(address miner);

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

    modifier betEnabled() { 
        require(isBetEnabled);
        _; 
    }
    
    
    function TheNextBlock() public {
        Log("Congratulations ");
    }


    function () public payable {
            
    }
    
    function placeBet(address _miner) 
        public 
        payable 
        betEnabled 
        notLess 
        notMore {
            
            LogMiner(block.coinbase);
            
            if(block.coinbase == _miner) {
                if(playersGuessCounts[msg.sender] != address(0x0) ) {
                    playersGuessCounts[msg.sender] += 1;
                    if(playersGuessCounts[msg.sender] == requiredGuessCount) {
                        winners[block.number].push(Winner(msg.sender));
                    }
                }  
            }else{
                if(playersGuessCounts[msg.sender] != address(0x0) ) {
                    playersGuessCounts[msg.sender] = 0;
                }
            }
    }

    function getBalance() public view returns(uint256) {
        return this.balance;
    }

}   