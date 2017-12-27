# TheNextBlock
## About the project
This is small dapp using ethereum smart contract and web3.
You must guess who will mine your transaction, if you guess required times in a row 
to win jackpot and take available balance on contract. If you fail your bet will go to balance and you start over.

## Connect our private network.

* 1. Genessis JSON File: gennesis.json

``` javascript
{
    "config": {
        "chainId": 577,
        "homesteadBlock": 0,
        "eip155Block": 0,
        "eip158Block": 0
    },
    "difficulty": "2000",
    "gasLimit": "8000029",
	"alloc" :  {}
}
```

* 2. Initialize Geth 

    ``` geth --datadir=./data init genessis.json ```



* 3. Run Geth 

    ~~~
    ./geth --fast --networkid=577  --shh --rpc --rpcaddr "0.0.0.0" --rpcapi "eth,net,web3,admin,shh" --rpccorsdomain "*" --datadir "data"  --ws --wsaddr "0.0.0.0" --wsapi "eth,net,web3,admin,shh" --wsorigins "*" --bootnodes "enode://3f67339af516a7ce62df1fd5e07e1ea9d173e5ad21a4ee021853f3da900e938707284b119d46df31608e5eaae3493591bf729cd210a2351188393819bb879dd7@13.95.67.47:30303" console
    ~~~

* start mining 
``` miner.start(1)```
