import { ethers } from "ethers";

async function main() {
    const owner = "0x5293E6BCbF3D2A8BDA414E7aef1986dfc627d0dC";
    const token = "0xDFdD3aC93A78c03C1F04f3E939E745756B4643d7";

    const abiCoder = new ethers.AbiCoder();
    const encoded = abiCoder.encode(["address", "address"], [owner, token]);

    console.log("Constructor Arguments (ABI-encoded):");
    console.log(encoded);
}

main();
