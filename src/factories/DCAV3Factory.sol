// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "interfaces/IDCA.sol";
import "interfaces/IAssetsWhitelist.sol";
import "../libraries/Path.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@uniswap-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap-periphery/contracts/libraries/TransferHelper.sol";
/*
0xfbD8ba80BcCE20135ba46e0BC300533dFE9a2F3a - admin
0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43 - user
0x2F81b3BAFC24d174D370678EfDe14A69F43974Cc - worker
0xb07BE8eE8D505245540a7d34De69C91A2A69D292 - contract address
"0xc2132D05D31c914a87C6611C10748AEb04B58e8F", # USDT
"0xb33EaAd8d922B1083446DC23f610c2567fB5180f", # UNI
struct Position {
        address beneficiary;
        address executor;
        uint256 singleSpendAmount;
        address tokenToSpend;
        address tokenToBuy;
        uint256 lastPurchaseTimestamp;
    }
*/
//                                                                                  newOwner                                    beneficiary                                executor                 singleSpendAmount  tokenToSpend(USDT)                          tokenToBuy(UNI)                            lastPurchaseTimestamp
// "createDCA(address,(address,address,uint256,address,address,uint256))(address)" 0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43 "(0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43,0x2F81b3BAFC24d174D370678EfDe14A69F43974Cc,2,0xc2132D05D31c914a87C6611C10748AEb04B58e8F,0xb33EaAd8d922B1083446DC23f610c2567fB5180f,0)"
// cast send 0xb07BE8eE8D505245540a7d34De69C91A2A69D292 --unlocked --from 0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43

contract DCAV3Factory {
    using Path for bytes;

    address public assetsWhitelist;
    address public dcaImpl;

    address public constant SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    event DcaDeployed(address indexed newDcaAddress, address indexed newOwner);

    constructor(address assetsWhitelist_, address dcaImpl_) {
        require(assetsWhitelist_ != address(0));
        require(dcaImpl_ != address(0));
        assetsWhitelist = assetsWhitelist_;
        dcaImpl = dcaImpl_;
    }

    function createDCA(address newOwner, IDCA.Position calldata initialPosition)
        external
        returns (address newDcaProxy)
    {
        address tokenIn = initialPosition.tokenToSpend;
        newDcaProxy = _deployDCA(newOwner, initialPosition);
        TransferHelper.safeApprove(tokenIn, newDcaProxy, type(uint256).max);

        return newDcaProxy;
    }

    function _deployDCA(address _newOwner, IDCA.Position calldata _initialPosition) internal returns (address) {
        address proxy = Clones.clone(dcaImpl);

        IDCA(proxy).initialize(IAssetsWhitelist(assetsWhitelist), SWAP_ROUTER, _newOwner, _initialPosition);

        emit DcaDeployed(proxy, _newOwner);

        return proxy;
    }
}
