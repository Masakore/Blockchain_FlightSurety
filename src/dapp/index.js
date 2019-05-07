
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

  let result = null;

  let contract = new Contract('localhost', () => {

    // Read transaction
    contract.isOperational((error, result) => {

      contract.flights.forEach(flight => {
        displayList(flight, DOM.elid("flights"));
      });

      contract.airlines.forEach(airline => {
        displayListAirline(airline, DOM.elid("airlines"));
      });

      contract.passengers.forEach(passenger => {
        displayListPassenger(passenger, DOM.elid("passengers"));
      });

      console.log(error,result);
      display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
    });

    DOM.elid('register-airline').addEventListener('click', () => {
      let airline = DOM.elid('airline-address').value;
      contract.registerAirline(airline,(error, result) => {
        alert("Airline was successfully registered.");
      });
      DOM.elid('airline-address').value = "";
      displayListAirline(airline, DOM.elid("airlines"));
    });

    DOM.elid('fund-registered-airline').addEventListener('click', () => {
      let airline = DOM.elid('airlines').value;
      let fund = DOM.elid('airline-fund').value;
      contract.sendFundToAirline(airline, fund, (error, result) => {
        alert("Airline was successfully funded.");
      });
    });

    DOM.elid('submit-oracle').addEventListener('click', () => {
      let flight = DOM.elid('flight-number').value;
      let address = DOM.elid('flight-address').value;
      let time = DOM.elid('flight-time').value;
      // Write transaction
      contract.fetchFlightStatus({address: address, flight: flight, time: time}, (error, result) => {
        display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' was succesfully submitted.'} ]);
      });
    });

    DOM.elid('buy').addEventListener('click', () => {
      let passenger = DOM.elid('passengers').value;
      let flight = DOM.elid('flights').value;
      let insurance = DOM.elid('insurance').value;
      if (insurance > 0) {
        contract.buy(passenger, insurance, flight, (error, result) => {
          alert(" insurance.");
        });
      } else {
        alert("Passenger should buy insurance.");
      }
    });

    DOM.elid('show').addEventListener('click', () => {
      let passenger = DOM.elid('passenger-address-for-show').value;
      contract.show(passenger, (error, result) => {
        cosnole.log("Show was successful");
      });
      alert(contract.getFunds(passenger));
    });

    DOM.elid('withdraw').addEventListener('click', () => {
      let passenger = DOM.elid('passenger-address-for-withdraw').value;
      contract.pay(passenger, (error, result) => {
        alert("Successed")
      });
    });

    DOM.elid('flights').addEventListener('change', () => {
      console.log("Hello" + contract.flights);
      return contract.flights;
    });

    DOM.elid('airlines').addEventListener('change', () => {
      return contract.airlines;
    });

  });

  function displayList(flight, parentEl) {
    console.log(flight);
    console.log(parentEl);
    let el = document.createElement("option");
    el.text = `${flight.flight} - ${new Date((flight.timestamp))}`;
    el.value = JSON.stringify(flight);
    parentEl.add(el);
  }

  function displayListAirline(airline, parentEl) {
    let el = document.createElement("option");
    el.text = airline;
    el.value = airline;
    parentEl.add(el);
  }

  function displayListPassenger(passenger, parentEl) {
    let el = document.createElement("option");
    el.text = passenger.account;
    el.value = passenger.account;
    parentEl.add(el);
  }

  function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
      let row = section.appendChild(DOM.div({className:'row'}));
      row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
      row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
      section.appendChild(row);
    })
    displayDiv.append(section);
  }

})();

