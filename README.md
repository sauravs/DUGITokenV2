## DugiToken : An ERC20 Compliant Token

**DugiToken - ERC20 Compliant Token created for Sgadugi Community to support the community and charity events.Token will be used in POS system in casinos**

**Important Details about this token:**

-   **Total Maximum Supply**:  21 Trillion
-   **Token Name**: Dugi Token
-   **Token Symbol**: DUGI
-   **Token Decimals**: 18
-   **Burning Mechanism**: YES


## Burning Details

- Every 30 days approximately 0.0714% of maximum supply (15 billion token per month) will be burn from BurnToken Reserve for next 35 years till BurnToken reserve reaches to zero .
- **BurnToken Reserve**:  10% of Total Maximum Supply (21 Trillion)
                       : 2.1 Trillion



### To run Tests

```shell
$ clone the repo
$ install foundry
$ forge build
$ forge test
```


### Deploy

```shell
$ forge script script/DeployDugiToken.s.sol:DeployDugiToken --rpc-url $POLYGON_AMOY_RPC_URL
$ forge script script/DeployDugiToken.s.sol:DeployDugiToken --rpc-url $POLYGON_AMOY_RPC_URL --broadcast --verify -vvvv

$ forge script script/DeployDugiToken.s.sol:DeployDugiToken --rpc-url $POLYGON_MAINNET_RPC_URL
$ forge script script/DeployDugiToken.s.sol:DeployDugiToken --rpc-url $POLYGON_MAINNET_RPC_URL --broadcast -vvvv
```

  ### To verify deployed contract:
     ```
	  $ forge verify-contract <contract_address> <contract_name> --chain-id <80002> --etherscan-api-key $<AMOY_POLYGONSCAN_KEY> --constructor-args <ABI_ENCODED_CONSTRUCTOR_ARGS> --watch

    forge verify-contract <contract_address> <contract_name> --chain-id <80002> --etherscan-api-key $<AMOY_POLYGONSCAN_KEY> --constructor-args <ABI_ENCODED_CONSTRUCTOR_ARGS> --watch
    ```



