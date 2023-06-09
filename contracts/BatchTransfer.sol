// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BatchNFTTransferService is Ownable {
    function batchSafeTransfer(
        address _tokenAddress,
        address[] memory _receivers,
        uint256[] memory tokenIds
    ) external {
        require(_receivers.length == tokenIds.length, "mismatch");
        IERC721 _contract = IERC721(_tokenAddress);
        for (uint256 index = 0; index < _receivers.length; index++) {
            require(
                _receivers[index] != address(0) &&
                    _receivers[index] != msg.sender,
                "0"
            );
            _contract.safeTransferFrom(
                msg.sender,
                _receivers[index],
                tokenIds[index]
            );
        }
    }

    function batchTransfer(
        address _tokenAddress,
        address[] memory _receivers,
        uint256[] memory tokenIds
    ) external {
        require(_receivers.length == tokenIds.length, "mismatch");
        IERC721 _contract = IERC721(_tokenAddress);
        for (uint256 index = 0; index < _receivers.length; index++) {
            require(
                _receivers[index] != address(0) &&
                    _receivers[index] != msg.sender,
                "0"
            );
            _contract.transferFrom(
                msg.sender,
                _receivers[index],
                tokenIds[index]
            );
        }
    }

    function saveNFTs(
        address _erc721,
        address to,
        uint256[] memory tokenIds
    ) external onlyOwner {
        // emergency
        IERC721 _contract = IERC721(_erc721);
        for (uint256 index = 0; index < tokenIds.length; index++) {
            _contract.safeTransferFrom(address(this), to, tokenIds[index]);
        }
    }
}
