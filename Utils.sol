pragma solidity ^0.4.11;

contract Utils{

	//verifies the amount greater than zero

	modifier greaterThanZero(uint256 _value){
		require(_value>0);
		_;
	}

	///verifies an address

	modifier validAddress(address _add){
		require(_add!=0x0);
		_;
	}
}