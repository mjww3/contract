pragma solidity ^0.4.10;
import './StandardToken.sol';
import './Pausable.sol';
import './BTC.sol';
import './Utils.sol';
import './SafeMath.sol';


contract ZohemDataToken is StandardToken, Pausable, SafeMath, Utils{
	string public constant name = "Zohem Data Token";
	string public constant symbol = "ZDT";
	uint256 public constant decimals = 18;
	string public version = "1.0";
	enum State{
		Prefunding,
		Funding,
		Success,
		Failure
	}
	struct etherUserData{
		bool isTokensDistributed;
		uint256 totalTokensAssigned;
	}
	mapping(address => etherUserData) etherAddressMap;
	///array of addresses for the ethereum relateed back funding  contract
	address[] public arr;
	 // metadata
	////btceth RELATED pARAMETERS	
	///The address of the trusted BTC relay
	address public trustedBTCRelay;
	////The address where we are accepting the bitcoins from the people
	address BitcoinAcceptAddress;
	///The value to be sent to our BTC address
	uint valueToBeSent = 1;
	///The ethereum address of the person manking the transaction
	address personMakingTx;
	//uint private output1,output2,output3,output4;
	///to return the address just for the testing purposes
	address public addr1;
	///to return the tx origin just for the testing purposes
	address public txorigin;
	///the txorigin is the web3.eth.coinbase account
	//record Transactions that have claimed ether to prevent the replay attacks
	//to-do
	mapping(uint256 => bool) transactionsClaimed;
	//function for testing only btc address
	bool isTesting;
	///testing the name remove while deploying
	bytes32 testname;
	uint256 public initialSupply;
	address finalOwner;
	uint256 public publisherPool = 100000009; 
    bool public finalizedCrowdfunding = false;
    uint256 public constant ZDTFund = 1500 * (10**6) * 10**decimals; 
    uint256 public fundingStartBlock; // crowdsale start block
    uint256 public fundingEndBlock; // crowdsale end block
    uint256 public constant tokensPerEther = 4400; //TODO
    uint256 public constant tokensPerBTC = 700000000;
    uint256 public constant tokenCreationMax = 1000 * 10000000* 10**18 ; //TODO
    uint256 public constant tokenCreationMin = 100 *1000000* 10**18; //TODO
   function ZohemDataToken(uint256 _fundingStartBlock,uint256 _fundingEndBlock){
		//require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input
		owner = msg.sender;
		fundingStartBlock =_fundingStartBlock;
		fundingEndBlock = _fundingEndBlock;
		totalSupply = ZDTFund;
		initialSupply = 0;
	}

	   // don't just send ether to the contract expecting to get tokens
    //function() { throw; }
	////@dev This function manages the Crowdsale State machine
	///We make it a function and do not assign to a variable//
	///so that no chance of stale variable
	function getState() constant public returns(State){
		///once we reach success lock the State
		if(finalizedCrowdfunding) return State.Success;
		if(block.number<fundingStartBlock) return State.Prefunding;
		else if(block.number<=fundingEndBlock && initialSupply<tokenCreationMax) return State.Funding;
		else if (initialSupply >= tokenCreationMin) return State.Success;
		else return State.Failure;
	}


	///Logs the address and returns the array just for the testing puroposes to be removed
	///while deployment
	event logarr(address[] addr);
	    function getarr() public returns(address[]){
	        logarr(arr);
	        return arr;
	    }
	    ////returns the legth of array after pushing
	    ///only for testing purposes
	   	function getArrLen() public returns (uint){
	   		logarr(arr);
	   		return arr.length;
	   	}
	///sets the array just for the testing puroposes to be removed
	///while deployment
	function setaddr(address addr) public {
	      arr.push(addr);
	  }


	 ///get total tokens in that address mapping
	 ///only for testing puropses
	 function getTokens(address addr) public returns(uint256){
	 	etherUserData my_struct = etherAddressMap[addr];
	 	return my_struct.totalTokensAssigned;
	 }

	 function savepublisherPool(uint256 value){
	 	publisherPool = safeSub(publisherPool,value);
	 }

	///get the block number state 
	///could be presale token sale,
	///20% discount 10% discount sale
	///according to the mail
	function getStateFunding() public returns (uint256){ 
		// 1 day= 50600
		if(block.number<fundingStartBlock+10000) return 40;
		if(block.number>=fundingStartBlock+10001 && block.number<fundingStartBlock+20000) return 20;
		if(block.number>=fundingStartBlock+20001 && block.number<fundingStartBlock+30000) return 10;
		if(block.number>=fundingStartBlock+30001 && block.number<fundingStartBlock+50000) return 0;
		if(block.number>fundingEndBlock) throw;
	}
	///a function using safemath to work with
	///the new function
	function calNewTokens(uint256 tokens) returns (uint256){
		uint256 disc = getStateFunding();
		tokens = safeAdd(tokens,safeDiv(safeMul(tokens,disc),100));
		return tokens;
	}

	function() external payable stopInEmergency{
		// Abort if not in Funding Active state.
        if(getState()==State.Success) throw;
        if (msg.value == 0) throw;
        uint256 newCreatedTokens = safeMul(msg.value,tokensPerEther);
        newCreatedTokens = calNewTokens(newCreatedTokens);
        ///since we are creating tokens we need to increase the total supply
      	initialSupply = safeAdd(initialSupply,newCreatedTokens);
      	if(initialSupply>tokenCreationMax) throw;
      	etherUserData my_struct = etherAddressMap[msg.sender];
      	arr.push(msg.sender);
      	my_struct.totalTokensAssigned = safeAdd(my_struct.totalTokensAssigned,newCreatedTokens);
      	my_struct.isTokensDistributed = false;
	}


	///token distribution initial function for the one in the exchanges
	///to be done only the owner can run this function
	function tokenAssignExchange(address addr,uint256 val) public{
	  if (val == 0) throw;
	  uint256 newCreatedTokens = safeMul(val,tokensPerEther);
	  newCreatedTokens = calNewTokens(newCreatedTokens);
	  initialSupply = safeAdd(initialSupply,newCreatedTokens);
	  if(initialSupply>tokenCreationMax) throw;
	  etherUserData my_struct = etherAddressMap[addr];
	  arr.push(addr);
	  my_struct.totalTokensAssigned = newCreatedTokens;
	  my_struct.isTokensDistributed = false;	
	}

	///function to run when the transaction has been veified
	function processTransaction(bytes txn, uint256 txHash,address addr,bytes20 btcaddr) returns (uint)
	{
		if(stopped) throw;
		var (output1,output2,output3,output4) = BTC.getFirstTwoOutputs(txn);
		bool valueSent;
		addr1 = msg.sender;
		//txorigin = tx.origin;
		//	if(getState()!=State.Funding) throw;
		if(!transactionsClaimed[txHash]){
			var (a,b) = BTC.checkValueSent(txn,btcaddr,valueToBeSent);
			if(a){
				valueSent = true;
				transactionsClaimed[txHash] = true;
				uint256 newCreatedTokens = safeMul(b,tokensPerBTC);
				 ///since we are creating tokens we need to increase the total supply
				newCreatedTokens = calNewTokens(newCreatedTokens);
				initialSupply = safeAdd(initialSupply,newCreatedTokens);
			 	///remember not to go off the LIMITS!!
			 	if(initialSupply>tokenCreationMax) throw;
			 	etherUserData my_struct = etherAddressMap[addr];
			 	arr.push(addr);
			 	my_struct.totalTokensAssigned = newCreatedTokens;
			 	my_struct.isTokensDistributed = false;	
			 	return 1;
			}
		}
		else{
			return 0;
		}
	}

	///function to finalize the crowdfuding
	function finalize() external{
		///abort if crowdfunding has not been a success
		if(getState()!=State.Success) throw;///dont finalize until completed
		if(finalizedCrowdfunding) throw;///cant do it twice
		///prevent more creation of tokens
		finalizedCrowdfunding = true;
		if(!finalOwner.send(this.balance))throw;
	}

	function getTotalepochs() returns (uint){
		if(arr.length%100==0){
			return arr.length/100;
		}else{
			return arr.length+1;
		}
	}

	///the final token distribution function to be run at the end of crowdfunding
	///caution only runs when the crowwdfunding is a success
	///to be done that it runs only by the owner
	///in every case
	function finalEtherDistribution(uint epochnumber) public{
		//if(getState()!=State.Success) throw;
		var x = 100*(epochnumber-1);
		var y = 100*(epochnumber)-1;
		for(var i=x;i<=y;i++)
		{
			etherUserData my_struct = etherAddressMap[arr[i]];
		 	if(!my_struct.isTokensDistributed && my_struct.totalTokensAssigned>0){
			balances[arr[i]] = safeAdd(balances[arr[i]],my_struct.totalTokensAssigned);
			my_struct.isTokensDistributed = true;
		}
		}
	}

	///blacklist the users which are fraudulent
	///from getting any tokens
	///to do also refund just in cases
	function blacklist(address addr) public{
		etherUserData my_struct = etherAddressMap[addr];
		my_struct.totalTokensAssigned = 0;
		my_struct.isTokensDistributed = false;
	}
	

		

}