import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
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
        tests: "./test",
        cache: "./cache_hardhat",
        artifacts: "./artifacts"
    },
};

export default config;
