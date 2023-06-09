// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract HatchyReward is
    ReentrancyGuardUpgradeable,
    ContextUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;

    struct UserInfo {
        uint256 weight;
        uint256 gen1Point;
        uint256 gen2Point;
        uint256 rewardDebt; // Reward debt
        address referrer;
        uint256[5] levels;
        uint256 bonus;
    }

    // Info of each user that stakes hatchy tokens.
    mapping(address => UserInfo) public userInfo;

    mapping(address => address[]) private userReferred;

    /* Reward Token */
    address public rewardTokenAddress;

    /* Staking Reward ratio ( every 1 week ) */
    uint256 public rewardPerWeek;

    uint256 public totalWeight;

    address public hatchyGen1Staking;
    address public hatchyGen2Staking;

    // Accrued token per share
    uint256 public accTokenPerShare;

    uint256 public lastRewardTime;

    uint256[] public REFERRAL_PERCENTS;
    uint256 public constant PERCENT_STEP = 5;
    uint256 public constant PERCENTS_DIVIDER = 1000;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    uint256 private constant MAX = ~uint256(0);

    event RewardAddressUpdated(address token);
    event RewardPerWeekUpdated(uint256 reward);

    event Harvest(address indexed user, uint256 amount);

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        address _rewardTokenAddress,
        address _hatchyGen1Stake,
        address _hatchyGen2Stake,
        uint256 _rewardPerWeek
    ) public initializer {
        __Ownable_init();

        __ReentrancyGuard_init();

        totalWeight = 0;

        hatchyGen1Staking = _hatchyGen1Stake;
        hatchyGen2Staking = _hatchyGen2Stake;

        rewardTokenAddress = _rewardTokenAddress;
        rewardPerWeek = _rewardPerWeek;

        REFERRAL_PERCENTS = [50, 30, 15, 10, 5];

        uint256 decimalsRewardToken = 18;
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));
        lastRewardTime = block.timestamp;
    }

    modifier onlyStaker() {
        _checkStaker();
        _;
    }

    function _checkStaker() internal view {
        require(
            hatchyGen1Staking == _msgSender() ||
                hatchyGen2Staking == _msgSender(),
            "HatchyReward: caller is not the staker"
        );
    }

    function setRewardTokenAddress(address _address) external onlyOwner {
        require(_address != address(0x0), "invalid address");
        rewardTokenAddress = _address;

        emit RewardAddressUpdated(_address);
    }

    function setRewardPerWeek(uint256 _reward) external onlyOwner {
        rewardPerWeek = _reward;
        emit RewardPerWeekUpdated(_reward);
    }

    function updateUserWeight(
        address _account,
        uint256 newWeight,
        address referrer
    ) public onlyStaker nonReentrant {
        _updatePool();

        UserInfo storage user = userInfo[_account];

        uint256 pending = user
            .weight
            .mul(accTokenPerShare)
            .div(PRECISION_FACTOR)
            .sub(user.rewardDebt);

        if (pending > 0) {
            IERC20(rewardTokenAddress).transfer(_account, pending);
        }

        if (_msgSender() == hatchyGen1Staking) {
            /// hatchy gen1 stake.
            if (user.gen1Point < newWeight) {
                updateReferrer(_account, referrer, newWeight - user.gen1Point);
            }

            user.gen1Point = newWeight;
        } else {
            /// hatchy gen2 stake.
            if (user.gen2Point < newWeight) {
                updateReferrer(_account, referrer, newWeight - user.gen2Point);
            }

            user.gen2Point = newWeight;
        }

        uint256 oldWeight = user.weight;

        user.weight = user.gen1Point + user.gen2Point + user.bonus;

        if (user.gen1Point == 0 && user.gen2Point == 0) {
            user.bonus = 0;
            user.weight = 0;
        }

        totalWeight = totalWeight.add(user.weight).sub(oldWeight);

        user.rewardDebt = user.weight.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );
    }

    function updateReferrer(
        address _account,
        address referrer,
        uint256 subWeight
    ) internal {
        if (referrer != address(0)) {
            if (!isContract(referrer)) {
                UserInfo storage user = userInfo[_account];

                if (user.referrer == address(0)) {
                    if (userInfo[referrer].weight > 0 && referrer != _account) {
                        user.referrer = referrer;
                        userReferred[referrer].push(_account);
                    }

                    address upline = user.referrer;
                    for (uint256 i = 0; i < 5; i++) {
                        if (upline != address(0)) {
                            userInfo[upline].levels[i] = userInfo[upline]
                                .levels[i]
                                .add(1);
                            upline = userInfo[upline].referrer;
                        } else break;
                    }
                }

                if (user.referrer != address(0)) {
                    address upline = user.referrer;
                    for (uint256 i = 0; i < 5; i++) {
                        if (upline != address(0)) {
                            uint256 referralWeight = subWeight
                                .mul(REFERRAL_PERCENTS[i])
                                .div(PERCENTS_DIVIDER);
                            userInfo[upline].bonus = userInfo[upline].bonus.add(
                                referralWeight
                            );
                            userInfo[upline].weight = userInfo[upline]
                                .weight
                                .add(referralWeight);
                            totalWeight = totalWeight.add(referralWeight);
                            upline = userInfo[upline].referrer;
                        } else break;
                    }
                }
            }
        }
    }

    function pendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];

        uint256 blockTime = block.timestamp;

        if (blockTime > lastRewardTime && totalWeight != 0) {
            uint256 multiplier = blockTime.sub(lastRewardTime);

            uint256 hatchyReward = multiplier.mul(rewardPerWeek).div(604800);

            uint256 adjustedTokenPerShare = accTokenPerShare.add(
                hatchyReward.mul(PRECISION_FACTOR).div(totalWeight)
            );

            return
                user
                    .weight
                    .mul(adjustedTokenPerShare)
                    .div(PRECISION_FACTOR)
                    .sub(user.rewardDebt);
        } else {
            return
                user.weight.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(
                    user.rewardDebt
                );
        }
    }

    function _updatePool() internal {
        uint256 blockTime = block.timestamp;

        if (block.timestamp <= lastRewardTime) {
            return;
        }

        if (totalWeight == 0) {
            lastRewardTime = block.timestamp;
            return;
        }

        uint256 multiplier = blockTime.sub(lastRewardTime);

        uint256 hatchyReward = multiplier.mul(rewardPerWeek).div(604800);

        accTokenPerShare = accTokenPerShare.add(
            hatchyReward.mul(PRECISION_FACTOR).div(totalWeight)
        );

        lastRewardTime = block.timestamp;
    }

    function harvest() public nonReentrant whenNotPaused {
        _updatePool();

        UserInfo storage user = userInfo[_msgSender()];

        uint256 pending = user
            .weight
            .mul(accTokenPerShare)
            .div(PRECISION_FACTOR)
            .sub(user.rewardDebt);

        if (pending > 0) {
            IERC20(rewardTokenAddress).transfer(_msgSender(), pending);
        }

        user.rewardDebt = user.weight.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );

        emit Harvest(_msgSender(), pending);
    }

    function tokenWithdraw(address account, uint256 amount) external {
        require(_msgSender() == hatchyGen2Staking, "auth error");
        require(
            IERC20(rewardTokenAddress).transfer(account, amount),
            "token transfer failed"
        );
    }

    function getUserTotalReferrals(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            userInfo[userAddress].levels[0] +
            userInfo[userAddress].levels[1] +
            userInfo[userAddress].levels[2] +
            userInfo[userAddress].levels[3] +
            userInfo[userAddress].levels[4];
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return userInfo[userAddress].bonus;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return userInfo[userAddress].referrer;
    }

    function getUserReferralCount(address userAddress)
        public
        view
        returns (uint256[5] memory referrals)
    {
        return (userInfo[userAddress].levels);
    }

    function userReferredInfo(address _user)
        public
        view
        returns (address[] memory)
    {
        return userReferred[_user];
    }

    function userReferredCount(address _user) external view returns (uint256) {
        return userReferred[_user].length;
    }

    function isContract(address _addr) private view returns (bool isContract) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
