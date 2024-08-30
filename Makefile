-include .env

build:
	forge build

test-report:
	forge test --gas-report

coverage:
	forge coverage

deploy: 
	forge script script/EcoChainDeploy.s.sol:EcoChainDeploy --rpc-url ${ALCHEMY_URL} --private-key ${PRIVATE_KEY} --broadcast --etherscan-api-key ${ETHERSCAN_KEY} --verify