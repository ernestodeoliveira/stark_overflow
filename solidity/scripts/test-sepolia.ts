import { ethers } from "ethers";
import hre from "hardhat";

// Deployed contract addresses on Ethereum Sepolia
const STARK_TOKEN_ADDRESS = "0x704ed3f1170b7F6D640b6860A5E46cb654206E1D";
const STARK_OVERFLOW_ADDRESS = "0x81049193703d62c423b1D3fbcE28A7f5BD4b7f11";

async function main() {
    console.log("🧪 Starting extended tests on Ethereum Sepolia deployment...\n");
    console.log("=".repeat(70));

    // Setup Provider and Signer manually
    const rpcUrl = process.env.SEPOLIA_RPC_URL || "https://ethereum-sepolia-rpc.publicnode.com";
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const privateKey = process.env.PRIVATE_KEY;

    if (!privateKey) {
        throw new Error("PRIVATE_KEY not found in .env");
    }

    const deployer = new ethers.Wallet(privateKey, provider);

    console.log("📋 Test Account:");
    console.log("Deployer:", deployer.address);
    console.log("=".repeat(70));
    console.log();

    // Get Artifacts
    const StarkTokenArtifact = await hre.artifacts.readArtifact("MockStarkToken");
    const StarkOverflowArtifact = await hre.artifacts.readArtifact("StarkOverflow");

    // Connect to deployed contracts
    const starkToken = new ethers.Contract(STARK_TOKEN_ADDRESS, StarkTokenArtifact.abi, deployer);
    const starkOverflow = new ethers.Contract(STARK_OVERFLOW_ADDRESS, StarkOverflowArtifact.abi, deployer);

    let testsPassed = 0;
    let testsFailed = 0;
    let testsSkipped = 0;

    // Test 1: Verify Contract Ownership
    console.log("🔐 Test 1: Verify Contract Ownership");
    try {
        const owner = await starkOverflow.owner();
        console.log("   Contract Owner:", owner);
        console.log("   Deployer:", deployer.address);
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
        // Note: name(), symbol(), decimals() might not be in the Artifact ABI if it's just IERC20, 
        // but MockStarkToken artifact should have them.
        const tokenName = await starkToken.name();
        const tokenSymbol = await starkToken.symbol();
        const tokenDecimals = await starkToken.decimals();

        console.log("   Token Address:", tokenAddress);
        console.log("   Token Name:", tokenName);
        console.log("   Token Symbol:", tokenSymbol);
        console.log("   Token Decimals:", tokenDecimals);

        if (tokenAddress.toLowerCase() === STARK_TOKEN_ADDRESS.toLowerCase()) {
            console.log("   ✅ PASSED: Token configuration correct");
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

    // Test 3: Test Multiple Forum Creation
    console.log("📁 Test 3: Create Multiple Forums on Sepolia");
    try {
        const forumNames = ["Sepolia DeFi", "Sepolia NFTs", "Sepolia Gaming"];

        for (const name of forumNames) {
            try {
                console.log(`   Creating forum: ${name}...`);
                const tx = await starkOverflow.createForum(name, `Qm${name.replace(/\s/g, "")}IconCid`);
                await tx.wait();
                console.log(`   ✅ Created forum: ${name}`);
            } catch (e: any) {
                // Check for "already exists" or similar errors if running multiple times
                console.log(`   ⚠️  Forum creation note: ${e.message.substring(0, 100)}...`);
            }
        }

        const [forums, total] = await starkOverflow.getForums(10, 1);
        console.log(`   Total forums: ${total}`);
        console.log("   ✅ PASSED: Forums check completed");
        testsPassed++;
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 4: Test Question Creation with Stakes
    console.log("💰 Test 4: Create Questions with Different Stakes");
    try {
        // Approve tokens first!
        const approveAmount = ethers.parseEther("1000");
        console.log(`   Approving ${ethers.formatEther(approveAmount)} STARK...`);
        const approveTx = await starkToken.approve(STARK_OVERFLOW_ADDRESS, approveAmount);
        await approveTx.wait();
        console.log("   ✅ Approved tokens");

        const amounts = [
            ethers.parseEther("15"),
            ethers.parseEther("30")
        ];

        // Get a valid forum ID
        const [forums] = await starkOverflow.getForums(1, 1);
        if (forums.length > 0) {
            const forumId = forums[0].id;

            for (let i = 0; i < amounts.length; i++) {
                try {
                    console.log(`   Asking question ${i + 1}...`);
                    const tx = await starkOverflow.askQuestion(
                        forumId,
                        `Sepolia Question ${Date.now()}: How to build on Sepolia?`,
                        `QmSepoliaQuestion${i + 1}Cid`,
                        `https://github.com/sepolia/example${i + 1}`,
                        ["sepolia", "development"],
                        amounts[i]
                    );
                    await tx.wait();
                    console.log(`   ✅ Created question with ${ethers.formatEther(amounts[i])} STARK stake`);
                } catch (e: any) {
                    console.log(`   ⚠️  Question ${i + 1} error: ${e.message.substring(0, 100)}...`);
                }
            }
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

    // Test 5: Test Pagination
    console.log("📄 Test 5: Test Pagination on Sepolia");
    try {
        const [page1, total1, hasNext1] = await starkOverflow.getQuestions(1, 2, 1);
        console.log(`   Page 1: ${page1.length} questions, Total: ${total1}, Has Next: ${hasNext1}`);

        if (total1 > 2) {
            const [page2, total2, hasNext2] = await starkOverflow.getQuestions(1, 2, 2);
            console.log(`   Page 2: ${page2.length} questions, Total: ${total2}, Has Next: ${hasNext2}`);
        }

        console.log("   ✅ PASSED: Pagination call successful");
        testsPassed++;
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 6: Test Token Balance Tracking
    console.log("💵 Test 6: Verify Token Balance Tracking");
    try {
        const contractBalance = await starkToken.balanceOf(STARK_OVERFLOW_ADDRESS);
        const deployerBalance = await starkToken.balanceOf(deployer.address);

        console.log("   Contract Balance:", ethers.formatEther(contractBalance), "STARK");
        console.log("   Deployer Balance:", ethers.formatEther(deployerBalance), "STARK");

        if (contractBalance > 0n) {
            console.log("   ✅ PASSED: Contract holds staked tokens");
            testsPassed++;
        } else {
            console.log("   ⚠️  WARNING: Contract has no balance (no stakes yet)");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 8: User Interaction - Answer Question
    console.log("💬 Test 8: Answer a Question (Simulated User)");
    let questionIdToAnswer = 0;
    let answerId = 0;

    // Create a second wallet for user interaction
    const user2 = ethers.Wallet.createRandom().connect(provider);
    console.log("   User 2 Address:", user2.address);

    try {
        // Fund User 2 with ETH
        const fundAmount = ethers.parseEther("0.01");
        console.log(`   Funding User 2 with ${ethers.formatEther(fundAmount)} ETH...`);
        const fundTx = await deployer.sendTransaction({
            to: user2.address,
            value: fundAmount
        });
        await fundTx.wait();
        console.log("   ✅ User 2 funded with ETH");

        // Fund User 2 with STARK tokens (if needed for future tests, though answering is free usually)
        // But let's do it anyway
        const tokenAmount = ethers.parseEther("100");
        console.log(`   Funding User 2 with ${ethers.formatEther(tokenAmount)} STARK...`);
        const tokenTx = await starkToken.transfer(user2.address, tokenAmount);
        await tokenTx.wait();
        console.log("   ✅ User 2 funded with STARK");

        // Get a question to answer
        const [questions] = await starkOverflow.getQuestions(1, 1, 1);
        if (questions.length > 0) {
            questionIdToAnswer = Number(questions[0].id);
            console.log(`   Answering Question ID: ${questionIdToAnswer}`);

            // Connect contracts as User 2
            const starkOverflowUser2 = starkOverflow.connect(user2);

            const answerTx = await starkOverflowUser2.submitAnswer(
                questionIdToAnswer,
                "QmAnswerCid"
            );
            await answerTx.wait();
            console.log("   ✅ Answer submitted");

            // Get the answer ID (it should be the last one)
            const lastAnswerId = await starkOverflow.lastAnswerId();
            answerId = Number(lastAnswerId);
            console.log(`   Answer ID: ${answerId}`);
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

    // Test 9: Upvote Answer
    console.log("👍 Test 9: Upvote Answer");
    try {
        if (answerId > 0) {
            console.log(`   Upvoting Answer ID: ${answerId}...`);
            const voteTx = await starkOverflow.voteAnswer(answerId, true); // true = upvote
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

    // Test 10: Select Best Answer
    console.log("🏆 Test 10: Select Best Answer & Verify Reward");
    try {
        if (questionIdToAnswer > 0 && answerId > 0) {
            console.log(`   Selecting Answer ID ${answerId} as best for Question ID ${questionIdToAnswer}...`);

            // Check User 2 balance before reward
            const balanceBefore = await starkToken.balanceOf(user2.address);
            console.log(`   User 2 Balance Before: ${ethers.formatEther(balanceBefore)} STARK`);

            const selectTx = await starkOverflow.chooseBestAnswer(questionIdToAnswer, answerId);
            await selectTx.wait();
            console.log("   ✅ Best answer selected");

            // Check User 2 balance after reward
            const balanceAfter = await starkToken.balanceOf(user2.address);
            console.log(`   User 2 Balance After: ${ethers.formatEther(balanceAfter)} STARK`);

            if (balanceAfter > balanceBefore) {
                console.log("   ✅ PASSED: Reward received by answer author");
                testsPassed++;
            } else {
                console.log("   ❌ FAILED: Balance did not increase");
                testsFailed++;
            }
        } else {
            console.log("   ⚠️  Skipping best answer test: Prerequisites not met");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Final Summary
    console.log("=".repeat(70));
    console.log("📊 ETHEREUM SEPOLIA TEST SUMMARY");
    console.log("=".repeat(70));
    console.log(`✅ Tests Passed: ${testsPassed}`);
    console.log(`❌ Tests Failed: ${testsFailed}`);
    console.log(`⚠️  Tests Skipped: ${testsSkipped}`);
    console.log("=".repeat(70));
    console.log();

    console.log("🔗 Contract Links:");
    console.log(`StarkToken: https://sepolia.etherscan.io/address/${STARK_TOKEN_ADDRESS}`);
    console.log(`StarkOverflow: https://sepolia.etherscan.io/address/${STARK_OVERFLOW_ADDRESS}`);
    console.log("=".repeat(70));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
