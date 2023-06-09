// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IHatchyRewarder.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
    internal
    view
    returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract HatchyGen1Staking is
ReentrancyGuardUpgradeable,
ContextUpgradeable,
ERC721HolderUpgradeable,
PausableUpgradeable,
UUPSUpgradeable,
OwnableUpgradeable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    // using SafeERC20 for IERC20;

    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    mapping(bytes32 => bool) public BannedR;
    mapping(bytes32 => bool) public BannedS;

    // constructor() {
    //     _addSigner(_msgSender());
    // }

    modifier onlySigner() {
        require(
            isSigner(_msgSender()),
            "SignerRole: caller does not have the Signer role"
        );
        _;
    }
    modifier sigIsValid(bytes32 r, bytes32 s) {
        require(!BannedR[r] || !BannedS[s], "invalid signature");
        _;
    }

    function banSignature(bytes32 r, bytes32 s) external onlyOwner {
        BannedR[r] = true;
        BannedS[s] = true;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(_msgSender());
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }

    struct MetaInfo {
        uint256 _tokenId;
        uint256 _monsterId;
        uint256 _shiny;
        uint256 _serial;
        uint256 _element;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    uint256 public constant MAX_HATCHIES = 40001;

    address public hatchyRewarder;

    address public hatchyNft;

    mapping(address => EnumerableSet.UintSet) private userBalances;

    mapping(uint256 => MetaInfo) public metadatas;

    /* Address for collecting fee */
    address public feeAddress;

    event Staked(address indexed account, uint256 tokenId, uint256 weight);
    event BatchStaked(address indexed account, uint256 weight);
    event Withdrawn(address indexed account, uint256 tokenId, uint256 weight);
    event BatchWithdrawn(
        address indexed account,
        uint256[] tokenIds,
        uint256 weight
    );

    uint256 private constant MAX = ~uint256(0);


    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        address _hatchyNft,
        address _feeAddress,
        address _signer
    ) public initializer {
        __Ownable_init();

        __ReentrancyGuard_init();

        __ERC721Holder_init();

        hatchyNft = _hatchyNft;
        feeAddress = _feeAddress;
        _addSigner(_signer);
    }

    function setRewarder(address _rewarder) external onlyOwner {
        hatchyRewarder = _rewarder;
    }

    function userStakedNFT(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        //  return userBalances[_owner].values();
        uint256 tokenCount = userBalances[_owner].length();
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    returns (uint256)
    {
        return userBalances[owner].at(index);
    }

    function userStakedNFTCount(address _owner)
    external
    view
    returns (uint256)
    {
        return userBalances[_owner].length();
    }

    function checkShinySetInfo(address _account)
    public
    view
    returns (uint256, uint256)
    {
        uint256 tokenCount = userBalances[_account].length();

        if (tokenCount == 0) {
            return (0, 0);
        } else {
            uint256[] memory staked = userStakedNFT(_account);

            uint256 i;

            uint256[6] memory shiny_set_checker = [
            MAX,
            MAX,
            MAX,
            MAX,
            MAX,
            MAX
            ];

            uint256[6] memory shiny_collection_checker;

            uint256[40] memory shiny_monster_checker;

            uint256 shiny_set_count = 0;
            uint256 shiny_collection_count = MAX;

            for (i = 0; i < tokenCount; i++) {
                MetaInfo storage info = metadatas[staked[i]];

                if (info._monsterId == 0) {
                    shiny_set_count += 1;
                }

                if (info._shiny > 0) {
                    shiny_monster_checker[info._monsterId] += 1;
                }
            }

            for (i = 1; i < 10; i++) {
                if (shiny_set_checker[1] > shiny_monster_checker[i]) {
                    shiny_set_checker[1] = shiny_monster_checker[i];
                }
            }

            for (i = 10; i < 19; i++) {
                if (shiny_set_checker[2] > shiny_monster_checker[i]) {
                    shiny_set_checker[2] = shiny_monster_checker[i];
                }
            }

            for (i = 19; i < 28; i++) {
                if (shiny_set_checker[3] > shiny_monster_checker[i]) {
                    shiny_set_checker[3] = shiny_monster_checker[i];
                }
            }

            for (i = 28; i < 34; i++) {
                if (shiny_set_checker[4] > shiny_monster_checker[i]) {
                    shiny_set_checker[4] = shiny_monster_checker[i];
                }
            }

            for (i = 34; i < 40; i++) {
                if (shiny_set_checker[5] > shiny_monster_checker[i]) {
                    shiny_set_checker[5] = shiny_monster_checker[i];
                }
            }

            for (i = 1; i < 6; i++) {
                shiny_set_count += shiny_set_checker[i];

                shiny_collection_checker[i] = shiny_set_checker[i];
            }

            for (i = 1; i < 6; i++) {
                if (shiny_collection_count > shiny_collection_checker[i]) {
                    shiny_collection_count = shiny_collection_checker[i];
                }
            }

            return (shiny_set_count, shiny_collection_count);
        }
    }

    function checkSetInfo(address _account)
    public
    view
    returns (uint256, uint256)
    {
        uint256 tokenCount = userBalances[_account].length();

        if (tokenCount == 0) {
            return (0, 0);
        } else {
            uint256[] memory staked = userStakedNFT(_account);

            uint256 i;

            uint256[6] memory set_checker = [MAX, MAX, MAX, MAX, MAX, MAX];

            uint256[6] memory collection_checker;

            uint256[40] memory monster_checker;

            uint256 set_count = 0;
            uint256 collection_count = MAX;

            for (i = 0; i < tokenCount; i++) {
                MetaInfo storage info = metadatas[staked[i]];
                monster_checker[info._monsterId] += 1;
            }

            for (i = 1; i < 10; i++) {
                if (set_checker[1] > monster_checker[i]) {
                    set_checker[1] = monster_checker[i];
                }
            }

            for (i = 10; i < 19; i++) {
                if (set_checker[2] > monster_checker[i]) {
                    set_checker[2] = monster_checker[i];
                }
            }

            for (i = 19; i < 28; i++) {
                if (set_checker[3] > monster_checker[i]) {
                    set_checker[3] = monster_checker[i];
                }
            }

            for (i = 28; i < 34; i++) {
                if (set_checker[4] > monster_checker[i]) {
                    set_checker[4] = monster_checker[i];
                }
            }

            for (i = 34; i < 40; i++) {
                if (set_checker[5] > monster_checker[i]) {
                    set_checker[5] = monster_checker[i];
                }
            }

            for (i = 1; i < 6; i++) {
                set_count += set_checker[i];

                collection_checker[i] = set_checker[i];
            }

            for (i = 1; i < 6; i++) {
                if (collection_count > collection_checker[i]) {
                    collection_count = collection_checker[i];
                }
            }

            return (set_count, collection_count);
        }
    }

    function calculateWeight(address _account)
    public
    view
    returns (uint256, uint256)
    {
        uint256 tokenCount = userBalances[_account].length();

        if (tokenCount == 0) {
            return (0, 0);
        } else {
            uint256 weight = 0;
            uint256 shinyCount = 0;

            uint256[] memory staked = userStakedNFT(_account);

            uint256 i;

            (uint256 set_count, uint256 collection_count) = checkSetInfo(
                _account
            );

            (
            uint256 shiny_set_count,
            uint256 shiny_collection_count
            ) = checkShinySetInfo(_account);

            for (i = 0; i < tokenCount; i++) {
                MetaInfo storage info = metadatas[staked[i]];

                if (info._shiny > 0) {
                    weight += 20;
                    shinyCount += 1;
                } else {
                    weight += 1;
                }
            }

            if (shiny_set_count > 0) {
                weight += 400 * shiny_set_count;
                if (set_count > shiny_set_count) {
                    weight += 20 * (set_count.sub(shiny_set_count));
                }
            } else {
                weight += 20 * set_count;
            }

            if (collection_count > 0 && collection_count != MAX) {
                if (shiny_collection_count > 0) {
                    weight += 8000 * shiny_collection_count;
                    if (collection_count > shiny_collection_count) {
                        weight +=
                        400 *
                        (collection_count.sub(shiny_collection_count));
                    }
                } else {
                    weight += 400 * collection_count;
                }
            }

            return (weight * 1000, shinyCount);
        }
    }

    function isStaked(address account, uint256 tokenId)
    public
    view
    returns (bool)
    {
        return userBalances[account].contains(tokenId);
    }

    function encodePackedData(
        uint256 _tokenId,
        uint256 _monsterId,
        uint256 _serial,
        uint256 _element,
        uint256 _shiny
    ) public pure returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                _tokenId,
                _monsterId,
                _serial,
                _element,
                _shiny
            )
        );
    }

    function batchStake(MetaInfo[] calldata _stakeParams, address referrer)
    external
    nonReentrant
    whenNotPaused
    {
        for (uint256 i = 0; i < _stakeParams.length; i++) {
            MetaInfo calldata _param = _stakeParams[i];
            require(!BannedR[_param.r] || !BannedS[_param.s], "invalid signature");
            bool signerCheck = isSigner(
                ecrecover(
                    toEthSignedMessageHash(
                        keccak256(
                            abi.encodePacked(
                                _param._tokenId,
                                _param._monsterId,
                                _param._serial,
                                _param._element,
                                _param._shiny
                            )
                        )
                    ),
                    _param.v,
                    _param.r,
                    _param.s
                )
            );

            if (signerCheck) {
                uint256 tokenId = _param._tokenId;

                require(tokenId < MAX_HATCHIES, "Invalid token id");

                require(IERC721(hatchyNft).ownerOf(tokenId) == msg.sender, "?!");

                require(
                    IERC721(hatchyNft).isApprovedForAll(
                        _msgSender(),
                        address(this)
                    ),
                    "Not approve nft to staker address"
                );

                IERC721(hatchyNft).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    tokenId
                );

                if (metadatas[tokenId]._tokenId == 0) {
                    metadatas[tokenId] = _param;
                }
                userBalances[_msgSender()].add(tokenId);
            } else {
                revert("not signer");
            }
        }

        (uint256 newWeight,) = calculateWeight(_msgSender());

        if (newWeight > 0) {
            IHatchyReward(hatchyRewarder).updateUserWeight(
                _msgSender(),
                newWeight,
                referrer
            );
        }

        emit BatchStaked(_msgSender(), newWeight);
    }

    function batchWithdraw(uint256[] calldata _tokenIds)
    external
    nonReentrant
    /*whenNotPaused*/
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];

            require(tokenId < MAX_HATCHIES, "Invalid token id");

            require(isStaked(_msgSender(), tokenId), "Not staked this nft");

            IERC721(hatchyNft).safeTransferFrom(
                address(this),
                _msgSender(),
                tokenId
            );

            userBalances[_msgSender()].remove(tokenId);
        }

        (uint256 newWeight,) = calculateWeight(_msgSender());

        IHatchyReward(hatchyRewarder).updateUserWeight(
            _msgSender(),
            newWeight,
            address(0)
        );

        emit BatchWithdrawn(_msgSender(), _tokenIds, newWeight);
    }

    function withdraw(uint256 tokenId) public nonReentrant {
        require(tokenId < MAX_HATCHIES, "Invalid token id");

        require(isStaked(_msgSender(), tokenId), "Not staked this nft");

        IERC721(hatchyNft).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId
        );

        userBalances[_msgSender()].remove(tokenId);

        (uint256 newWeight,) = calculateWeight(_msgSender());

        IHatchyReward(hatchyRewarder).updateUserWeight(
            _msgSender(),
            newWeight,
            address(0)
        );

        emit Withdrawn(_msgSender(), tokenId, newWeight);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function addSignerRole(address account) external onlyOwner {
        _addSigner(account);
    }

    function removeSignerRole(address account) external onlyOwner {
        _removeSigner(account);
    }

    function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }

    function setHatchyGen1(address gen1) external onlyOwner {
        hatchyNft = gen1;
    }
}
