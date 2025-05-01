const fs = require('fs');
const faker = require('@faker-js/faker').faker;

const states = ['MP', 'MH', 'DL', 'KA', 'UP', 'RJ', 'TN', 'GJ', 'PB', 'CG'];
const vehicleTypes = ['Bike', 'Car', 'Truck'];
const companies = {
    Bike: ['Hero', 'Bajaj', 'TVS'],
    Car: ['Maruti Suzuki', 'Hyundai', 'Toyota', 'Renault', 'Mahindra'],
    Truck: ['Tata', 'Ashok Leyland', 'Eicher']
};

function generateVehicleNumber(stateCode) {
    const rto = String(faker.number.int({ min: 1, max: 99 })).padStart(2, '0');
    const series = faker.string.alpha({ length: 2 }).toUpperCase();
    const number = faker.number.int({ min: 1000, max: 9999 });
    return `${stateCode} ${rto} ${series} ${number}`;
}

function generateVehicle() {
    const state = faker.helpers.arrayElement(states);
    const type = faker.helpers.arrayElement(vehicleTypes);
    const company = faker.helpers.arrayElement(companies[type]);
    const model = faker.vehicle.model();
    const manufactureDate = faker.date.between({ from: '2018-01-01', to: '2023-12-31' });
    const registrationDate = faker.date.between({ from: manufactureDate, to: '2024-12-31' });
    const insuranceExpiry = faker.date.future({ years: 2 });

    return {
        vehicle_number: generateVehicleNumber(state),
        vehicle_type: type,
        company: company,
        model: model,
        engine_type: faker.helpers.arrayElement(['Petrol', 'Diesel', 'Electric']),
        engine_horse_power: `${faker.number.int({ min: 80, max: 400 })} HP`,
        engine_strokes: faker.helpers.arrayElement([2, 4]),
        date_of_manufacturing: manufactureDate.toISOString().split('T')[0],
        registration_date: registrationDate.toISOString().split('T')[0],
        insurance_expiry: insuranceExpiry.toISOString().split('T')[0],
        fuel_tank_capacity: `${faker.number.int({ min: 10, max: 100 })}L`,
        owner_name: faker.person.fullName(),
        registration_state: state,
        fuel_type: faker.helpers.arrayElement(['Petrol', 'Diesel', 'Electric']),
        emission_standard: faker.helpers.arrayElement(['BS-IV', 'BS-VI'])
    };
}

const vehicles = Array.from({ length: 200 }, generateVehicle);

fs.writeFileSync('vehicles.json', JSON.stringify(vehicles, null, 2));
console.log('✅ 200 vehicle records generated in vehicles.json');
