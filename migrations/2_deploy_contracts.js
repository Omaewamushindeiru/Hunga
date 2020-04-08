const SafeMath = artifacts.require("SafeMath");
const Counters = artifacts.require("Counters");
const ERC721 = artifacts.require("ERC721");
const ERC20 = artifacts.require("ERC20");
const Jungle = artifacts.require("Jungle");
const Crowdsale = artifacts.require("Crowdsale");

const name = "BaNaneMitraille";
const ticker = "BNM";
const totalSupply = 10**12;
const decimals = 16;

module.exports = function(deployer, network) {
  if (network === "development") {
    return deployer
      .then(() => deployer.deploy(SafeMath))
      .then(() => deployer.link(SafeMath, Counters))
      .then(() => deployer.link(SafeMath, ERC20))
      .then(() => deployer.link(SafeMath, ERC721))
      .then(() => deployer.link(SafeMath, Jungle))
      .then(() => deployer.link(SafeMath, Crowdsale))
      .then(() => deployer.deploy(Counters))
      .then(() => deployer.link(Counters, ERC721))
      .then(() => deployer.deploy(ERC20, name, ticker, totalSupply, decimals))
      .then(() => deployer.deploy(ERC721))
      .then(() => deployer.deploy(Jungle, ERC721.address, ERC20.address))
      .then(() => deployer.deploy(Crowdsale, 1, 1, 10**6, ERC20.address))   
      .then(() => ERC20.deployed())
      .then(ERC20Instance => { ERC20Instance.addTrusted(Jungle.address); });
  }
};