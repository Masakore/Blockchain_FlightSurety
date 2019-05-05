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

  uint private no_of_registered_airlines = 0;

	uint256 private balance = 0 ether;

  uint256 private registration_fund = 10 ether;

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
	  no_of_registered_airlines++;
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
  external
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

		no_of_registered_airlines.add(1);
	}

	function addAirlineFund(address _airline, uint256 _fund)
	external
  payable
	requireIsOperational
	isCallerAuthorized
	{
	  airlines[_airline].fund = airlines[_airline].fund.add(_fund);
	  balance = balance.add(_fund);
	}

	/**
	 * @dev Buy insurance for a flight
	 *
	 */
	function buy
	(
	)
	external
	payable
	{

	}

	/**
	 *  @dev Credits payouts to insurees
	*/
	function creditInsurees
	(
	)
	external
	pure
	{
	}


	/**
	 *  @dev Transfers eligible payout funds to insuree
	 *
	*/
	function pay
	(
	)
	external
	pure
	{
	}

	/**
	 * @dev Initial funding for the insurance. Unless there are too many delayed flights
	 *      resulting in insurance payouts, the contract should be self-sustaining
	 *
	 */
	function fund
	(
	)
	public
	payable
	{
	}

	function getFlightKey
	(
	address airline,
	string memory flight,
	uint256 timestamp
	)
	pure
	internal
	returns (bytes32)
	{
	return keccak256(abi.encodePacked(airline, flight, timestamp));
	}

	/**
	* @dev Fallback function for funding smart contract.
	*
	*/
	function()
	external
	payable
	{
	fund();
	}


}

