import { ethers } from "ethers";
import hre from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
    console.log("Starting deployment (Manual Mode)...\n");
    let networkName = hre.network ? hre.network.name : (process.env.HARDHAT_NETWORK || "unknown");

    if (!networkName || networkName === "undefined" || networkName === "unknown") {
        if (process.argv.includes("optimismSepolia") || process.argv.includes("--network") && process.argv[process.argv.indexOf("--network") + 1] === "optimismSepolia") {
            networkName = "optimismSepolia";
        } else if (process.argv.includes("sepolia") || process.argv.includes("--network") && process.argv[process.argv.indexOf("--network") + 1] === "sepolia") {
            networkName = "sepolia";
        } else if (process.argv.includes("baseSepolia") || process.argv.includes("--network") && process.argv[process.argv.indexOf("--network") + 1] === "baseSepolia") {
            networkName = "baseSepolia";
        }
    }
    console.log("Network Name:", networkName);

    // Determine network settings
    let rpcUrl = "";
    if (networkName === "optimismSepolia") {
        rpcUrl = process.env.OPTIMISM_SEPOLIA_RPC_URL || "https://sepolia.optimism.io";
    } else if (networkName === "sepolia") {
        rpcUrl = process.env.SEPOLIA_RPC_URL || "https://ethereum-sepolia-rpc.publicnode.com";
    } else if (networkName === "baseSepolia") {
        rpcUrl = process.env.BASE_SEPOLIA_RPC_URL || "";
    } else if (networkName === "unichainSepolia") {
        rpcUrl = process.env.UNICHAIN_SEPOLIA_RPC_URL || "";
    } else if (networkName === "arbitrumSepolia") {
        rpcUrl = process.env.ARBITRUM_SEPOLIA_RPC_URL || "";
    } else {
        console.log("Using Hardhat provider config...");
        const config = hre.network.config as any;
        if (config && config.url) {
            rpcUrl = config.url;
        } else {
            // If no URL, maybe we are on hardhat network
            if (networkName === "hardhat" || networkName === "localhost") {
                console.log("Local network detected. Skipping RPC URL check.");
                // For local network we might need a different approach or just skip
            } else {
                throw new Error(`RPC URL not found for network: ${networkName}`);
            }
        }
    }

    const privateKey = process.env.PRIVATE_KEY;
    if (!privateKey) throw new Error("Private key not found");

    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(privateKey, provider);

    console.log("Deploying with account:", wallet.address);
    const balance = await provider.getBalance(wallet.address);
    console.log("Account balance:", ethers.formatEther(balance), "ETH\n");

    // Read artifacts using Hardhat
    const mockTokenArtifact = await hre.artifacts.readArtifact("MockStarkToken");
    const starkOverflowArtifact = await hre.artifacts.readArtifact("StarkOverflow");

    let starkTokenAddress;

    // Deploy MockStarkToken only if NOT on Base Sepolia (or other networks with specific tokens)
    if (networkName === "baseSepolia") {
        console.log("Base Sepolia detected. Using existing WETH as Stark Token.");
        starkTokenAddress = "0x4200000000000000000000000000000000000006";
    } else {
        console.log("Deploying MockStarkToken...");
        const MockStarkTokenFactory = new ethers.ContractFactory(mockTokenArtifact.abi, mockTokenArtifact.bytecode, wallet);
        const starkToken = await MockStarkTokenFactory.deploy();
        await starkToken.waitForDeployment();
        starkTokenAddress = await starkToken.getAddress();
        console.log("MockStarkToken deployed to:", starkTokenAddress);

        // Verify token balance (using contract instance)
        const tokenContract = new ethers.Contract(starkTokenAddress, mockTokenArtifact.abi, wallet);
        const tokenBalance = await tokenContract.balanceOf(wallet.address);
        console.log("Deployer STARK token balance:", ethers.formatEther(tokenBalance), "STARK");
    }

    // Deploy StarkOverflow
    console.log("Deploying StarkOverflow...");
    const StarkOverflowFactory = new ethers.ContractFactory(starkOverflowArtifact.abi, starkOverflowArtifact.bytecode, wallet);
    const starkOverflow = await StarkOverflowFactory.deploy(wallet.address, starkTokenAddress);
    await starkOverflow.waitForDeployment();
    const starkOverflowAddress = await starkOverflow.getAddress();
    console.log("StarkOverflow deployed to:", starkOverflowAddress);

    console.log("\n=== Deployment Summary ===");
    console.log("Network:", hre.network.name);
    console.log("Stark Token:", starkTokenAddress);
    console.log("StarkOverflow:", starkOverflowAddress);
    console.log("Owner:", wallet.address);
    console.log("========================\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
