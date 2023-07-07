# make sure message comes after testnet log passed
sleep 2s
echo Waiting for testnet to startup...
# wait for testnet to start fully
sleep 1s

RPC=http://0.0.0.0:8545
echo USDT balance of {$address} is
cast call 0xc2132d05d31c914a87c6611c10748aeb04b58e8f "balanceOf(address)(uint256)" $address
echo Deploying contracts
echo DCAV3Factory
forge create DCAV3Factory --constructor-args 0x59698022f08FF0d0B6EDbC956Fd9c0596543A983 0xf52Aea45dFDE4669C73010D4C47E9e0c75E5c8ca --mnemonic-passphrase "$mnemonic" --rpc-url $infura_url --legacy
