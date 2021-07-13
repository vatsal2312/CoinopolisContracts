pragma solidity ^0.7.4;

// Must import CST AND add the correct CST address in constructor
import '../dBankV2/CST.sol';


contract Timelock {
  uint public constant duration = 8 minutes;
  uint public immutable end;
  address public immutable owner;
  CST public cst;

  constructor() {
    end = block.timestamp + duration;
    owner = msg.sender; 
    cst = CST();
  }

  function withdraw() external {
    require(msg.sender == owner, 'only owner');
    require(block.timestamp >= end, 'too early');
    cst.transferOwnership(owner);
  }
}
