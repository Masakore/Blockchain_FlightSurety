pragma solidity ^0.4.25;


import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract FlightSuretyData {
	using SafeMath for uint256;

/********************************************************************************************/
/*                                       DATA VARIABLES                                     */
/********************************************************************************************/

	// Account used to deploy contract
	address private contractOwner;
	bool private operational = true;

  mapping(address => uint256) private authorizedContracts;

  struct Airline {
    bool isRegistered;
    uint256 fund;
  }

  mapping(address => Airline) private airlines;
  address[] private registeredAirlineAddress;

  uint private no_of_registered_airlines = 0;


  uint256 private registration_fund = 10 ether;

  struct Passenger {
    bool isInsured;
    bool[] isClaimed;
    uint256[] insuranceAmount;
    string[] flights;
  }

  mapping(address => Passenger) private passengers;

  mapping(string => address[]) private flightPassengersMapping;

  // Holds the ether anted by Airline and paid as insurance by passengers
	uint256 private contractBalance = 0 ether;

  mapping(address => uint256) private insuranceAmount;

/********************************************************************************************/
/*                                       EVENT DEFINITIONS                                  */
/********************************************************************************************/

	/**
	* @dev Constructor
	*      The deploying account becomes contractOwner
	*/
	constructor(address firstAirline)
	public
	{
	  contractOwner = msg.sender;
	  airlines[firstAirline] = Airline({
	                                     isRegistered: true,
	                                     fund: 0
	                                   });
	  no_of_registered_airlines = no_of_registered_airlines.add(1);
	  registeredAirlineAddress.push(firstAirline);

	  // The following is for testing purpose
		address dapp_address = 0xf25186B5081Ff5cE73482AD761DB0eB0d25abfBF;
	  authorizeContract(dapp_address);

	}

/********************************************************************************************/
/*                                       FUNCTION MODIFIERS                                 */
/********************************************************************************************/

// Modifiers help avoid duplication of code. They are typically used to validate something
// before a function is allowed to be executed.

	/**
	* @dev Modifier that requires the "operational" boolean variable to be "true"
	*      This is used on all state changing functions to pause the contract in
	*      the event there is an issue that needs to be fixed
	*/
	modifier requireIsOperational()
	{
	  require(operational, "Contract is currently not operational");
	  _;
	}

	/**
	* @dev Modifier that requires the "ContractOwner" account to be the function caller
	*/
	modifier requireContractOwner()
	{
	  require(msg.sender == contractOwner, "Caller is not contract owner");
	  _;
	}

  modifier isCallerAuthorized()
  {
    require(authorizedContracts[msg.sender] == 1, "Caller is not authorized");
    _;
  }

/********************************************************************************************/
/*                                       UTILITY FUNCTIONS                                  */
/********************************************************************************************/

	/**
	* @dev Get operating status of contract
	*
	* @return A bool that is the current operating status
	*/
	function isOperational()
  public
	view
  isCallerAuthorized
	returns (bool)
	{
	  return operational;
	}

	/**
	* @dev Sets contract operations on/off
	*
	* When operational mode is disabled, all write transactions except for this one will fail
	*/
	function setOperatingStatus(bool mode)
	external
	requireContractOwner
	{
	  operational = mode;
	}

  function authorizeContract(address callerContract)
  public
  requireContractOwner
  {
    authorizedContracts[callerContract] = 1;
  }

	function deauthorizeContract(address callerContract)
	external
	requireContractOwner
	{
	  delete authorizedContracts[callerContract];
	}

  function isAirline(address _airline)
  external
  isCallerAuthorized
  returns (bool)
  {
    if(airlines[_airline].isRegistered == true) {
      return true;
    }
    return false;
  }

	function isEnoughFunded(address _airline)
	external
	isCallerAuthorized
	returns (bool)
	{
		if(airlines[_airline].fund >= registration_fund) {
		  return true;
		}
		return false;
	}

	function getRemainingFund(address _airline)
	external
	isCallerAuthorized
	returns (uint256)
	{
	  return airlines[_airline].fund;
	}

	function getNoOfRegisteredAirlines()
	external
	view
	isCallerAuthorized
	returns (uint)
	{
	  return no_of_registered_airlines;
	}

/********************************************************************************************/
/*                                     SMART CONTRACT FUNCTIONS                             */
/********************************************************************************************/

// TODO add isCallerAuthorized modifier to all functions

	/**
	 * @dev Add an airline to the registration queue
	 *      Can only be called from FlightSuretyApp contract
	 *
	 */
	function registerAirline(address _airline)
	external
	requireIsOperational
	isCallerAuthorized
	{
		airlines[_airline] = Airline({
	                                 isRegistered: true,
									                 fund: 0
	                               });

	  registeredAirlineAddress.push(_airline);
		no_of_registered_airlines = no_of_registered_airlines.add(1);
	}

	/**
	 * @dev Initial funding for the insurance. Unless there are too many delayed flights
	 *      resulting in insurance payouts, the contract should be self-sustaining
	 *
	 */
	function addAirlineFund(address _airline, uint256 _fund)
	external
  payable
	requireIsOperational
	isCallerAuthorized
	{
	  airlines[_airline].fund = airlines[_airline].fund.add(_fund);
	  contractBalance = contractBalance.add(_fund);
	}

	/**
	 * @dev Buy insurance for a flight
	 *
	 */
	function buy(address _passenger, uint _amount, string _flight)
	external
	payable
	requireIsOperational
	isCallerAuthorized
	{
	  //Todo: fix me later. seems have to initialise array by passing size in order to use memory.
	  // Alternate approach without assigning initial size is to use storage but it's expensive.
	  // For now, just assign random value that is good enough for testing.
		string[] memory flights = new string[](3);
		bool[] memory claimed = new bool[](3);
		uint256[] memory insurance = new uint[](3);

		if(passengers[_passenger].isInsured == true){
			isPassengerBoughtInsuranceForTheFlight(_passenger, _flight);

	    // Purchase an insurance for another flight
			passengers[_passenger].flights.push(_flight);
			passengers[_passenger].isClaimed.push(false);
			passengers[_passenger].insuranceAmount.push(_amount);
		} else {
	    flights[0] = _flight;
			claimed[0] = false;
			insurance[0] = _amount;

			passengers[_passenger] = Passenger({isInsured: true, isClaimed: claimed, insuranceAmount: insurance, flights: flights});
		}

		// update insurance amount contributed
   	contractBalance = contractBalance.add(_amount);
		flightPassengersMapping[_flight].push(_passenger);
	}

  function getFlightIndex(address _passenger, string memory _flight)
  internal
  view
  returns(uint)
	{
	  require(passengers[_passenger].flights.length > 0, "This passenger does not purchase any insurance yet");
	  string[] memory flights = new string[](5);
	  flights = passengers[_passenger].flights;

	  uint index;
	  bool isMatched = false;

	  for(uint i = 0; i < flights.length; i++) {
	    if(uint(keccak256(abi.encodePacked(flights[i]))) == uint(keccak256(abi.encodePacked(_flight)))) {
	      index = i;
        isMatched = true;
	    }
	  }

	  require(isMatched == true, "There's no matching flight attached with this passenger");

	  return index;
	}

	function isPassengerBoughtInsuranceForTheFlight(address _passenger, string memory _flight)
	internal
	view
	returns(bool)
	{
		require(passengers[_passenger].flights.length > 0, "This passenger does not purchase any insurance yet");
	  string[] memory flights = new string[](5);
	  flights = passengers[_passenger].flights;

		for(uint i = 0; i < flights.length; i++) {
			if(uint(keccak256(abi.encodePacked(flights[i]))) == uint(keccak256(abi.encodePacked(_flight)))) {
				return true;
			}
		}

		return false;
	}

	/**
	 *  @dev Transfers eligible payout funds to insuree
	 *
	*/
	function pay(address _passenger)
	external
  payable
  requireIsOperational
  isCallerAuthorized
	{
	  uint256 amount = insuranceAmount[_passenger];
	  insuranceAmount[_passenger] = insuranceAmount[_passenger].sub(amount);
	  contractBalance = contractBalance.sub(amount);
	  _passenger.transfer(amount);
	}

	function getFlightKey(address airline, string memory flight, uint256 timestamp)
	pure
	internal
	returns (bytes32)
	{
	  return keccak256(abi.encodePacked(airline, flight, timestamp));
	}

//  function getInsuranceAmount(address _passenger)
//  external
//  view
//  requireIsOperational
//  isCallerAuthorized
//  returns (uint256)
//  {
//    return insuranceAmount[_passenger];
//  }

	function getInsuredPassengers(string _flight)
	external
	view
	requireIsOperational
	returns(address[])
	{
	  return flightPassengersMapping[_flight];
	}

  function creditInsurees(address _passenger, string _flight)
  external
  requireIsOperational
  isCallerAuthorized
  {
    uint index = getFlightIndex(_passenger, _flight);

    if(passengers[_passenger].isClaimed[index] == false) {
      passengers[_passenger].isClaimed[index] = true;
      uint256 amount = passengers[_passenger].insuranceAmount[index];
      insuranceAmount[_passenger] = insuranceAmount[_passenger].mul(15).div(10); // Pay 1.5 times of insurance
      passengers[_passenger].insuranceAmount[index].sub(amount);
    }
  }

  function getRegisteredAirlines()
  external
  requireIsOperational
  isCallerAuthorized
  returns(address[])
  {
    return registeredAirlineAddress;
  }


	/**
	* @dev Fallback function for funding smart contract.
	*
	*/
	function()
	external
	payable
	{
	}


}

