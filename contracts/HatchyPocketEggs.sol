// SPDX-License-Identifier: GNU GPLv3

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Hatchy.sol";

pragma solidity ^0.8.0;

contract HatchyPocketEggs is OwnableUpgradeable, ERC1155Upgradeable, UUPSUpgradeable {
    using Strings for uint256;

    uint256 public PRICE;

    IERC20 HatchyToken;

    address public HatchyPocketGen2;

    // TODO, adjust on mainnet.
    uint256 public constant MAX_LUNAR = 249990;
    uint256 public constant MAX_SOLAR = 249990;
    uint256 public constant MAX_PER_TX = 40;
    mapping(address => address) public referrals;

    mapping(Hatchy.Egg => uint256) public eggSupplies;


    string baseURI;

    modifier onlyHatchyGen2() {
        require(msg.sender == HatchyPocketGen2, "h4x0r");
        _;
    }

    function initialize(
        string memory _baseUri,
        uint256 _price,
        address _erc20
    ) external initializer {
        __ERC1155_init(_baseUri);
        __Ownable_init();
        PRICE = _price;
        HatchyToken = IERC20(_erc20);
        baseURI = _baseUri;
    }
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setHatchyGen2(address _gen2Address) external onlyOwner {
        HatchyPocketGen2 = _gen2Address;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setHatchy(address _hatchy) external onlyOwner {
        HatchyToken = IERC20(_hatchy);
    }

    function clearMyReferral() external {
        // BE CAREFUL
        delete referrals[msg.sender];
    }

    function mintEgg(
        Hatchy.Egg egg,
        uint256 amount,
        address referral
    ) external {
        if (referrals[msg.sender] == address(0) && referral != address(0)) {
            referrals[msg.sender] = referral;
        }

        egg == Hatchy.Egg.LUNAR
            ? require(eggSupplies[egg] + amount <= MAX_LUNAR, "max.")
            : require(eggSupplies[egg] + amount <= MAX_SOLAR, "max.");

        require(amount <= MAX_PER_TX);

        if (PRICE > 0) {
            uint256 total = PRICE * amount;
            if (referrals[msg.sender] != address(0)) {
                require(
                    HatchyToken.transferFrom(
                        msg.sender,
                        owner(),
                        (total * 90) / 100
                    )
                );

                require(
                    HatchyToken.transferFrom(
                        msg.sender,
                        owner(),
                        (total * 10) / 100
                    )
                );
            } else {
                require(HatchyToken.transferFrom(msg.sender, owner(), total));
            }
        }

        eggSupplies[egg] += amount;
        _mint(msg.sender, uint256(egg), amount, new bytes(0));
    }

    function burn(Hatchy.Egg egg, uint256 amount) external {
        _burn(msg.sender, uint256(egg), amount);
    }

    function burnEggOfUser(
        Hatchy.Egg egg,
        address account,
        uint256 amount
    ) external onlyHatchyGen2 {
        require(
            balanceOf(account, uint256(egg)) >= amount && amount > 0,
            "bal."
        );
        _burn(account, uint256(egg), amount);
    }

    function setBaseMetadataURI(string memory _newBaseMetadataURI)
        public
        onlyOwner
    {
        _setURI(_newBaseMetadataURI);
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI(_id);
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

    function name() external pure returns (string memory _name) {
        _name = "HatchyPocket Gen2 Eggs";
    }
    function symbol() external pure returns (string memory _name) {
        _name = "HATCHY$EGG";
    }
}
