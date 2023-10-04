pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FakeToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 amountToMint) ERC20(name, symbol) {
        _mint(msg.sender, amountToMint * 10 ** uint256(decimals()));
    }
}

contract AssetsHelper {
    ERC20[] public assets;
    address[] public assetsAddresses;

    constructor(uint256 amountOfAssets) {
        for (uint256 i = 0; i < amountOfAssets; i++) {
            generateAsset(string.concat("FakeAsset", Strings.toString(i)), string.concat("FA", Strings.toString(i)));
        }
    }

    function generateAsset(string memory name_, string memory symbol_) public returns (ERC20) {
        ERC20 newAsset = new FakeToken(name_, symbol_, 100);
        assets.push(newAsset);
        assetsAddresses.push(payable(address(newAsset)));
        return newAsset;
    }

    function dealTokens(ERC20 asset, address to, uint256 amount) public {
        asset.transfer(to, amount);
    }

    function getAssetsAddresses() public view returns (address[] memory) {
        return assetsAddresses;
    }
}
