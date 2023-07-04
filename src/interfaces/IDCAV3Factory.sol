// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "interfaces/IDCA.sol";

interface IDCAV3Factory {
    function createDCA(
        address newOwner,
        IDCA.Position calldata initialPosition
    ) external returns (address newDcaProxy);
}