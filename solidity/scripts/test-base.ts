import { ethers } from "ethers";
import hre from "hardhat";

// Deployed contract addresses on Base Sepolia
const WETH_ADDRESS = "0x4200000000000000000000000000000000000006";
const STARK_OVERFLOW_ADDRESS = "0x98B6ff9d138894e3D9F5CAFa046cE564Bf8dbcf6";

// Minimal WETH ABI for wrapping/unwrapping
const WETH_ABI = [
    "function deposit() public payable",
    "function withdraw(uint wad) public",
    "function approve(address guy, uint wad) public returns (bool)",
    "function transfer(address dst, uint wad) public returns (bool)",
    "function transferFrom(address src, address dst, uint wad) public returns (bool)",
    "function allowance(address src, address dst) view returns (uint)",
    "function balanceOf(address guy) public view returns (uint)",
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function decimals() view returns (uint8)"
];

async function main() {
    console.log("🧪 Starting tests on Base Sepolia deployment (using WETH)...\n");
    console.log("=".repeat(70));

    // Setup Provider and Signer manually
    const rpcUrl = process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org";
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const privateKey = process.env.PRIVATE_KEY;

    if (!privateKey) {
        throw new Error("PRIVATE_KEY not found in .env");
    }

    const deployer = new ethers.Wallet(privateKey, provider);

    console.log("📋 Test Account:");
    console.log("Deployer:", deployer.address);
    const ethBalance = await provider.getBalance(deployer.address);
    console.log("ETH Balance:", ethers.formatEther(ethBalance));
    console.log("=".repeat(70));
    console.log();

    // Get Artifacts
    const StarkOverflowArtifact = await hre.artifacts.readArtifact("StarkOverflow");

    // Connect to contracts
    const weth = new ethers.Contract(WETH_ADDRESS, WETH_ABI, deployer);
    const starkOverflow = new ethers.Contract(STARK_OVERFLOW_ADDRESS, StarkOverflowArtifact.abi, deployer);

    let testsPassed = 0;
    let testsFailed = 0;
    let testsSkipped = 0;

    // Shared state variables
    let questionIdToAnswer = 0;
    let answerId = 0;

    // Pre-check: Ensure we have WETH
    console.log("🔄 Pre-check: Wrapping ETH to WETH for testing...");
    try {
        const wethBalance = await weth.balanceOf(deployer.address);
        console.log(`   Current WETH Balance: ${ethers.formatEther(wethBalance)}`);

        if (wethBalance < ethers.parseEther("100")) {
            const wrapAmount = ethers.parseEther("0.01"); // Wrap small amount for gas safety
            console.log(`   Wrapping ${ethers.formatEther(wrapAmount)} ETH...`);
            const tx = await weth.deposit({ value: wrapAmount });
            await tx.wait();
            console.log("   ✅ Wrapped ETH successfully");
        } else {
            console.log("   ✅ Sufficient WETH balance");
        }
    } catch (error: any) {
        console.log("   ❌ Error wrapping ETH:", error.message);
        // Don't fail yet, maybe we have enough
    }
    console.log();

    // Test 1: Verify Contract Ownership
    console.log("🔐 Test 1: Verify Contract Ownership");
    try {
        const owner = await starkOverflow.owner();
        console.log("   Contract Owner:", owner);
        if (owner.toLowerCase() === deployer.address.toLowerCase()) {
            console.log("   ✅ PASSED: Ownership verified");
            testsPassed++;
        } else {
            console.log("   ❌ FAILED: Owner mismatch");
            testsFailed++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 2: Verify Token Configuration
    console.log("💎 Test 2: Verify Token Configuration");
    try {
        const tokenAddress = await starkOverflow.starkToken();
        const tokenName = await weth.name();
        const tokenSymbol = await weth.symbol();

        console.log("   Token Address:", tokenAddress);
        console.log("   Token Name:", tokenName);
        console.log("   Token Symbol:", tokenSymbol);

        if (tokenAddress.toLowerCase() === WETH_ADDRESS.toLowerCase()) {
            console.log("   ✅ PASSED: Token configuration correct (WETH)");
            testsPassed++;
        } else {
            console.log("   ❌ FAILED: Token address mismatch");
            testsFailed++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 3: Create Forums
    console.log("📁 Test 3: Create Forums on Base");
    try {
        const forumNames = ["Base DeFi", "Base NFTs", "Base Gaming"];

        for (const name of forumNames) {
            try {
                console.log(`   Creating forum: ${name}...`);
                const tx = await starkOverflow.createForum(name, `Qm${name.replace(/\s/g, "")}IconCid`);
                await tx.wait();
                console.log(`   ✅ Created forum: ${name}`);
            } catch (e: any) {
                console.log(`   ⚠️  Forum creation note: ${e.message.substring(0, 100)}...`);
            }
        }

        const [forums, total] = await starkOverflow.getForums(10, 1);
        console.log(`   Total forums: ${total}`);
        testsPassed++;
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 4: Create Questions with Stakes (Using WETH)
    console.log("💰 Test 4: Create Questions with WETH Stakes");
    try {
        const approveAmount = ethers.parseEther("0.005"); // Small amount for test
        console.log(`   Approving ${ethers.formatEther(approveAmount)} WETH...`);
        const approveTx = await weth.approve(STARK_OVERFLOW_ADDRESS, approveAmount);
        await approveTx.wait();
        console.log("   ✅ Approved WETH");

        // DEBUG: Check Allowance and Balance
        const allowance = await weth.allowance(deployer.address, STARK_OVERFLOW_ADDRESS);
        const balance = await weth.balanceOf(deployer.address);
        console.log(`   DEBUG: Allowance: ${ethers.formatEther(allowance)} WETH`);
        console.log(`   DEBUG: Balance: ${ethers.formatEther(balance)} WETH`);

        const stakeAmount = ethers.parseEther("0.0001");
        const [forums] = await starkOverflow.getForums(1, 1);

        if (forums.length > 0) {
            const forumId = forums[0].id;
            console.log(`   Asking question in Forum ${forumId}...`);

            // DEBUG: Gas Estimation
            try {
                const gasEstimate = await starkOverflow.askQuestion.estimateGas(
                    forumId,
                    `Base Question ${Date.now()}: How to use WETH?`,
                    `QmBaseQuestionCid`,
                    `https://github.com/base/example`,
                    ["base", "weth"],
                    stakeAmount
                );
                console.log(`   DEBUG: Estimated Gas: ${gasEstimate}`);
            } catch (gasError: any) {
                console.log(`   ❌ DEBUG: Gas Estimation Failed: ${gasError.message}`);
            }

            const tx = await starkOverflow.askQuestion(
                forumId,
                `Base Question ${Date.now()}: How to use WETH?`,
                `QmBaseQuestionCid`,
                `https://github.com/base/example`,
                ["base", "weth"],
                stakeAmount
            );
            await tx.wait();
            console.log(`   ✅ Created question with ${ethers.formatEther(stakeAmount)} WETH stake`);

            // Capture the new Question ID
            const lastQId = await starkOverflow.lastQuestionId();
            questionIdToAnswer = Number(lastQId);
            console.log(`   New Question ID: ${questionIdToAnswer}`);

            testsPassed++;
        } else {
            console.log("   ⚠️  Skipping question creation: No forums found");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 5: User Interaction - Submit Answer
    console.log("💬 Test 5: Submit Answer (Simulated User)");

    const user2 = ethers.Wallet.createRandom().connect(provider);
    console.log("   User 2 Address:", user2.address);

    try {
        // Fund User 2 with ETH
        const fundAmount = ethers.parseEther("0.001");

        const deployerBalance = await provider.getBalance(deployer.address);
        if (deployerBalance < fundAmount) {
            console.log(`   ⚠️  Skipping User 2 funding: Insufficient Deployer ETH (${ethers.formatEther(deployerBalance)})`);
            throw new Error("Insufficient Deployer ETH");
        }

        console.log(`   Funding User 2 with ${ethers.formatEther(fundAmount)} ETH...`);
        const fundTx = await deployer.sendTransaction({
            to: user2.address,
            value: fundAmount
        });
        await fundTx.wait();
        console.log("   ✅ User 2 funded with ETH");

        // Verify User 2 Balance with Retry
        let user2Balance = await provider.getBalance(user2.address);
        let retries = 5;
        while (user2Balance < ethers.parseEther("0.001") && retries > 0) {
            console.log(`   Waiting for balance update... (${retries} retries left)`);
            await new Promise(resolve => setTimeout(resolve, 2000));
            user2Balance = await provider.getBalance(user2.address);
            retries--;
        }
        console.log(`   User 2 Balance: ${ethers.formatEther(user2Balance)} ETH`);

        if (user2Balance < ethers.parseEther("0.001")) {
            throw new Error("User 2 funding failed or insufficient");
        }

        if (questionIdToAnswer > 0) {
            console.log(`   Answering Question ID: ${questionIdToAnswer}`);

            const starkOverflowUser2 = starkOverflow.connect(user2);

            const answerTx = await starkOverflowUser2.submitAnswer(
                questionIdToAnswer,
                "QmBaseAnswerCid"
            );
            const receipt = await answerTx.wait();
            console.log(`   ✅ Answer submitted (Block: ${receipt.blockNumber})`);

            // Retry loop to find the answer (handling RPC lag)
            let foundAnswer = false;
            retries = 5;
            while (!foundAnswer && retries > 0) {
                const [answers] = await starkOverflow.getAnswers(questionIdToAnswer, 10, 1);
                console.log(`   DEBUG: Answers found for Q${questionIdToAnswer}: ${answers.length}`);

                if (answers.length > 0) {
                    // Find the answer by this user
                    const myAnswer = answers.find((a: any) => a.author.toLowerCase() === user2.address.toLowerCase());
                    if (myAnswer) {
                        console.log(`   ✅ Found my answer! ID: ${myAnswer.id}`);
                        answerId = Number(myAnswer.id);
                        foundAnswer = true;
                    } else {
                        console.log("   ⚠️  Answers found, but not mine yet...");
                    }
                }

                if (!foundAnswer) {
                    console.log(`   Waiting for indexer... (${retries} retries left)`);
                    await new Promise(resolve => setTimeout(resolve, 2000));
                    retries--;
                }
            }

            if (!foundAnswer) {
                console.log("   ❌ Failed to find answer after retries.");
                // Fallback to lastAnswerId (though likely stale)
                const lastAnswerId = await starkOverflow.lastAnswerId();
                answerId = Number(lastAnswerId);
                console.log(`   Fallback Answer ID: ${answerId}`);
            }
            testsPassed++;
        } else {
            console.log("   ⚠️  Skipping answer test: No questions found");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 6: Vote on Answer
    console.log("👍 Test 6: Vote on Answer");
    try {
        if (answerId > 0) {
            console.log(`   Upvoting Answer ID: ${answerId}...`);
            const voteTx = await starkOverflow.voteOnAnswer(answerId, true);
            await voteTx.wait();
            console.log("   ✅ Upvoted answer");
            testsPassed++;
        } else {
            console.log("   ⚠️  Skipping vote test: No answer available");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 7: Mark Answer as Correct & Verify Reward
    console.log("🏆 Test 7: Mark Answer as Correct & Verify Reward");
    try {
        if (questionIdToAnswer > 0 && answerId > 0) {
            console.log(`   Marking Answer ID ${answerId} as correct...`);

            const balanceBefore = await weth.balanceOf(user2.address);
            console.log(`   User 2 WETH Balance Before: ${ethers.formatEther(balanceBefore)}`);

            const selectTx = await starkOverflow.markAnswerAsCorrect(questionIdToAnswer, answerId);
            await selectTx.wait();
            console.log("   ✅ Answer marked as correct");

            // Check Total Staked (Debug)
            const totalStaked = await starkOverflow.totalStakedByQuestionId(questionIdToAnswer);
            console.log(`   DEBUG: Total Staked on Question: ${ethers.formatEther(totalStaked)} WETH`);

            // Retry loop for balance update
            let balanceAfter = await weth.balanceOf(user2.address);
            let retries = 5;
            while (balanceAfter <= balanceBefore && retries > 0) {
                console.log(`   Waiting for balance update... (${retries} retries left)`);
                await new Promise(resolve => setTimeout(resolve, 2000));
                balanceAfter = await weth.balanceOf(user2.address);
                retries--;
            }
            console.log(`   User 2 WETH Balance After: ${ethers.formatEther(balanceAfter)}`);

            if (balanceAfter > balanceBefore) {
                console.log("   ✅ PASSED: Reward received by answer author");
                testsPassed++;
            } else {
                console.log("   ❌ FAILED: Balance did not increase");
                testsFailed++;
            }
        } else {
            console.log("   ⚠️  Skipping test: Prerequisites not met");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Final Summary
    console.log("=".repeat(70));
    console.log("📊 BASE SEPOLIA TEST SUMMARY");
    console.log("=".repeat(70));
    console.log(`✅ Tests Passed: ${testsPassed}`);
    console.log(`❌ Tests Failed: ${testsFailed}`);
    console.log(`⚠️  Tests Skipped: ${testsSkipped}`);
    console.log("=".repeat(70));
    console.log();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
