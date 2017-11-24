pragma solidity ^0.4.8;

contract Ownable {
  address public owner;
  address public owner1;
  address public owner2;
  address public owner3;

  function Ownable() {
    owner = msg.sender;
  }

    function Ownable1() {
    owner1 = msg.sender;
  }

    function Ownable2() {
    owner2 = msg.sender;
  }

    function Ownable3() {
    owner3 = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  modifier onlyOwner1() {
    if (msg.sender == owner1)
      _;
  }

  modifier onlyOwner2() {
    if (msg.sender == owner2)
      _;
  }

  modifier onlyOwner3() {
    if (msg.sender == owner3)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}