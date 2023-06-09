
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Hatchy.sol";

interface IHatchyPocketGen2 {
    function hatchySupplies(uint tokenId) external returns(uint);

    function _solarCommonPool(uint index) external returns(uint);

    function _solarShinyPool(uint index) external returns(uint);

    function _lunarCommonPool(uint index) external returns(uint);

    function _lunarShinyPool(uint index) external returns(uint);

    function _sharedCommonPool(uint index) external returns(uint);

    function _sharedShinyPool(uint index) external returns(uint);

    function accountBalanceBatch(address account, uint[] memory ids) external view returns (uint[] memory);
}
