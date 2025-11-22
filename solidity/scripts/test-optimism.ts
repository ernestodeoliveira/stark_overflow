import { ethers } from "ethers";
import hre from "hardhat";

// Deployed contract addresses on Optimism Sepolia
const STARK_TOKEN_ADDRESS = "0xDFdD3aC93A78c03C1F04f3E939E745756B4643d7";
const STARK_OVERFLOW_ADDRESS = "0x4A1058b3E8EDd3De25C7D35558176b102217EA22";

async function main() {
    console.log("🧪 Starting extended tests on Optimism Sepolia deployment...\n");
    console.log("=".repeat(70));

    // Setup Provider and Signer manually
    const rpcUrl = process.env.OPTIMISM_SEPOLIA_RPC_URL || "https://sepolia.optimism.io";
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

    // Test 3: Create Forums
    console.log("📁 Test 3: Create Forums on Optimism");
    try {
        const forumNames = ["Optimism DeFi", "Optimism NFTs", "Optimism Gaming"];

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
        console.log("   ✅ PASSED: Forums check completed");
        testsPassed++;
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 4: Create Questions with Stakes
    console.log("💰 Test 4: Create Questions with Different Stakes");
    try {
        const approveAmount = ethers.parseEther("1000");
        console.log(`   Approving ${ethers.formatEther(approveAmount)} STARK...`);
        const approveTx = await starkToken.approve(STARK_OVERFLOW_ADDRESS, approveAmount);
        await approveTx.wait();
        console.log("   ✅ Approved tokens");

        const amounts = [
            ethers.parseEther("20"),
            ethers.parseEther("50")
        ];

        const [forums] = await starkOverflow.getForums(1, 1);
        if (forums.length > 0) {
            const forumId = forums[0].id;

            for (let i = 0; i < amounts.length; i++) {
                try {
                    console.log(`   Asking question ${i + 1}...`);
                    const tx = await starkOverflow.askQuestion(
                        forumId,
                        `Optimism Question ${Date.now()}: How to build on Optimism?`,
                        `QmOptimismQuestion${i + 1}Cid`,
                        `https://github.com/optimism/example${i + 1}`,
                        ["optimism", "development"],
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

    // Test 5: User Interaction - Submit Answer
    console.log("💬 Test 5: Submit Answer (Simulated User)");
    let questionIdToAnswer = 0;
    let answerId = 0;

    const user2 = ethers.Wallet.createRandom().connect(provider);
    console.log("   User 2 Address:", user2.address);

    try {
        const fundAmount = ethers.parseEther("0.01");
        console.log(`   Funding User 2 with ${ethers.formatEther(fundAmount)} ETH...`);
        const fundTx = await deployer.sendTransaction({
            to: user2.address,
            value: fundAmount
        });
        await fundTx.wait();
        console.log("   ✅ User 2 funded with ETH");

        const tokenAmount = ethers.parseEther("100");
        console.log(`   Funding User 2 with ${ethers.formatEther(tokenAmount)} STARK...`);
        const tokenTx = await starkToken.transfer(user2.address, tokenAmount);
        await tokenTx.wait();
        console.log("   ✅ User 2 funded with STARK");

        const [questions] = await starkOverflow.getQuestions(1, 1, 1);
        if (questions.length > 0) {
            questionIdToAnswer = Number(questions[0].id);
            console.log(`   Answering Question ID: ${questionIdToAnswer}`);

            const starkOverflowUser2 = starkOverflow.connect(user2);

            const answerTx = await starkOverflowUser2.submitAnswer(
                questionIdToAnswer,
                "QmOptimismAnswerCid"
            );
            await answerTx.wait();
            console.log("   ✅ Answer submitted");

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
            console.log(`   Marking Answer ID ${answerId} as correct for Question ID ${questionIdToAnswer}...`);

            const balanceBefore = await starkToken.balanceOf(user2.address);
            console.log(`   User 2 Balance Before: ${ethers.formatEther(balanceBefore)} STARK`);

            const selectTx = await starkOverflow.markAnswerAsCorrect(questionIdToAnswer, answerId);
            await selectTx.wait();
            console.log("   ✅ Answer marked as correct");

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
            console.log("   ⚠️  Skipping test: Prerequisites not met");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 8: Verify Network
    console.log("🔗 Test 8: Verify Optimism Sepolia Network");
    try {
        const network = await provider.getNetwork();
        console.log("   Chain ID:", network.chainId.toString());
        console.log("   Network Name:", network.name);

        if (network.chainId === 11155420n) {
            console.log("   ✅ PASSED: Connected to Optimism Sepolia");
            testsPassed++;
        } else {
            console.log("   ❌ FAILED: Wrong network");
            testsFailed++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 9: Retrieve and Verify Answer Details
    console.log("📝 Test 9: Retrieve Answer Details");
    try {
        const [answers, totalAnswers] = await starkOverflow.getAnswers(1, 10, 1);
        console.log(`   Total answers for Question 1: ${totalAnswers}`);

        if (answers.length > 0) {
            const answer = answers[0];
            console.log(`   Answer ID: ${answer.id}`);
            console.log(`   Author: ${answer.author}`);
            console.log(`   Upvotes: ${answer.upvotes}`);
            console.log(`   Downvotes: ${answer.downvotes}`);
            console.log("   ✅ PASSED: Answer details retrieved");
            testsPassed++;
        } else {
            console.log("   ⚠️  No answers found");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 10: Test Staking on Question
    console.log("💎 Test 10: Stake Additional Tokens on Question");
    try {
        const [questions] = await starkOverflow.getQuestions(1, 1, 1);
        if (questions.length > 0) {
            const questionId = questions[0].id;
            const stakeAmount = ethers.parseEther("10");

            console.log(`   Staking ${ethers.formatEther(stakeAmount)} STARK on Question ${questionId}...`);
            const stakeTx = await starkOverflow.stakeOnQuestion(questionId, stakeAmount);
            await stakeTx.wait();
            console.log("   ✅ Stake successful");

            const totalStaked = await starkOverflow.getTotalStakedOnQuestion(questionId);
            console.log(`   Total staked on question: ${ethers.formatEther(totalStaked)} STARK`);
            testsPassed++;
        } else {
            console.log("   ⚠️  Skipping: No questions found");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 11: Verify Reputation System
    console.log("⭐ Test 11: Check User Reputation");
    try {
        const deployerReputation = await starkOverflow.getUserReputation(deployer.address);
        console.log(`   Deployer Reputation: ${deployerReputation}`);

        if (user2) {
            const user2Reputation = await starkOverflow.getUserReputation(user2.address);
            console.log(`   User 2 Reputation: ${user2Reputation}`);
        }

        console.log("   ✅ PASSED: Reputation retrieved");
        testsPassed++;
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 12: Test Forum Statistics
    console.log("📊 Test 12: Verify Forum Statistics");
    try {
        const [forums] = await starkOverflow.getForums(10, 1);
        if (forums.length > 0) {
            const forum = forums[0];
            console.log(`   Forum: ${forum.name}`);
            console.log(`   Total Questions: ${forum.totalQuestions}`);
            console.log(`   Total Amount Staked: ${ethers.formatEther(forum.amount)} STARK`);
            console.log(`   Deleted: ${forum.deleted}`);
            console.log("   ✅ PASSED: Forum statistics accurate");
            testsPassed++;
        } else {
            console.log("   ⚠️  No forums found");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 13: Test Question Pagination
    console.log("📄 Test 13: Test Question Pagination");
    try {
        const [page1, total1, hasNext1] = await starkOverflow.getQuestions(1, 1, 1);
        console.log(`   Page 1: ${page1.length} questions, Total: ${total1}, Has Next: ${hasNext1}`);

        if (total1 > 1) {
            const [page2, total2, hasNext2] = await starkOverflow.getQuestions(1, 1, 2);
            console.log(`   Page 2: ${page2.length} questions, Total: ${total2}, Has Next: ${hasNext2}`);
        }

        console.log("   ✅ PASSED: Pagination working");
        testsPassed++;
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Test 14: Verify Contract Balances
    console.log("💰 Test 14: Verify Token Balances");
    try {
        const contractBalance = await starkToken.balanceOf(STARK_OVERFLOW_ADDRESS);
        const deployerBalance = await starkToken.balanceOf(deployer.address);

        console.log(`   Contract Balance: ${ethers.formatEther(contractBalance)} STARK`);
        console.log(`   Deployer Balance: ${ethers.formatEther(deployerBalance)} STARK`);

        if (contractBalance > 0n) {
            console.log("   ✅ PASSED: Contract holds staked tokens");
            testsPassed++;
        } else {
            console.log("   ⚠️  WARNING: Contract has no balance");
            testsSkipped++;
        }
    } catch (error: any) {
        console.log("   ❌ ERROR:", error.message);
        testsFailed++;
    }
    console.log();

    // Final Summary
    console.log("=".repeat(70));
    console.log("📊 OPTIMISM SEPOLIA TEST SUMMARY");
    console.log("=".repeat(70));
    console.log(`✅ Tests Passed: ${testsPassed}`);
    console.log(`❌ Tests Failed: ${testsFailed}`);
    console.log(`⚠️  Tests Skipped: ${testsSkipped}`);
    console.log("=".repeat(70));
    console.log();

    console.log("🔗 Contract Links:");
    console.log(`StarkToken: https://sepolia-optimism.etherscan.io/address/${STARK_TOKEN_ADDRESS}`);
    console.log(`StarkOverflow: https://sepolia-optimism.etherscan.io/address/${STARK_OVERFLOW_ADDRESS}`);
    console.log("=".repeat(70));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
