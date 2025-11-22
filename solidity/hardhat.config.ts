import { createRequire } from "module";
// import toolbox from "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import "@nomicfoundation/hardhat-ethers";
import * as dotenv from "dotenv";

// Attempt dynamic import for verify
import("@nomicfoundation/hardhat-verify").catch(err => console.error("Failed to load hardhat-verify:", err));

dotenv.config();

const config: HardhatUserConfig = {
    // ...toolbox,
    solidity: {
        version: "0.8.20",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            },
            viaIR: true
        }
    },
    paths: {
        sources: "./src",
        cache: "./cache_hardhat",
        artifacts: "./artifacts"
    },
    networks: {
        baseSepolia: {
            type: "http",
            url: process.env.BASE_SEPOLIA_RPC_URL || "",
            accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
            chainId: 84532
        },
        unichainSepolia: {
            type: "http",
            url: process.env.UNICHAIN_SEPOLIA_RPC_URL || "https://sepolia.unichain.org",
            accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
            chainId: 1301
        },
        arbitrumSepolia: {
            type: "http",
            url: process.env.ARBITRUM_SEPOLIA_RPC_URL || "",
            accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
            chainId: 421614
        },
        optimismSepolia: {
            type: "http",
            url: process.env.OPTIMISM_SEPOLIA_RPC_URL || "https://sepolia.optimism.io",
            accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
            chainId: 11155420
        },
        sepolia: {
            type: "http",
            url: process.env.SEPOLIA_RPC_URL || "https://ethereum-sepolia-rpc.publicnode.com",
            accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
            chainId: 11155111
        }
    },
    etherscan: {
        apiKey: {
            sepolia: process.env.ETHERSCAN_API_KEY || "",
            optimismSepolia: process.env.ETHERSCAN_API_KEY || "",
            baseSepolia: process.env.BASESCAN_API_KEY || "",
            arbitrumSepolia: process.env.ARBISCAN_API_KEY || ""
        },
        customChains: [
            {
                network: "baseSepolia",
                chainId: 84532,
                urls: {
                    apiURL: "https://api-sepolia.basescan.org/api",
                    browserURL: "https://sepolia.basescan.org"
                }
            },
            {
                network: "unichainSepolia",
                chainId: 1301,
                urls: {
                    apiURL: "https://api-sepolia.uniscan.xyz/api",
                    browserURL: "https://sepolia.uniscan.xyz"
                }
            },
            {
                network: "arbitrumSepolia",
                chainId: 421614,
                urls: {
                    apiURL: "https://api-sepolia.arbiscan.io/api",
                    browserURL: "https://sepolia.arbiscan.io"
                }
            },
            {
                network: "optimismSepolia",
                chainId: 11155420,
                urls: {
                    apiURL: "https://api-sepolia-optimistic.etherscan.io/api",
                    browserURL: "https://sepolia-optimism.etherscan.io"
                }
            }
        ]
    }
};

export default config;
