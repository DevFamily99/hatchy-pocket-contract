// SPDX-License-Identifier: GNU GPLv3

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

pragma solidity ^0.8.0;

import "./interfaces/IHatchyPocketEggs.sol";
import "./Random.sol";

// import "./Hatchy.sol";

contract HatchyPocketGen2 is Random, OwnableUpgradeable, ERC1155Upgradeable, UUPSUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using Strings for uint256;

    bool enabled;
    address HatchyPocketEggs;

    // uint public constant MAX_SHINY = 1;
    uint256 public constant MAX_SHINY = 140;
    // uint public constant MAX_COMMON = 1;
    uint256 public constant MAX_COMMON = 5000;

    uint256 private randomnessNonce;

    // @dev hatchyId -> supply mapping
    mapping(uint256 => uint256) public hatchySupplies;

    EnumerableSetUpgradeable.UintSet private availableSolarCommon;
    EnumerableSetUpgradeable.UintSet private availableSolarShiny;
    EnumerableSetUpgradeable.UintSet private availableLunarCommon;
    EnumerableSetUpgradeable.UintSet private availableLunarShiny;
    EnumerableSetUpgradeable.UintSet private availableSharedCommon;
    EnumerableSetUpgradeable.UintSet private availableSharedShiny;

    // admin stuff
    uint256 public noShinyStreak;
    string baseURI;
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(string memory _baseUri) external initializer {
        __Ownable_init();
        __ERC1155_init(_baseUri);
        randomnessNonce = block.number % 10;
        baseURI = _baseUri;
    }

    function initialize1() external onlyOwner {
        require(availableSolarCommon.values().length == 0, "init.");
        uint8[30] memory _solarCommonPool = [
            45,
            46,
            55,
            56,
            61,
            68,
            74,
            75,
            78,
            82,
            84,
            88,
            98,
            102,
            105,
            107,
            123,
            124,
            125,
            126,
            127,
            128,
            129,
            130,
            131,
            132,
            133,
            134,
            135,
            136
        ];

        for (uint256 i = 0; i < _solarCommonPool.length; ) {
            availableSolarCommon.add(_solarCommonPool[i]);
            unchecked {
                i++;
            }
        }
    }

    function initialize2() external onlyOwner {
        require(availableSolarShiny.values().length == 0, "init.");

        uint24[32] memory _solarShinyPool = [
            11111111,
            141888,
            45888,
            46888,
            55888,
            56888,
            61888,
            68888,
            74888,
            75888,
            78888,
            82888,
            84888,
            88888,
            98888,
            102888,
            105888,
            107888,
            123888,
            124888,
            125888,
            126888,
            127888,
            128888,
            129888,
            130888,
            131888,
            132888,
            133888,
            134888,
            135888,
            136888
        ];
        for (uint256 i = 0; i < _solarShinyPool.length; ) {
            availableSolarShiny.add(_solarShinyPool[i]);
            unchecked {
                i++;
            }
        }
    }

    function initialize3() external onlyOwner {
        require(availableLunarCommon.values().length == 0, "init.");

        uint8[30] memory _lunarCommonPool = [
            40,
            41,
            42,
            49,
            54,
            62,
            71,
            72,
            73,
            77,
            85,
            86,
            94,
            95,
            100,
            108,
            109,
            110,
            111,
            112,
            113,
            114,
            115,
            116,
            117,
            118,
            119,
            120,
            121,
            122
        ];
        for (uint256 i = 0; i < _lunarCommonPool.length; ) {
            availableLunarCommon.add(_lunarCommonPool[i]);
            unchecked {
                i++;
            }
        }
    }

    function initialize4() external onlyOwner {
        require(availableLunarShiny.values().length == 0, "init.");

        uint24[32] memory _lunarShinyPool = [
            10100101,
            140888,
            40888,
            41888,
            42888,
            49888,
            54888,
            62888,
            71888,
            72888,
            73888,
            77888,
            85888,
            86888,
            94888,
            95888,
            100888,
            108888,
            109888,
            110888,
            111888,
            112888,
            113888,
            114888,
            115888,
            116888,
            117888,
            118888,
            119888,
            120888,
            121888,
            122888
        ];
        for (uint256 i = 0; i < _lunarShinyPool.length; ) {
            availableLunarShiny.add(_lunarShinyPool[i]);
            unchecked {
                i++;
            }
        }
    }

    function initialize5() external onlyOwner {
        require(availableSharedCommon.values().length == 0, "init.");

        uint8[37] memory _sharedCommonPool = [
            43,
            44,
            47,
            48,
            50,
            51,
            52,
            53,
            57,
            58,
            59,
            60,
            63,
            64,
            65,
            66,
            67,
            69,
            70,
            76,
            79,
            80,
            81,
            83,
            87,
            89,
            90,
            91,
            92,
            93,
            96,
            97,
            99,
            101,
            103,
            104,
            106
        ];
        for (uint256 i = 0; i < _sharedCommonPool.length; ) {
            availableSharedCommon.add(_sharedCommonPool[i]);
            unchecked {
                i++;
            }
        }
    }

    function initialize6() external onlyOwner {
        require(availableSharedShiny.values().length == 0, "init.");

        uint24[43] memory _sharedShinyPool = [
            10011001,
            10101001,
            137888,
            138888,
            139888,
            142888,
            43888,
            44888,
            47888,
            48888,
            50888,
            51888,
            52888,
            53888,
            57888,
            58888,
            59888,
            60888,
            63888,
            64888,
            65888,
            66888,
            67888,
            69888,
            70888,
            76888,
            79888,
            80888,
            81888,
            83888,
            87888,
            89888,
            90888,
            91888,
            92888,
            93888,
            96888,
            97888,
            99888,
            101888,
            103888,
            104888,
            106888
        ];
        for (uint256 i = 0; i < _sharedShinyPool.length; ) {
            availableSharedShiny.add(_sharedShinyPool[i]);
            unchecked {
                i++;
            }
        }
    }

    function setEggContract(address _eggs) external onlyOwner {
        HatchyPocketEggs = _eggs;
    }

    function flipState() external onlyOwner {
        enabled = !enabled;
    }

    // implementation will be here.

    function hatchSingle(Hatchy.Egg egg) external {
        require(enabled, "not yet.");
        _handleHatch(egg);
        IHatchyPocketEggs(HatchyPocketEggs).burnEggOfUser(egg, msg.sender, 1);
    }

    function hatchMultiple(Hatchy.Egg egg, uint256 amount) external {
        require(enabled, "not yet.");
        require(amount <= 10, "2many");

        for (uint256 i = 0; i < amount; i++) {
            _handleHatch(egg);
        }

        IHatchyPocketEggs(HatchyPocketEggs).burnEggOfUser(
            egg,
            msg.sender,
            amount
        );
    }

    function _handleHatch(Hatchy.Egg egg) internal {
        bool _isShiny = isShiny(egg);
        randomnessNonce++;
        if (!_isShiny) {
            noShinyStreak++;
        } else {
            noShinyStreak = 0;
        }

        // check if shiny, then check if its egg specific pool or shared pool
        if (_isShiny) {
            // check if its shared shiny pool or egg specific shiny pool
            bool isSpecialPool = isSpecial_ShinyPool(egg);
            if (isSpecialPool) {
                if (egg == Hatchy.Egg.LUNAR) {
                    handleShinyLunarPool();
                } else {
                    handleShinySolarPool();
                }
            } else {
                handleSharedShinyPool();
            }
        } else {
            // check if its shared common pool or egg specific common pool
            bool isSpecialPool = isSpecial_CommonPool(egg);
            if (isSpecialPool) {
                if (egg == Hatchy.Egg.LUNAR) {
                    handleCommonLunarPool();
                } else {
                    handleCommonSolarPool();
                }
            } else {
                handleSharedCommonPool();
            }
        }
    }

    function handleCommonSolarPool() internal {
        uint256[] memory availableHatchyIds = availableSolarCommon.values();
        uint256 indexRoll = dn(
            randomnessNonce + block.number,
            availableHatchyIds.length
        );
        randomnessNonce++;
        uint256 hatchyToMint = availableHatchyIds[indexRoll];

        _mint(msg.sender, hatchyToMint, 1, new bytes(0));

        hatchySupplies[hatchyToMint]++;

        if (hatchySupplies[hatchyToMint] >= MAX_COMMON) {
            availableSolarCommon.remove(hatchyToMint);
        }
    }

    function handleCommonLunarPool() internal {
        uint256[] memory availableHatchyIds = availableLunarCommon.values();
        uint256 indexRoll = dn(
            randomnessNonce + block.number,
            availableHatchyIds.length
        );
        randomnessNonce++;
        uint256 hatchyToMint = availableHatchyIds[indexRoll];

        _mint(msg.sender, hatchyToMint, 1, new bytes(0));

        hatchySupplies[hatchyToMint]++;

        if (hatchySupplies[hatchyToMint] >= MAX_COMMON) {
            availableLunarCommon.remove(hatchyToMint);
        }
    }

    function handleShinySolarPool() internal {
        uint256[] memory availableHatchyIds = availableSolarShiny.values();
        uint256 indexRoll = dn(
            randomnessNonce + block.number,
            availableHatchyIds.length
        );
        randomnessNonce++;
        uint256 hatchyToMint = availableHatchyIds[indexRoll];

        _mint(msg.sender, hatchyToMint, 1, new bytes(0));

        hatchySupplies[hatchyToMint]++;

        if (hatchySupplies[hatchyToMint] >= MAX_SHINY) {
            availableSolarShiny.remove(hatchyToMint);
        }
    }

    function handleShinyLunarPool() internal {
        uint256[] memory availableHatchyIds = availableLunarShiny.values();
        uint256 indexRoll = dn(
            randomnessNonce + block.number,
            availableHatchyIds.length
        );
        randomnessNonce++;
        uint256 hatchyToMint = availableHatchyIds[indexRoll];

        _mint(msg.sender, hatchyToMint, 1, new bytes(0));

        hatchySupplies[hatchyToMint]++;

        if (hatchySupplies[hatchyToMint] >= MAX_SHINY) {
            availableLunarShiny.remove(hatchyToMint);
        }
    }

    function handleSharedShinyPool() internal {
        uint256[] memory availableHatchyIds = availableSharedShiny.values();
        uint256 indexRoll = dn(
            randomnessNonce + block.number,
            availableHatchyIds.length
        );
        randomnessNonce++;
        uint256 hatchyToMint = availableHatchyIds[indexRoll];

        _mint(msg.sender, hatchyToMint, 1, new bytes(0));

        hatchySupplies[hatchyToMint]++;

        if (hatchySupplies[hatchyToMint] >= MAX_SHINY) {
            availableSharedShiny.remove(hatchyToMint);
        }
    }

    function handleSharedCommonPool() internal {
        uint256[] memory availableHatchyIds = availableSharedCommon.values();
        uint256 indexRoll = dn(
            randomnessNonce + block.number,
            availableHatchyIds.length
        );
        randomnessNonce++;
        uint256 hatchyToMint = availableHatchyIds[indexRoll];

        _mint(msg.sender, hatchyToMint, 1, new bytes(0));

        hatchySupplies[hatchyToMint]++;

        if (hatchySupplies[hatchyToMint] >= MAX_COMMON) {
            availableSharedCommon.remove(hatchyToMint);
        }
    }

    function isShiny(Hatchy.Egg egg) internal view returns (bool) {
        // means no lunar shiny left, in specific pool or shared pool
        if (
            egg == Hatchy.Egg.LUNAR &&
            availableLunarCommon.values().length == 0 &&
            availableSharedCommon.values().length == 0
        ) return true;

        // means no solar shiny left, in specific pool or shared pool
        if (
            egg == Hatchy.Egg.SOLAR &&
            availableSolarCommon.values().length == 0 &&
            availableSharedCommon.values().length == 0
        ) return true;

        uint256 bonusStreakChance = noShinyStreak / 60;

        // there are some shiny left. and we roll for it.
        return d100(randomnessNonce) + bonusStreakChance + 1 > 97;
    }

    // if its shiny, and if its lunar or solar pool , rather than shared
    function isSpecial_ShinyPool(Hatchy.Egg egg) internal view returns (bool) {
        // if no more hatchy left in egg specific pool, instantly return shared pool
        if (egg == Hatchy.Egg.SOLAR && availableSolarShiny.values().length == 0)
            return false;
        if (egg == Hatchy.Egg.LUNAR && availableLunarShiny.values().length == 0)
            return false;

        // if no more common hatchy left in shared pool, instantly return egg specific pool
        if (availableSharedShiny.values().length == 0) return true;

        return d100(randomnessNonce) + 1 < 43;
    }

    // if its common, and if its lunar or solar pool , rather than shared
    function isSpecial_CommonPool(Hatchy.Egg egg) internal view returns (bool) {
        // if no more shiny left in egg specific pool, instantly return shared pool
        if (
            egg == Hatchy.Egg.SOLAR && availableSolarCommon.values().length == 0
        ) return false;
        if (
            egg == Hatchy.Egg.LUNAR && availableLunarCommon.values().length == 0
        ) return false;

        // if no more common hatchy left in shared pool, instantly return egg specific pool
        if (availableSharedCommon.values().length == 0) return true;

        return d100(randomnessNonce) + 1 < 43;
    }

    function accountBalanceBatch(address account, uint256[] memory ids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ) {
            result[i] = balanceOf(account, ids[i]);
            unchecked {
                i++;
            }
        }
        return result;
    }

    function availableSolarCommonPool()
        external
        view
        returns (uint256[] memory)
    {
        return availableSolarCommon.values();
    }

    function availableSolarShinyPool()
        external
        view
        returns (uint256[] memory)
    {
        return availableSolarShiny.values();
    }

    function availableLunarCommonPool()
        external
        view
        returns (uint256[] memory)
    {
        return availableLunarCommon.values();
    }

    function availableLunarShinyPool()
        external
        view
        returns (uint256[] memory)
    {
        return availableLunarShiny.values();
    }

    function availableSharedCommonPool()
        external
        view
        returns (uint256[] memory)
    {
        return availableSharedCommon.values();
    }

    function availableSharedShinyPool()
        external
        view
        returns (uint256[] memory)
    {
        return availableSharedShiny.values();
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI(_id);
    }

    function name() external pure returns (string memory _name) {
        _name = "HatchyPocket Gen2";
    }

    function symbol() external pure returns (string memory _name) {
        _name = "HATCHY GEN2";
    }
}
