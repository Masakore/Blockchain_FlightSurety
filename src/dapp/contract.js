import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

function randomDate(start, end) {
  return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

export default class Contract {
  constructor(network, callback) {
    let config = Config[network];
    this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
    this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
    this.owner = null;
    this.airlines = [];
    this.flights = [];
    this.passengers = [];
    this.initialize(callback);
  }
  
  initialize(callback) {
    this.web3.eth.getAccounts(async (error, accts) => {
      let account = accts[0];

      this.owner = account;

      let counter = 1;

      this.airlines = await this.flightSuretyApp.methods.getRegisteredAirlines().call({ from: self.owner});

      if (!this.airlines || !this.airlines.length) {
          alert("There is no airline available");
      }

      //create 5 passengers
      while(this.passengers.length < 5) {
          this.passengers.push({
              account: accts[counter++],
              passengerFund: 0,
          });
      }

      //create 5 flights to display
      while(this.flights.length < 5) {
          this.flights.push({
              airline: accts[counter++],
              flight: "Flight" + Math.floor((Math.random() * 10) + 1),
              timestamp: randomDate(new Date(), new Date(Date.now() + 1000 * 60 * 60 * 2)),
          });
      }

      callback();
    });
  }

  async registerAirline(airline, callback){
    let self = this;
    await self.flightSuretyApp.methods.registerAirline(airline).call({from: this.owner}, (error, result) => {
      callback(error, result);
  });
  }

  async addAirlineFund(airline,funds, callback){
    let self = this;
    let amount = self.web3.utils.toWei(funds, "ether").toString();
    await self.flightSuretyApp.methods.addAirlineFund(airline).send(
      { from: self.owner, value:amount}, (error, result) => { callback(error, result);}
  );
  }

  async buy(passenger, insurance, flight, callback){
    let self = this;
    let amount = self.web3.utils.toWei(insurance);
    this.addFunds(passenger, insurance);
    await self.flightSuretyApp.methods.buy(insurance, flight).send({ from: passenger, value: amount,  gas:3000000 }, (error, result) => {
        callback(error, result);
    });
  }

  async show(passenger, callback){
    let self = this;
    self.funds = await self.flightSuretyApp.methods.getPassengersInsurance().call({from: passenger});
  }

  async pay(passenger, callback){
    let self = this;
    let passengerCurrentFund = this.getFunds(passenger);
    let withdrawAmount = self.web3.utils.toWei(passengerCurrentFund);
    await self.flightSuretyApp.methods.pay().send({from: passenger, value: passengerCurrentFund, gas:3000000}, (error, result) => {
      if(error){
          console.log(error);
      }else {
          console.log(result);
        callback(result);
      }
    });
  }

  addFunds(passenger, insurance){
    for (var i=0; i < this.passengers.length; i++) {
      if (this.passengers[i].account === passenger) {
        this.passengers[i].passengerFund = insurance;
      }
    }
  }

  getFunds(passenger) {
    let result = 0;
    for (var i=0; i < this.passengers.length; i++) {
      if (this.passengers[i].account === passenger) {
          result = this.passengers[i].passengerFund;
      }
    }
    return result;
  }

  isOperational(callback) {
    let self = this;
    self.flightSuretyApp.methods
      .isOperational()
      .call({ from: self.owner}, callback);
  }

  fetchFlightStatus(payload, callback) {
    let self = this;
    self.flightSuretyApp.methods
      .fetchFlightStatus(payload.address, payload.flight, payload.time)
      .send({ from: self.owner}, (error, result) => {
        callback(error, payload);
      });
  }
}