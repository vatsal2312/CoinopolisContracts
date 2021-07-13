pragma solidity ^0.7.4;

import '../dBankV2/CST.sol';


contract Timelock {
  uint public constant duration = 8 minutes;
  uint public immutable end;
  address public immutable owner;
  CST public cst;

  constructor() {
    end = block.timestamp + duration;
    owner = msg.sender; 
    cst = CST(0x281bd1e74A8C5A7e47Df102594500a322BD61929);
  }

  function withdraw() external {
    require(msg.sender == owner, 'only owner');
    require(block.timestamp >= end, 'too early');
    cst.transferOwnership(owner);
  }
}
