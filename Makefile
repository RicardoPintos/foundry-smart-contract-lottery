-include .env

.PHONY: build test fork install deploy anvil sepolia

build :; forge build

test :; forge test

fork-test :; forge test --fork-url $(SEPOLIA_RPC_URL)

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit

deploy-anvil:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(LOCAL_RPC_URL) --account anvilKey --broadcast -vvvv

deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account testKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
