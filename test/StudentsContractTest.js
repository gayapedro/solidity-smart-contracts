const assert = require("assert");
const Web3 = require("web3");
const {abiJSON, bytecode} = require('../scripts/compile');
const {before, it, describe} = require("mocha");

const provider = new Web3.providers.HttpProvider('HTTP://127.0.0.1:7545');

const web3 = new Web3(provider);

let accounts;
let account_1;
let account_2;
let studentsContract;

before(async () => {
  accounts = await web3.eth.getAccounts();
  account_1 = accounts[0];
  account_2 = accounts[1];
  studentsContract = await new web3.eth.Contract(abiJSON).deploy({data: "0x"+bytecode}).send({from: account_1, gas: 1000000});
})

describe("StudentsContract", () => {
  it("Should return a valid student", async () => {
    const student = {
      name: 'Pedro Gaya',
      age: 29,
    }

    await studentsContract.methods.enrollStudent(student.name, student.age).send({from: account_1, gas: 1000000});
    const savedStudent = await studentsContract.methods.getEnrolledStudentByAddress(account_1).call();

    assert.strictEqual(savedStudent[0], student.name);
    assert.strictEqual(savedStudent[1], student.age.toString());
  })

  it('Should return the default values when the student is not found', async () => {
    const student = await studentsContract.methods.getEnrolledStudentByAddress(account_2).call();

    assert.strictEqual(student[0], '');
    assert.strictEqual(student[1], '0');
  })
})