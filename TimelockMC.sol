pragma solidity ^0.7.4;

import '../dBankV2/MasterChefv2.sol';


contract Timelock {
  uint public constant duration = 365 days;
  uint public immutable end;
  address public immutable owner;
  MasterChef public masterChef;

  constructor() {
    end = block.timestamp + duration;
    owner = msg.sender; 
    masterChef = MasterChef();
  }

  function withdraw() external {
    require(msg.sender == owner, 'only owner');
    require(block.timestamp >= end, 'too early');
    masterChef.transferOwnership(owner);
  }
}
