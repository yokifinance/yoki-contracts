# Testnet and local usage

1. Setup your wallet and infura rpc inside `.env` file. Make sure you are using correct network since it will be cloned.

   [https://app.infura.io/dashboard](https://app.infura.io/dashboard)

2. Start docker
   `docker-compose up`

_optional_: In order to refetch latest chain state or fix any issues you can simply rebuild the container `docker-compose up --build`

It will start local testnet RPC on `http://localhost:8545` and deploy contracts to it. Provided .env mnemonic and address will be the owner of contracts as well as given 1000ETH for playtesting. _Don't forget to add and switch to local network in your metamask_.

Testnet provides fast minting (transactions are executed immediately instead of 10-15s). It is also a complete fork of existing network which means that you can test with real assets without affecting real chain state.

# Deploy contracts

## Deploy

Rename `.env.example` to `.env` and setup env variables

Run

Production:
`RPS`

```
export $(grep -v '^#' .env | xargs)
forge script --rpc-url $RPC --chain-id $CHAIN_ID script/rps/All_Deploy.s.sol --broadcast --legacy --verify
```

`DCA polygon`


```
export $(grep -v '^#' .env | xargs)
forge script --rpc-url $RPC --chain-id $CHAIN_ID script/dca/networks/All_Deploy_Polygon.s.sol --broadcast --legacy --verify
```

`DCA optimism`

```
export $(grep -v '^#' .env | xargs)
forge script --rpc-url $RPC --chain-id $CHAIN_ID script/dca/networks/All_Deploy_Optimism.s.sol --broadcast --legacy --verify
```

`DCA bsc`

```
export $(grep -v '^#' .env | xargs)
forge script --rpc-url $RPC --chain-id $CHAIN_ID script/dca/networks/All_Deploy_Binance.s.sol --broadcast --legacy --verify
```

`note: deploy goes for single chain only. IF you need to deploy on multiple chains - dont forget to update "RPC" and "CHAIN_ID" values in env file before rerunning both commands`
`tip: to save gas - you may want to deploy factory only and keep dcaImp and whitelist from first/old ones. In that case - use deployDCAV3Factory instead`
Local testnet:

```
forge script --rpc-url http://localhost:8545 script/All_Deploy.sol --broadcast --legacy
```

You can check deployed addresses in console or in /broadcast folder

## Verify

Setup apikeys and urls in `foundry.toml` and constructor args in txt file (see example in `factory-constructor-args.txt`)

Verify target contract using following command:

## RPSV1

Example for manual verification on optimism

```
forge verify-contract 0xc347BA6f6A9Ce0dd4F4A351EaB30c8Ebde59028e "src/RPS/RPSV1.sol:RPSV1" --verifier-url "https://api-optimistic.etherscan.io/api" --etherscan-api-key "F8EQY2UV2JB9VQ88VZ58NE3ZXWKAY2Q9MC" --num-of-optimizations 200 --compiler-version v0.8.20+commit.a1b79de6
```

## RPSV1Factory

```
forge verify-contract 0xF8ce142e20f3c4209E8d1E0FAc4A307db4dfC975 "src/RPS/RPSV1Factory.sol:RPSV1Factory" --verifier-url 'https://api-optimistic.etherscan.io/api' --etherscan-api-key BPHPNQ1IYRT2FFUPIWQXN2Z7YY1P3IGCXN --num-of-optimizations 200 --compiler-version v0.8.20+commit.a1b79de6 --constructor-args $(cast abi-encode "constructor(address param1)" 0x1B8EE524844DE43827F13007C3360024D7d09191)
```

with admins

```
forge verify-contract 0x63ed218143F18f3a16c03008D4D062818298CA80 "src/RPS/RPSV1Factory.sol:RPSV1Factory" --verifier-url "https://api.polygonscan.com/api" --etherscan-api-key "EII3M4G2MKTHAS6METKBJH149P8EFWV9ZP" --num-of-optimizations 200 --compiler-version v0.8.20+commit.a1b79de6 --constructor-args $(cast abi-encode "constructor(address param1, address[] admins)" 0x0f15FBC7189468B5983A1Caa0e31d552128f6703 0x94Ad54EC1299B9BE82eCc9328187eF37fDB07329, 0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43, 0xB0b12f40b18027f1a2074D2Ab11C6e0d6c6acbB5)
```

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

Use scripts from `/script` folder

## Now we can test locally deployed contract with metamask / FE app / cast / hardhat / etc.

# Deployed contracts

[DCA contracts can be found here](./src/DCA/)
