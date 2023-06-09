// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract HATCHY  is ERC20PresetFixedSupply {




   constructor() ERC20PresetFixedSupply("Hatchy", "HATCHY", 1000000000 ether, msg.sender) {}
}