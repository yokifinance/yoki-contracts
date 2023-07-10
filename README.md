# Testnet and local usage

1. Setup your wallet and infura rpc inside `.env` file. Make sure you are using correct network since it will be cloned.

   [https://app.infura.io/dashboard](https://app.infura.io/dashboard)

2. Start docker
   `docker-compose up`

_optional_: In order to refetch latest chain state or fix any issues you can simply rebuild the container `docker-compose up --build`

It will start local testnet RPC on `http://localhost:8545` and deploy contracts to it. Provided .env mnemonic and address will be the owner of contracts as well as given 1000ETH for playtesting. _Don't forget to add and switch to local network in your metamask_.

Testnet provides fast minting (transactions are executed immediately instead of 10-15s). It is also a complete fork of existing network which means that you can test with real assets without affecting real chain state.

# Developing contracts

## Prerequisites

Forge and other foundry tools are required.
Foundry prerequisites can be installed using guide from here: https://book.getfoundry.sh/getting-started/installation

## Local testing

To run tests simply start
cmd: `forge test -vv`
to run specific test use test name from any test file:
ex: `forge test -vv --match-test test_retrieveFunds`

## Local network for tests

You can start local testnet via docker or cmd. Instruction below is how to setup working environment manually:

1. We need testnet RPC with a copy of mainnet.
   We will be using Infra for that cause: (Infra website)[https://app.infura.io/]

Make sure to enable Polygon network in your app settings (_in order to use polygon you will have to attach a credit card_, however it is free of charge)

2. Start local testnet as a fork
   `anvil -m "*your wallet mnemonic*" --fork-url https://polygon-mainnet.infura.io/*your infra api key here*`

We provide our private key so we can ahve access to USDT's on local chain for easier testing moving further. Alternatively - you can create a custom pool and distribute test tokens, but this scenario is up to you and moving forward it is assumed that you are using account with USDT's on mainnet.

You can test that you did everything correctly by running:
`cast interface 0xE592427A0AEce92De3Edee1F18E0157C05861564` - it should output the ABI of UniSwap

Don't forget to check USDT balance of your wallet
`cast call 0xc2132d05d31c914a87c6611c10748aeb04b58e8f "balanceOf(address)(uint256)" \*your wallet address\*`

## Deploy contract to testnet

Note: on local chain wallets will be saved between restarts, however - deployed contracts will not.

1. Compile source files
   `forge build`
   result can be found in "out" and "cache" folders.

2. Deploy DCAV3Factory to local node

0x59698022f08FF0d0B6EDbC956Fd9c0596543A983 - production whitelist contract
0xf52Aea45dFDE4669C73010D4C47E9e0c75E5c8ca - IDC Implementation (???)
`forge create DCAV3Factory --constructor-args 0x59698022f08FF0d0B6EDbC956Fd9c0596543A983 0xf52Aea45dFDE4669C73010D4C47E9e0c75E5c8ca --unlocked --from \*Testnet wallet address\* --rpc-url http://127.0.0.1:8545 --legacy`
Testnet wallet address can be found in output when started anvil. Notice that we need address, _not_ private key.

Don't forget to save deployed contract address somewhere.

Optional:
You can check contract being successfully deployed using
`case code \* contract address \*`
as long as response is not "0x" - contract successfully deployed
Alternatively - you can open logs in anvil and see contract creation transaction there

3. Factory a DCA contract
   WIP: code below doesn't work for me yet

Pay attention at parts that need to be replaced, marked with "{}" brackets.
`cast send {contract_address} --unlocked --from {user_address} "createDCA(address,(address,address,uint256,address,address,uint256))(address)" {user_address} "({user_address},{worker_address},{amount_to_spend},0xc2132D05D31c914a87C6611C10748AEb04B58e8F,0xb33EaAd8d922B1083446DC23f610c2567fB5180f,0)"`
example:
`cast send 0xb07BE8eE8D505245540a7d34De69C91A2A69D292 --unlocked --from 0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43 "createDCA(address,(address,address,uint256,address,address,uint256))(address)" 0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43 "(0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43,0x2F81b3BAFC24d174D370678EfDe14A69F43974Cc,2,0xc2132D05D31c914a87C6611C10748AEb04B58e8F,0xb33EaAd8d922B1083446DC23f610c2567fB5180f,0)"`

## Legend:

0xfbD8ba80BcCE20135ba46e0BC300533dFE9a2F3a - admin, who owns factory
0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43 - user, who will call exchanges
0x2F81b3BAFC24d174D370678EfDe14A69F43974Cc - worker, random address from anvil (will call swap commands)
0xb07BE8eE8D505245540a7d34De69C91A2A69D292 - contract address
"0xc2132D05D31c914a87C6611C10748AEb04B58e8F", # USDT contract address
"0xb33EaAd8d922B1083446DC23f610c2567fB5180f", # UNI contract address

`//                                                                                  newOwner                                    beneficiary                                executor                 singleSpendAmount  tokenToSpend(USDT)                          tokenToBuy(UNI)                            lastPurchaseTimestamp
// "createDCA(address,(address,address,uint256,address,address,uint256))(address)" 0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43 "(0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43,0x2F81b3BAFC24d174D370678EfDe14A69F43974Cc,2,0xc2132D05D31c914a87C6611C10748AEb04B58e8F,0xb33EaAd8d922B1083446DC23f610c2567fB5180f,0)"`

## Alternative method using remix

1. Add local network to metamask (127.0.0.1:8545)
2. Add abi from out/DCAV3Factory
3. Connect to contract deployed previously
4. Call "deployDCA"
   example input:
   `0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43`
   `["0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43", "0x2F81b3BAFC24d174D370678EfDe14A69F43974Cc",2,"0xc2132D05D31c914a87C6611C10748AEb04B58e8F","0xb33EaAd8d922B1083446DC23f610c2567fB5180f",0]`

## Now we can test locally deployed contract with metamask / FE app / cast / hardhat / etc.

# Deploy to production

TBD
