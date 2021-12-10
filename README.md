# **PCS-Project**
## **References**
1. **Battleship: https://courses.csail.mit.edu/6.857/2020/projects/13-Gupta-Kaashoek-Wang-Zhao.pdf**
2. GANACHE: https://www.trufflesuite.com/docs/ganache/overview
3. TRUFFLE: https://www.trufflesuite.com/docs/truffle/overview
4. Solidity: https://docs.soliditylang.org/en/v0.8.10/introduction-to-smart-contracts.html#a-simple-smart-contract
5. Snarkjs: https://github.com/iden3/snarkjs
6. Circom: https://docs.circom.io/getting-started/installation/
7. **(UPDATE) web3.js: https://web3js.readthedocs.io/en/v1.5.2/**
## **Source code**
1. Online-Junqi: https://github.com/samuelyuan/online-junqi
## **Hello World of Smart Contract**
1. https://blog.logrocket.com/develop-test-deploy-smart-contracts-ganache/
2. **(UPDATE)metamask with ganache: https://www.trufflesuite.com/docs/truffle/getting-started/truffle-with-metamask**
3. **(UPDATE)web3.js https://www.dappuniversity.com/articles/how-to-build-a-blockchain-app**
## **Hello World of Snarkjs**
1. https://github.com/iden3/snarkjs
## **Directory Layout**
1. circom: zksnark circuit for computing finishSetup and move proof
  - move/move.circom
  - finishSetup/finishSetup.circom
2. mpc/garbled: garbler circuit for comparing ranks of two players
  - examples/junqi.mpcl
3. public
  - js/lib: code for game logic
  - js/client.js: main code of client, used for communicating with smart contract, update UI, etc.
  - json: Application Binary Interface(ABI) for Ethereum smart contract
## **How to build this project**
1. Run Ganache
2. Deploy smart_contract
  - cd smart_contract
  - truffle migrate
  - truffle migrate --reset (used for resetting smart_contract)
3. Compile MPC garbled
  - cd mpc/garbled
  - go mod tidy
  - go build 
5. Run frontend server
  - npm install
  - node server.js
6. Need two different browsers (firefox, chrome, edge)
  - Install Metamask extension for these browsers
  - add network(HTTP://127.0.0.1:7545, chain ID: 1337)
  - import accounts for different browsers (private key in Ganache)
