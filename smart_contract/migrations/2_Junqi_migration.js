// Help Truffle find `TruffleTutorial.sol` in the `/contracts` directory
const Junqi = artifacts.require("Junqi");

module.exports = function(deployer) {
  // Command Truffle to deploy the Smart Contract
  deployer.deploy(Junqi);
};