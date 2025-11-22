// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/StarkOverflow.sol";
import "../src/MockStarkToken.sol";

contract DeployStarkOverflow is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Mock Token (Optional: Only if you don't have a token yet)
        // In production, you would use an existing ERC20 address.
        // For testnet, we can deploy a mock one.
        MockStarkToken token = new MockStarkToken();
        console.log("MockStarkToken deployed at:", address(token));

        // 2. Deploy StarkOverflow
        // Pass the deployer as the initial owner and the token address
        StarkOverflow starkOverflow = new StarkOverflow(msg.sender, address(token));
        console.log("StarkOverflow deployed at:", address(starkOverflow));

        vm.stopBroadcast();
    }
}
