// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IHatchyRewarder.sol";

contract HatchyGen2Staking is
    ReentrancyGuardUpgradeable,
    ContextUpgradeable,
    ERC1155ReceiverUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    struct ShinyInfo {
        uint256 plant;
        uint256 water;
        uint256 fire;
        uint256 light;
        uint256 dark;
        uint256 dragon;
        uint256 void;
    }

    // Mapping from token ID to account balances

    mapping(address => EnumerableMap.UintToUintMap) private userBlanaces;

    address public hatchyGen2;

    address public hatchyToken;

    mapping(address => uint256) private tokenStakedBalances;

    address public hatchyRewarder;

    uint256 private constant MAX = ~uint256(0);

    event Staked(address indexed account, uint256 tokenId, uint256 amount);
    event TokenStaked(address indexed account, uint256 amount);
    event BatchStaked(
        address indexed account,
        uint256[] tokenIds,
        uint256[] amounts
    );

    event Withdrawn(address indexed account, uint256 tokenId, uint256 amount);
    event TokenWithdrawn(address indexed account, uint256 amount);
    event BatchWithdrawn(
        address indexed account,
        uint256[] tokenIds,
        uint256[] amounts
    );

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(address _hatchyGen2, address _hatchyToken)
        public
        initializer
    {
        __Ownable_init();

        __ReentrancyGuard_init();

        __ERC1155Receiver_init();

        hatchyGen2 = _hatchyGen2;

        hatchyToken = _hatchyToken;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setRewarder(address _rewarder) external onlyOwner {
        hatchyRewarder = _rewarder;
    }

    function tokenStake(uint256 amount, address referrer)
        external
        nonReentrant
        whenNotPaused
    {
        require(amount > 0, "Amount cannot be zero");
        require(
            IERC20(hatchyToken).transferFrom(
                _msgSender(),
                hatchyRewarder,
                amount
            ),
            "token transfer failed"
        );
        handleTokenStake(_msgSender(), amount, referrer);
    }

    function handleTokenStake(
        address from,
        uint256 amount,
        address referrer
    ) internal {
        tokenStakedBalances[_msgSender()] += amount;

        emit TokenStaked(from, amount);

        updateWeight(from, referrer);
    }

    function stake(
        uint256 tokenId,
        uint256 amount,
        address referrer
    ) external nonReentrant whenNotPaused {
        uint256 balance = IERC1155(hatchyGen2).balanceOf(_msgSender(), tokenId);

        require(balance > 0, "User has no nft");

        require(
            IERC1155(hatchyGen2).isApprovedForAll(_msgSender(), address(this)),
            "Not approve to staker address"
        );

        uint256 stakeAmount = amount;

        if (balance < amount) {
            stakeAmount = balance;
        }

        IERC1155(hatchyGen2).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId,
            stakeAmount,
            new bytes(0)
        );

        handleStake(_msgSender(), tokenId, stakeAmount, referrer);
    }

    function handleStake(
        address from,
        uint256 tokenId,
        uint256 amount,
        address referrer
    ) internal {
        (bool staked, uint256 beforeBalance) = userBlanaces[from].tryGet(
            tokenId
        );

        if (staked) {
            userBlanaces[from].set(tokenId, beforeBalance + amount);
        } else {
            userBlanaces[from].set(tokenId, amount);
        }

        emit Staked(from, tokenId, amount);

        updateWeight(from, referrer);
    }

    function updateWeight(address from, address referrer) internal {
        (uint256 newWeight, ) = calculateWeight(from);

        IHatchyReward(hatchyRewarder).updateUserWeight(
            from,
            newWeight,
            referrer
        );
    }

    function batchStake(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address referrer
    ) external nonReentrant whenNotPaused {
        require(tokenIds.length == amounts.length, "Wrong stake parameter");

        require(
            IERC1155(hatchyGen2).isApprovedForAll(_msgSender(), address(this)),
            "Not approve to staker address"
        );

        uint256 totalBalance = 0;
        uint256[] memory values;
        uint256 length = amounts.length;
        for (uint256 i; i < length; ) {
            uint256 balance = IERC1155(hatchyGen2).balanceOf(
                _msgSender(),
                tokenIds[i]
            );
            if (amounts[i] > balance) {
                values[i] = balance;
            } else {
                values[i] = amounts[i];
            }
            totalBalance += values[i];
            unchecked {
                i++;
            }
        }

        require(totalBalance > 0, "User has no nft");

        IERC1155(hatchyGen2).safeBatchTransferFrom(
            _msgSender(),
            address(this),
            tokenIds,
            values,
            new bytes(0)
        );

        handleBatchStake(_msgSender(), tokenIds, values, referrer);
    }

    function handleBatchStake(
        address from,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address referrer
    ) internal {
        uint256 length = amounts.length;

        for (uint256 i; i < length; ) {
            (bool staked, uint256 beforeBalance) = userBlanaces[from].tryGet(
                tokenIds[i]
            );

            if (staked) {
                userBlanaces[from].set(tokenIds[i], beforeBalance + amounts[i]);
            } else {
                userBlanaces[from].set(tokenIds[i], amounts[i]);
            }
            unchecked {
                i++;
            }
        }
        emit BatchStaked(from, tokenIds, amounts);

        updateWeight(from, referrer);
    }

    function tokenWithdraw(uint256 amount) external nonReentrant {
        uint256 stakedAmount = tokenStakedBalances[_msgSender()];
        uint256 withdrawnAmount = stakedAmount <= amount
            ? stakedAmount
            : amount;

        IHatchyReward(hatchyRewarder).tokenWithdraw(
            _msgSender(),
            withdrawnAmount
        );

        updateWeight(_msgSender(), address(0));

        emit TokenWithdrawn(_msgSender(), withdrawnAmount);
    }

    function withdraw(uint256 tokenId, uint256 amount) external nonReentrant {
        uint256 stakeAmount = userBlanaces[_msgSender()].get(
            tokenId,
            "Not staked nft"
        );

        uint256 withdrawAmount = amount;

        if (stakeAmount < amount) {
            withdrawAmount = stakeAmount;
        }

        IERC1155(hatchyGen2).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId,
            amount,
            new bytes(0)
        );

        if (stakeAmount > withdrawAmount) {
            userBlanaces[_msgSender()].set(
                tokenId,
                stakeAmount - withdrawAmount
            );
        } else {
            userBlanaces[_msgSender()].remove(tokenId);
        }

        updateWeight(_msgSender(), address(0));

        emit Withdrawn(_msgSender(), tokenId, withdrawAmount);
    }

    function batchWithdraw(uint256[] memory tokenIds, uint256[] memory amounts)
        external
        nonReentrant
    {
        require(tokenIds.length == amounts.length, "Wrong withdraw parameter");

        uint256[] memory values;
        uint256 length = amounts.length;

        for (uint256 i; i < length; ) {
            uint256 balance = userBlanaces[_msgSender()].get(
                tokenIds[i],
                "Not staked nft"
            );

            if (amounts[i] > balance) {
                values[i] = balance;
            } else {
                values[i] = amounts[i];
            }
            unchecked {
                i++;
            }
        }

        IERC1155(hatchyGen2).safeBatchTransferFrom(
            address(this),
            _msgSender(),
            tokenIds,
            values,
            new bytes(0)
        );

        for (uint256 i; i < length; ) {
            uint256 balance = userBlanaces[_msgSender()].get(
                tokenIds[i],
                "Not staked nft"
            );

            if (values[i] < balance) {
                userBlanaces[_msgSender()].set(
                    tokenIds[i],
                    balance - values[i]
                );
            } else {
                userBlanaces[_msgSender()].remove(tokenIds[i]);
            }
            unchecked {
                i++;
            }
        }

        updateWeight(_msgSender(), address(0));

        emit BatchWithdrawn(_msgSender(), tokenIds, amounts);
    }

    function userStakedNFT(address _owner)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 tokenCount = userBlanaces[_owner].length();
        if (tokenCount == 0) {
            // Return an empty array
            return (new uint256[](0), new uint256[](0));
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256[] memory balances = new uint256[](tokenCount);
            uint256 index;

            for (index = 0; index < tokenCount; ) {
                (uint256 tokenId, uint256 balance) = userBlanaces[_owner].at(
                    index
                );
                result[index] = tokenId;
                balances[index] = balance;
                unchecked {
                    index++;
                }
            }

            return (result, balances);
        }
    }

    function setInfo(
        address _account,
        uint256 setStart,
        uint256 setLast
    ) private view returns (uint256) {
        uint256 index = setStart;

        uint256 setCount = MAX;

        while (index <= setLast) {
            (bool staked, uint256 balance) = userBlanaces[_account].tryGet(
                index
            );

            if (staked) {
                if (setCount > balance) {
                    setCount = balance;
                }
            } else {
                setCount = 0;
                break;
            }

            unchecked {
                index++;
            }
        }

        return setCount;
    }

    function shinySetInfo(
        address _account,
        uint256 setStart,
        uint256 setLast
    ) private view returns (uint256) {
        uint256 index = setStart;

        uint256 setCount = MAX;

        while (index <= setLast) {
            uint256 tokenId = index * 1000 + 888;

            (bool staked, uint256 balance) = userBlanaces[_account].tryGet(
                tokenId
            );

            if (staked) {
                if (setCount > balance) {
                    setCount = balance;
                }
            } else {
                setCount = 0;
                break;
            }

            unchecked {
                index++;
            }
        }

        return setCount;
    }

    function voidMonsterSetInfo(address _account)
        public
        view
        returns (uint256)
    {
        uint256[4] memory tokenIds = [
            uint256(10011001),
            10101001,
            10100101,
            11111111
        ];

        uint256 setCount = MAX;
        uint256 index = 0;

        while (index < 4) {
            uint256 tokenId = tokenIds[index];

            (bool staked, uint256 balance) = userBlanaces[_account].tryGet(
                tokenId
            );

            if (staked) {
                if (setCount > balance) {
                    setCount = balance;
                }
            } else {
                setCount = 0;
                break;
            }

            unchecked {
                index++;
            }
        }

        return setCount;
    }

    function calculateWeight(address _account)
        public
        view
        returns (uint256, uint256)
    {
        uint256 amount = userBlanaces[_account].length();
        uint256 tokenAmount = tokenStakedBalances[_account];

        if (amount == 0) {
            return (tokenAmount, 0);
        } else {
            uint256 weight = 0;
            uint256 shinyCount = 0;

            for (uint256 i; i < amount; ) {
                (uint256 tokenId, uint256 balance) = userBlanaces[_account].at(
                    i
                );

                if (tokenId >= 137) {
                    weight += 20 * balance;
                    shinyCount += balance;
                } else {
                    weight += balance;
                }

                unchecked {
                    i++;
                }
            }

            (
                uint256 totalSet,
                uint256 plantSet,
                uint256 waterSet,
                uint256 fireSet,
                uint256 lightSet,
                uint256 darkSet
            ) = userSetInfo(_account);
            (
                uint256 totalShinySet,
                ShinyInfo memory shinyInfo
            ) = userShinySetInfo(_account);

            uint256 minSet = plantSet < waterSet ? plantSet : waterSet;
            minSet = minSet < fireSet ? minSet : fireSet;
            minSet = minSet < lightSet ? minSet : lightSet;
            minSet = minSet < darkSet ? minSet : darkSet;

            uint256 minShinySet = shinyInfo.plant < shinyInfo.water
                ? shinyInfo.plant
                : shinyInfo.water;
            minShinySet = minShinySet < shinyInfo.fire
                ? minShinySet
                : shinyInfo.fire;
            minShinySet = minShinySet < shinyInfo.light
                ? minShinySet
                : shinyInfo.light;
            minShinySet = minShinySet < shinyInfo.dark
                ? minShinySet
                : shinyInfo.dark;
            minShinySet = minShinySet < shinyInfo.dragon
                ? minShinySet
                : shinyInfo.dragon;
            minShinySet = minShinySet < shinyInfo.void
                ? minShinySet
                : shinyInfo.void;

            weight +=
                20 *
                totalSet +
                400 *
                totalShinySet +
                400 *
                minSet +
                8000 *
                minShinySet +
                tokenAmount;

            return (weight, shinyCount);
        }
    }

    function userSetInfo(address _account)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amount = userBlanaces[_account].length();

        if (amount == 0) {
            return (0, 0, 0, 0, 0, 0);
        } else {
            uint256 plantSet = setInfo(_account, 40, 62);

            uint256 waterSet = setInfo(_account, 63, 85);

            uint256 fireSet = setInfo(_account, 86, 108);

            uint256 lightSet = setInfo(_account, 123, 136);

            uint256 darkSet = setInfo(_account, 109, 122);

            return (
                plantSet + waterSet + fireSet + lightSet + darkSet,
                plantSet,
                waterSet,
                fireSet,
                lightSet,
                darkSet
            );
        }
    }

    function userShinySetInfo(address _account)
        public
        view
        returns (uint256, ShinyInfo memory)
    {
        uint256 amount = userBlanaces[_account].length();

        if (amount == 0) {
            ShinyInfo memory _shinyInfo = ShinyInfo({
                plant: 0,
                water: 0,
                fire: 0,
                light: 0,
                dark: 0,
                dragon: 0,
                void: 0
            });

            return (0, _shinyInfo);
        } else {
            uint256 shinyPlantSet = shinySetInfo(_account, 40, 62);

            uint256 shinyWaterSet = shinySetInfo(_account, 63, 85);

            uint256 shinyFireSet = shinySetInfo(_account, 86, 108);

            uint256 shinyLightSet = shinySetInfo(_account, 123, 136);

            uint256 shinyDarkSet = shinySetInfo(_account, 109, 122);

            uint256 dragonSet = setInfo(_account, 137, 142);

            uint256 voidSet = voidMonsterSetInfo(_account);

            uint256 totalShinySet = shinyPlantSet +
                shinyWaterSet +
                shinyFireSet +
                shinyLightSet +
                shinyDarkSet +
                dragonSet +
                voidSet;

            ShinyInfo memory _shinyInfo = ShinyInfo({
                plant: shinyPlantSet,
                water: shinyWaterSet,
                fire: shinyFireSet,
                light: shinyLightSet,
                dark: shinyDarkSet,
                dragon: dragonSet,
                void: voidSet
            });

            return (totalShinySet, _shinyInfo);
        }
    }

    function isStaked(
        address account,
        uint256 tokenId,
        uint256 amount
    ) public view returns (bool) {
        (bool staked, uint256 balance) = userBlanaces[account].tryGet(tokenId);
        return staked && balance >= amount;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
