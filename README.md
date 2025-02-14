# Foundry Smart Contract Lottery

With this Foundry project you can create raffles, deploy them to a blockchain network and fetch a random number from Chainlink Vrf to choose a winner. It was made for the Foundry Fundamentals course of Cyfrin Updraft.

<br>

- [Foundry Smart Contract Lottery](#foundry-smart-contract-lottery)
- [Getting Started](#getting-started)
  * [Requirements](#requirements)
  * [Quickstart](#quickstart)
- [Usage](#usage)
  * [Libraries](#libraries)
  * [Testing](#testing)
    + [Integration tests](#integration-tests)
    + [Test Coverage](#test-coverage)
  * [Estimate gas](#estimate-gas)
  * [Formatting](#formatting)
- [Deploy](#deploy)
  * [Private Key Encryption](#private-key-encryption)
  * [Deployment to local Anvil](#deployment-to-local-anvil)
    + [Preparation](#preparation)
    + [Deployment](#deployment)
    + [Result](#result)
  * [Deployment to Sepolia testnet](#deployment-to-sepolia-testnet)
    + [Preparation](#preparation-1)
    + [Deployment](#deployment-1)
    + [Result](#result-1)
- [Acknowledgments](#acknowledgments)
- [Thank you](#thank-you)

<br>

![LokapalBanner](https://github.com/user-attachments/assets/5509e1f8-9f31-4141-8975-02132a1ba63e)

<br>

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```
git clone https://github.com/RicardoPintos/foundry-smart-contract-lottery
cd foundry-smart-contract-lottery
forge build
```

<br>

# Usage

## Libraries

This project uses the following libraries:

- [Chainlink-brownie-contracts (version 1.1.1)](https://github.com/smartcontractkit/chainlink-brownie-contracts)
- [Cyfrin-foundry-devops (version 0.2.2)](https://github.com/Cyfrin/foundry-devops)
- [Foundry-forge-std (version 1.8.2)](https://github.com/foundry-rs/forge-std)
- [Transmissions11-Solmate (version 6)](https://github.com/transmissions11/solmate)

You can install all of them with the following Makefile command:

```
make install
```

## Testing

To run every test:

```
forge test
```

You can also perform a **forked test**. If you have an [Alchemy](https://www.alchemy.com) account, you can set up a Sepolia node, add it to your .env file with the flag $SEPOLIA_RPC_URL and run:

```
source .env
forge test --fork-url $SEPOLIA_RPC_URL
```

### Integration tests

The tests in "test/integration/Integrations.t.sol" on this repo were made as an optional assignment for the Foundry Fundamentals Course of Cyfrin Updraft. I made them in order to practice integration tests in Solidity. Therefore they are not for production and their validity is not guaranteed.

### Test Coverage

To check the test coverage of this project, run:

```
forge coverage
```

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see an output file called `.gas-snapshot`

## Formatting

To run code formatting:

```
forge fmt
```

<br>

# Deploy

## Private Key Encryption

It is recommended to work with encrypted private keys for both Anvil and Sepolia. The following method is an example for Anvil. If you want to deploy to Sepolia, repeat this process with the private key and address of your **test wallet**.

In your local terminal, run this:

```
cast wallet import <Choose_Your_Anvil_Account_Name> --interactive
```

Paste your private key, hit enter and then create a password for that key. 

<br>

For this project, it is recommended to use the **first** Anvil private key. If you use a different Anvil key, you'll need to modify the account address of the localNetworkConfig in the HelperConfig.s.sol contract to the address of the private key that you will be using.

<br>

Now, you can use the `--account` flag instead of `--private-key`. You'll need to type your password when is needed. To check all of your encrypted keys, run this:

```
cast wallet list
```

<br>

## Deployment to local Anvil

### Preparation

There is currently an issue with the subscription Id creation when you tried to deploy to Anvil. If you try to use the DeployRaffle script, Foundry will revert with this error:

```
Error: script failed: panic: arithmetic underflow or overflow (0x11)
```

The following fix was proposed by [Petar Ivanov](https://github.com/PetarIvanov01). To fix it, you need to modify the code on the contract SubscriptionAPI.sol from the "Chainlink brownie contracts" library. On the "createSubscription()" function of this contract, you'll find this lines:

```
subId = uint256(
      keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1), address(this), currentSubNonce))
    );
```

You have to remove the "- 1", because that is the source of the underflow. You'll end up with this:

```
subId = uint256(
      keccak256(abi.encodePacked(msg.sender, blockhash(block.number), address(this), currentSubNonce))
    );
```

### Deployment

First you need to run Anvil on your terminal:

```
anvil
```

Then you open another terminal and run this:

```
forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url http://127.0.0.1:8545 --account <Your_Encrypted_Anvil_Private_Key_Account_Name> --broadcast -vvvv
```

We are not using the default Foundry sender, because it returns this error:

```
Error: You seem to be using Foundry's default sender. Be sure to set your own --sender.
```

### Result

This deployment will do this:
1. Create a raffle,
2. Add a subscription,
3. Fund that subscription,
4. Add your raffle as a consumer to that subscription Id.

<br>

This raffle is running with a mock Vrf contract, therefore it will not have the Chainlink Automation functionality that is available in the rest of the Raffle.sol code.

<br>

## Deployment to Sepolia testnet

### Preparation

There is currently an issue with the subscription Id creation when you tried to deploy to Sepolia. If you try to use the DeployRaffle script, Foundry will revert with and **InvalidSubscription** error in both the `transferAndCall()` and the `addConsumer()` functions.

<br>

This is an issue with the Foundry on-chain simulation. It ends up creating a different subscription Id from the one that the `fundSubscription()` and `addConsumer()` functions are using. So you need to skip the build-in `createSubscription()` functionality by having a subscription Id before deployment.

<br>

Here are the steps needed:
1. Create a subscription on the Chainlink VRF website,
2. Copy your new subscription Id,
3. Open the HelperConfig.s.sol contract of this project,
4. Find the getSepoliaEthConfig() function,
5. Paste your new subscription Id on the NetworkConfig.

<br>

**Don't forget** to fund your new subscription with LINK so it can perform correctly on deployment.

### Deployment

When you complete the preparation, run this:

```
forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url <Your_Alchemy_Sepolia_Node_Url> --account <Your_Encrypted_Sepolia_Private_Key_Account_Name> --broadcast -vvvv
```

If you have an Etherscan API key, you can verify your contract alongside the deployment by running this instead:

```
forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url <Your_Alchemy_Sepolia_Node_Url> --account <Your_Encrypted_Sepolia_Private_Key_Account_Name> --broadcast --verify --etherscan-api-key <Your_Etherscan_Api_Key> -vvvv
```

If your contract wasn't properly verified on deployment, you can manually do it on the Ethescan UI by running this:

```
forge verify-contract <Your_Raffle_Address> src/Raffle.sol:Raffle --etherscan-api-key <Your_Etherscan_Api_key> --rpc-url <Your_Alchemy_Sepolia_Node_Url> --show-standard-json-input > json.json
```

### Result

This deployment will do this:
1. Create a raffle,
2. Set up the subscription Id that was created, funded and manually added to the code,
4. Add your raffle as a consumer to that subscription Id.

<br>

After deployment you can interact with the raffle like this:
1. Register a new Upkeep on Chainlink Automation UI with the raffle address using a Custom Logic trigger.
2. Use the Etherscan UI to start the raffle by adding players.
3. After the upkeep interval is completed, check the address of the randomly selected winner.

<br>

# Acknowledgments

Thanks to the Cyfrin Updraft team and to Patrick Collins for their amazing work. Please check out their courses on [Cyfrin Updraft](https://updraft.cyfrin.io/courses).
<br>
Thanks to [EngrPips](https://github.com/EngrPips) for the help with the Foundry on-chain Simulation issues.
<br>
Thanks to [Petar Ivanov](https://github.com/PetarIvanov01) for sharing the arithmetic underflow fix.

<br>

# Thank you

If you appreciated this, feel free to follow me!

[![Ricardo Pintos Twitter](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=x&logoColor=white)](https://x.com/pintosric)
[![Ricardo Pintos Linkedin](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ricardo-mauro-pintos/)
[![Ricardo Pintos YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@PintosRic)

![EthereumBanner](https://github.com/user-attachments/assets/8a1c6e53-2e66-4256-9312-252a0360b7df)
