// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./TransferHelper.sol";

enum AssetTypes {
    ERC20,
    ERC721,
    ERC1155
}

struct ERC1155Offer {
    address contractAddress;
    uint256[] tokens;
    uint256[] amounts;
}

struct ERC721Offer {
    address contractAddress;
    uint256[] tokens;
}

struct ERC20Offer {
    address contractAddress;
    uint256 amount;
}

struct Offers {
    ERC1155Offer[] erc1155Offers;
    ERC721Offer[] erc721Offers;
    ERC20Offer[] erc20Offers;
}

struct SwapOffer {
    uint256 id;
    address offerer;
    bool executed;
    uint256 validUntil;
}

contract HatchySwap is Ownable {
    uint256 createdOffers;
    mapping(uint256 => Offers) offers;
    mapping(uint256 => Offers) askings;
    mapping(uint256 => SwapOffer) offerData;

    modifier validateOffer(Offers memory _offer) {
        for (uint256 i = 0; i < _offer.erc1155Offers.length; ) {
            require(_offer.erc1155Offers[i].contractAddress != address(0), "0");
            require(
                _offer.erc1155Offers[i].tokens.length ==
                    _offer.erc1155Offers[i].amounts.length,
                "mismatch"
            );
            unchecked {
                i++;
            }
        }

        for (uint256 i = 0; i < _offer.erc721Offers.length; ) {
            require(
                _offer.erc721Offers[i].contractAddress != address(0),
                "0_2"
            );
            require(
                _offer.erc721Offers[i].tokens.length ==
                    _offer.erc721Offers[i].tokens.length,
                "mismatch_2"
            );

            unchecked {
                i++;
            }
        }

        for (uint256 i = 0; i < _offer.erc20Offers.length; ) {
            require(_offer.erc20Offers[i].contractAddress != address(0), "0_2");
            require(_offer.erc20Offers[i].amount > 0, "mismatch_2");
            unchecked {
                i++;
            }
        }
        _;
    }

    function createSwapOffer(
        Offers calldata _myOffer,
        Offers calldata _asking,
        uint256 validUntil
    ) external validateOffer(_myOffer) validateOffer(_asking) {
        offerData[createdOffers] = SwapOffer({
            id: createdOffers,
            offerer: msg.sender,
            executed: false,
            validUntil: validUntil
        });
        askings[createdOffers] = _asking;
        offers[createdOffers] = _myOffer;
        createdOffers++;
    }

    function matchSwapOffer(uint256 id) external {
        require(offerData[id].validUntil >= block.timestamp, "time");
        require(!offerData[id].executed, "exec");
        require(offerData[id].offerer != msg.sender, "self");
        offerData[id].validUntil = 0;
        offerData[id].executed = true;

        // transfer assets of order creator to caller

        // transfer erc721s from order creator to caller
        for (
            uint256 index = 0;
            index < offers[id].erc721Offers.length;
            index++
        ) {
            ERC721Offer memory _erc721s = offers[id].erc721Offers[index];
            for (uint256 j = 0; j < _erc721s.tokens.length; j++) {
                _transferERC721(
                    _erc721s.contractAddress,
                    offerData[id].offerer,
                    msg.sender,
                    _erc721s.tokens[j]
                );
            }
        }

        // transfer erc1155s from order creator to caller

        for (
            uint256 index = 0;
            index < offers[id].erc1155Offers.length;
            index++
        ) {
            ERC1155Offer memory _erc1155s = offers[id].erc1155Offers[index];
            _transferERC1155(
                _erc1155s.contractAddress,
                offerData[id].offerer,
                msg.sender,
                _erc1155s.tokens,
                _erc1155s.amounts
            );
        }

        // transfer erc20s from order creator to caller
        for (
            uint256 index = 0;
            index < offers[id].erc20Offers.length;
            index++
        ) {
            ERC20Offer memory _erc20s = offers[id].erc20Offers[index];
            _transferERC20(
                _erc20s.contractAddress,
                offerData[id].offerer,
                msg.sender,
                _erc20s.amount
            );
        }

        // transfer assets of  caller  to  order creator

        // transfer erc721s from   caller  to  order creator
        for (
            uint256 index = 0;
            index < askings[id].erc721Offers.length;
            index++
        ) {
            ERC721Offer memory _erc721s = askings[id].erc721Offers[index];
            for (uint256 j = 0; j < _erc721s.tokens.length; j++) {
                _transferERC721(
                    _erc721s.contractAddress,
                    msg.sender,
                    offerData[id].offerer,
                    _erc721s.tokens[j]
                );
            }
        }

        // transfer erc1155s from   caller  to  order creator

        for (
            uint256 index = 0;
            index < askings[id].erc1155Offers.length;
            index++
        ) {
            ERC1155Offer memory _erc1155s = askings[id].erc1155Offers[index];
            _transferERC1155(
                _erc1155s.contractAddress,
                msg.sender,
                offerData[id].offerer,
                _erc1155s.tokens,
                _erc1155s.amounts
            );
        }

        // transfer erc20s from   caller  to order creator
        for (
            uint256 index = 0;
            index < askings[id].erc20Offers.length;
            index++
        ) {
            ERC20Offer memory _erc20s = askings[id].erc20Offers[index];
            _transferERC20(
                _erc20s.contractAddress,
                msg.sender,
                offerData[id].offerer,
                _erc20s.amount
            );
        }
    }

    function _transferERC20(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        TransferHelper.safeTransferFrom(token, from, to, value);
    }

    function _transferERC721(
        address erc721,
        address from,
        address to,
        uint256 id
    ) internal {
        IERC721(erc721).safeTransferFrom(from, to, id);
    }

    function _transferERC1155(
        address erc1155,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        TransferHelper.safeTransferERC1155(erc1155, from, to, ids, amounts);
    }
}
