pragma solidity ^0.8.0;

import "../Hatchy.sol";

interface IHatchyPocketEggs {
    function burnEggOfUser(Hatchy.Egg egg, address account, uint amount) external;
}
