import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("StarkOverflow", function () {
    async function deployStarkOverflowFixture() {
        const [owner, user1, user2, user3] = await ethers.getSigners();

        const MockStarkToken = await ethers.getContractFactory("MockStarkToken");
        const token = await MockStarkToken.deploy();

        const StarkOverflow = await ethers.getContractFactory("StarkOverflow");
        const starkOverflow = await StarkOverflow.deploy(owner.address, await token.getAddress());

        // Mint tokens to users
        await token.mint(user1.address, ethers.parseEther("1000"));
        await token.mint(user2.address, ethers.parseEther("1000"));
        await token.mint(user3.address, ethers.parseEther("1000"));

        // Approve spending
        await token.connect(user1).approve(await starkOverflow.getAddress(), ethers.MaxUint256);
        await token.connect(user2).approve(await starkOverflow.getAddress(), ethers.MaxUint256);
        await token.connect(user3).approve(await starkOverflow.getAddress(), ethers.MaxUint256);

        return { starkOverflow, token, owner, user1, user2, user3 };
    }

    describe("Forums", function () {
        it("Should create a forum", async function () {
            const { starkOverflow } = await loadFixture(deployStarkOverflowFixture);

            await starkOverflow.createForum("General", "QmIconCid");

            const forum = await starkOverflow.getForum(1);
            expect(forum.name).to.equal("General");
            expect(forum.iconCid).to.equal("QmIconCid");
            expect(forum.deleted).to.be.false;
        });

        it("Should revert if non-owner creates forum", async function () {
            const { starkOverflow, user1 } = await loadFixture(deployStarkOverflowFixture);

            await expect(
                starkOverflow.connect(user1).createForum("Hacker", "QmIconCid")
            ).to.be.revertedWithCustomError(starkOverflow, "OwnableUnauthorizedAccount")
                .withArgs(user1.address);
        });

        it("Should update a forum", async function () {
            const { starkOverflow } = await loadFixture(deployStarkOverflowFixture);
            await starkOverflow.createForum("General", "QmIconCid");

            await starkOverflow.updateForum(1, "Updated General", "QmNewIconCid");

            const forum = await starkOverflow.getForum(1);
            expect(forum.name).to.equal("Updated General");
            expect(forum.iconCid).to.equal("QmNewIconCid");
        });

        it("Should delete a forum", async function () {
            const { starkOverflow } = await loadFixture(deployStarkOverflowFixture);
            await starkOverflow.createForum("General", "QmIconCid");

            await starkOverflow.deleteForum(1);

            const forum = await starkOverflow.getForum(1);
            expect(forum.deleted).to.be.true;
        });
    });

    describe("Questions", function () {
        it("Should ask a question", async function () {
            const { starkOverflow, user1, token } = await loadFixture(deployStarkOverflowFixture);
            await starkOverflow.createForum("General", "QmIconCid");

            const amount = ethers.parseEther("10");
            await starkOverflow.connect(user1).askQuestion(
                1, "How to test?", "QmDescriptionCid", "http://repo.url", ["solidity"], amount
            );

            const question = await starkOverflow.getQuestion(1);
            expect(question.title).to.equal("How to test?");
            expect(question.author).to.equal(user1.address);
            expect(question.amount).to.equal(amount);

            expect(await token.balanceOf(await starkOverflow.getAddress())).to.equal(amount);
        });

        it("Should revert asking question with zero amount", async function () {
            const { starkOverflow, user1 } = await loadFixture(deployStarkOverflowFixture);
            await starkOverflow.createForum("General", "QmIconCid");

            await expect(
                starkOverflow.connect(user1).askQuestion(
                    1, "Q", "D", "R", ["tag"], 0
                )
            ).to.be.revertedWithCustomError(starkOverflow, "AmountMustBeGreaterThanZero");
        });
    });

    describe("Staking", function () {
        it("Should stake on a question", async function () {
            const { starkOverflow, user1, user2 } = await loadFixture(deployStarkOverflowFixture);
            await starkOverflow.createForum("General", "QmIconCid");
            await starkOverflow.connect(user1).askQuestion(
                1, "Q", "D", "R", ["tag"], ethers.parseEther("10")
            );

            await starkOverflow.connect(user2).stakeOnQuestion(1, ethers.parseEther("5"));

            expect(await starkOverflow.getTotalStakedOnQuestion(1)).to.equal(ethers.parseEther("15"));
            expect(await starkOverflow.getStakedAmount(user2.address, 1)).to.equal(ethers.parseEther("5"));
        });

        it("Should revert staking on resolved question", async function () {
            const { starkOverflow, user1, user2 } = await loadFixture(deployStarkOverflowFixture);
            await starkOverflow.createForum("General", "QmIconCid");
            await starkOverflow.connect(user1).askQuestion(
                1, "Q", "D", "R", ["tag"], ethers.parseEther("10")
            );

            await starkOverflow.connect(user2).submitAnswer(1, "A");
            await starkOverflow.connect(user1).markAnswerAsCorrect(1, 1);

            await expect(
                starkOverflow.connect(user2).stakeOnQuestion(1, ethers.parseEther("5"))
            ).to.be.revertedWithCustomError(starkOverflow, "QuestionResolved");
        });
    });

    describe("Answers and Voting", function () {
        it("Should submit answer and vote", async function () {
            const { starkOverflow, user1, user2 } = await loadFixture(deployStarkOverflowFixture);
            await starkOverflow.createForum("General", "QmIconCid");
            await starkOverflow.connect(user1).askQuestion(
                1, "Q", "D", "R", ["tag"], ethers.parseEther("10")
            );

            await starkOverflow.connect(user2).submitAnswer(1, "QmAnswerCid");

            // Upvote
            await starkOverflow.connect(user1).voteOnAnswer(1, true);

            const answer = await starkOverflow.getAnswer(1);
            expect(answer.upvotes).to.equal(1);
            expect(await starkOverflow.getUserReputation(user2.address)).to.equal(1);
        });

        it("Should revert double voting", async function () {
            const { starkOverflow, user1, user2 } = await loadFixture(deployStarkOverflowFixture);
            await starkOverflow.createForum("General", "QmIconCid");
            await starkOverflow.connect(user1).askQuestion(
                1, "Q", "D", "R", ["tag"], ethers.parseEther("10")
            );
            await starkOverflow.connect(user2).submitAnswer(1, "A");

            await starkOverflow.connect(user1).voteOnAnswer(1, true);

            await expect(
                starkOverflow.connect(user1).voteOnAnswer(1, false)
            ).to.be.revertedWithCustomError(starkOverflow, "AlreadyVoted");
        });
    });

    describe("Resolution", function () {
        it("Should mark answer as correct and distribute rewards", async function () {
            const { starkOverflow, user1, user2, token } = await loadFixture(deployStarkOverflowFixture);
            await starkOverflow.createForum("General", "QmIconCid");
            await starkOverflow.connect(user1).askQuestion(
                1, "Q", "D", "R", ["tag"], ethers.parseEther("10")
            );
            await starkOverflow.connect(user2).submitAnswer(1, "A");

            const initialBalance = await token.balanceOf(user2.address);

            await starkOverflow.connect(user1).markAnswerAsCorrect(1, 1);

            const finalBalance = await token.balanceOf(user2.address);
            expect(finalBalance - initialBalance).to.equal(ethers.parseEther("10"));

            const question = await starkOverflow.getQuestion(1);
            expect(question.status).to.equal(1); // Resolved
        });
    });
});
