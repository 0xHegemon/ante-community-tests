pragma solidity ^0.8.0;

import "./IERC20.sol";
import './token.sol';
import "./AntePoHTest.sol";

/* This exchange is based off of Uniswap V1. The original whitepaper for the constant product rule
 * can be found here:
 * https://github.com/runtimeverification/verified-smart-contracts/blob/uniswap/uniswap/x-y-k.pdf
 */

contract TokenBridge {
    address public anteTestAddr;
    AntePoHTest private anteTest;

    WETH private token;
    address private owner;

    uint public eth_reserves = 0;
    bool public live = false;

    constructor(address _tokenAddr) {
        owner = msg.sender;
        token = WETH(_tokenAddr);
    }

    function setAnteTest(address _anteTestAddr) public {
        require(msg.sender == owner);
        anteTestAddr = _anteTestAddr;
        anteTest = AntePoHTest(_anteTestAddr);
    }

    function heartbeat() public view returns (bool) {
        return live;
    }

    function disable() public {
        require(msg.sender == anteTestAddr || msg.sender == owner);
        live = false;
    }

    function enable() public {
        require(msg.sender == owner);
        live = true;
    }

    function deposit() external payable {
        require(live, "Deposits currently disabled");
        require(msg.value > 0, "Need ETH to bridge");
        eth_reserves += msg.value;
        token.mint(msg.sender, msg.value);
    }

    function withdraw(uint amount) external payable {
        require(amount <= eth_reserves, "Amount of ETH withdrawn must not be more than reserve");
        token.transferFrom(msg.sender, address(this), amount);
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send ETH");
    }
}