// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StarkOverflow.sol";
import "../src/MockStarkToken.sol";

contract StarkOverflowTest is Test {
    StarkOverflow public starkOverflow;
    MockStarkToken public token;

    address public owner;
    address public user1;
    address public user2;
    address public user3;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);

        token = new MockStarkToken();
        starkOverflow = new StarkOverflow(owner, address(token));

        token.mint(user1, 1000 ether);
        token.mint(user2, 1000 ether);
        token.mint(user3, 1000 ether);

        vm.prank(user1);
        token.approve(address(starkOverflow), type(uint256).max);
        
        vm.prank(user2);
        token.approve(address(starkOverflow), type(uint256).max);

        vm.prank(user3);
        token.approve(address(starkOverflow), type(uint256).max);
    }

    // --- Forum Management Tests ---

    function testCreateForum() public {
        uint256 forumId = starkOverflow.createForum("General", "QmIconCid");
        assertEq(forumId, 1);
        
        IStarkOverflow.Forum memory forum = starkOverflow.getForum(forumId);
        assertEq(forum.name, "General");
        assertEq(forum.iconCid, "QmIconCid");
        assertEq(forum.deleted, false);
    }

    function testRevertCreateForumNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        starkOverflow.createForum("Hacker", "QmIconCid");
    }

    function testUpdateForum() public {
        uint256 forumId = starkOverflow.createForum("General", "QmIconCid");
        
        starkOverflow.updateForum(forumId, "Updated General", "QmNewIconCid");
        
        IStarkOverflow.Forum memory forum = starkOverflow.getForum(forumId);
        assertEq(forum.name, "Updated General");
        assertEq(forum.iconCid, "QmNewIconCid");
    }

    function testRevertUpdateForumNotOwner() public {
        uint256 forumId = starkOverflow.createForum("General", "QmIconCid");
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        starkOverflow.updateForum(forumId, "Hacker", "QmIconCid");
    }

    function testDeleteForum() public {
        uint256 forumId = starkOverflow.createForum("General", "QmIconCid");
        
        starkOverflow.deleteForum(forumId);
        
        IStarkOverflow.Forum memory forum = starkOverflow.getForum(forumId);
        assertEq(forum.deleted, true);

        // Verify it's not returned in getForums (using pagination)
        (IStarkOverflow.Forum[] memory forums, uint64 total, ) = starkOverflow.getForums(10, 1);
        assertEq(forums.length, 0);
        assertEq(total, 0);
    }

    function testRevertDeleteForumNotOwner() public {
        uint256 forumId = starkOverflow.createForum("General", "QmIconCid");
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        starkOverflow.deleteForum(forumId);
    }

    function testRevertDeleteForumAlreadyDeleted() public {
        uint256 forumId = starkOverflow.createForum("General", "QmIconCid");
        starkOverflow.deleteForum(forumId);
        
        vm.expectRevert(IStarkOverflow.ForumDeleted.selector);
        starkOverflow.deleteForum(forumId);
    }

    function testGetForumsPagination() public {
        // Create 5 forums
        for(uint i = 0; i < 5; i++) {
            starkOverflow.createForum("F", "C");
        }

        // Delete the 3rd one (ID 3)
        starkOverflow.deleteForum(3);

        // Should have 4 active forums: 1, 2, 4, 5 (order might change due to swap-pop)
        // Swap-pop: 3 replaced by 5. Active: 1, 2, 5, 4.

        (IStarkOverflow.Forum[] memory forums, uint64 total, bool hasNext) = starkOverflow.getForums(2, 1);
        assertEq(forums.length, 2);
        assertEq(total, 4);
        assertEq(hasNext, true);
        
        // Check IDs
        assertEq(forums[0].id, 1);
        assertEq(forums[1].id, 2);

        (forums, total, hasNext) = starkOverflow.getForums(2, 2);
        assertEq(forums.length, 2);
        assertEq(hasNext, false);
        // Order depends on implementation, but should be valid IDs
        assertTrue(forums[0].id == 4 || forums[0].id == 5);
        assertTrue(forums[1].id == 4 || forums[1].id == 5);
    }

    // --- Question Tests ---

    function testAskQuestion() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(
            1,
            "How to test?",
            "QmDescriptionCid",
            "http://repo.url",
            tags,
            10 ether
        );

        assertEq(questionId, 1);
        assertEq(token.balanceOf(address(starkOverflow)), 10 ether);
        
        IStarkOverflow.QuestionResponse memory q = starkOverflow.getQuestion(questionId);
        assertEq(q.title, "How to test?");
        assertEq(q.descriptionCid, "QmDescriptionCid");
        assertEq(q.author, user1);
        assertEq(uint(q.status), uint(IStarkOverflow.QuestionStatus.Open));
    }

    function testRevertAskQuestionZeroAmount() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        vm.expectRevert(IStarkOverflow.AmountMustBeGreaterThanZero.selector);
        starkOverflow.askQuestion(1, "Q", "D", "R", tags, 0);
    }

    function testRevertAskQuestionDeletedForum() public {
        uint256 forumId = starkOverflow.createForum("General", "QmIconCid");
        starkOverflow.deleteForum(forumId);

        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        vm.expectRevert(IStarkOverflow.ForumDeleted.selector);
        starkOverflow.askQuestion(forumId, "Q", "D", "R", tags, 1 ether);
    }

    function testGetQuestionsPagination() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "tag";

        // Create 5 questions
        for(uint i = 0; i < 5; i++) {
            vm.prank(user1);
            starkOverflow.askQuestion(1, "Q", "D", "R", tags, 1 ether);
        }

        // Page 1, Size 2 -> Should return Q1, Q2. Has next = true
        (IStarkOverflow.QuestionResponse[] memory questions, uint64 total, bool hasNext) = starkOverflow.getQuestions(1, 2, 1);
        assertEq(questions.length, 2);
        assertEq(questions[0].id, 1);
        assertEq(questions[1].id, 2);
        assertEq(total, 5);
        assertEq(hasNext, true);

        // Page 2, Size 2 -> Should return Q3, Q4. Has next = true
        (questions, total, hasNext) = starkOverflow.getQuestions(1, 2, 2);
        assertEq(questions.length, 2);
        assertEq(questions[0].id, 3);
        assertEq(questions[1].id, 4);
        assertEq(hasNext, true);

        // Page 3, Size 2 -> Should return Q5. Has next = false
        (questions, total, hasNext) = starkOverflow.getQuestions(1, 2, 3);
        assertEq(questions.length, 1);
        assertEq(questions[0].id, 5);
        assertEq(hasNext, false);
    }

    function testGetQuestionsEmptyForum() public {
        starkOverflow.createForum("Empty", "QmIconCid");
        (IStarkOverflow.QuestionResponse[] memory questions, uint64 total, bool hasNext) = starkOverflow.getQuestions(1, 10, 1);
        assertEq(questions.length, 0);
        assertEq(total, 0);
        assertEq(hasNext, false);
    }

    // --- Staking Tests ---

    function testStakeOnQuestion() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 10 ether);

        vm.prank(user2);
        starkOverflow.stakeOnQuestion(questionId, 5 ether);

        assertEq(starkOverflow.getTotalStakedOnQuestion(questionId), 15 ether);
        assertEq(starkOverflow.getStakedAmount(user2, questionId), 5 ether);
        assertEq(token.balanceOf(address(starkOverflow)), 15 ether);
    }

    function testRevertStakeZeroAmount() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 10 ether);

        vm.prank(user2);
        vm.expectRevert(IStarkOverflow.AmountMustBeGreaterThanZero.selector);
        starkOverflow.stakeOnQuestion(questionId, 0);
    }

    function testRevertStakeOnResolvedQuestion() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 10 ether);

        vm.prank(user2);
        uint256 answerId = starkOverflow.submitAnswer(questionId, "A");

        vm.prank(user1);
        starkOverflow.markAnswerAsCorrect(questionId, answerId);

        // Try to stake on resolved question
        vm.prank(user2);
        vm.expectRevert(IStarkOverflow.QuestionResolved.selector);
        starkOverflow.stakeOnQuestion(questionId, 5 ether);
    }

    // --- Answer & Voting Tests ---

    function testSubmitAnswerAndVote() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "QmQuestionCid", "R", tags, 10 ether);

        vm.prank(user2);
        uint256 answerId = starkOverflow.submitAnswer(questionId, "QmAnswerCid");

        assertEq(answerId, 1);

        // Upvote
        vm.prank(user1);
        starkOverflow.voteOnAnswer(answerId, true);

        IStarkOverflow.Answer memory a = starkOverflow.getAnswer(answerId);
        assertEq(a.upvotes, 1);
        assertEq(a.downvotes, 0);
        
        uint256 rep = starkOverflow.getUserReputation(user2);
        assertEq(rep, 1);
    }

    function testVoteDown() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 10 ether);

        vm.prank(user2);
        uint256 answerId = starkOverflow.submitAnswer(questionId, "A");

        // Give user2 some reputation first (so we can decrease it)
        // User3 upvotes user2's answer
        vm.prank(user3);
        starkOverflow.voteOnAnswer(answerId, true);
        assertEq(starkOverflow.getUserReputation(user2), 1);

        // User1 downvotes user2's answer
        vm.prank(user1);
        starkOverflow.voteOnAnswer(answerId, false);

        IStarkOverflow.Answer memory a = starkOverflow.getAnswer(answerId);
        assertEq(a.upvotes, 1);
        assertEq(a.downvotes, 1);

        // Reputation should go back to 0
        assertEq(starkOverflow.getUserReputation(user2), 0);
    }

    function testRevertDoubleVote() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 10 ether);

        vm.prank(user2);
        uint256 answerId = starkOverflow.submitAnswer(questionId, "A");

        vm.prank(user1);
        starkOverflow.voteOnAnswer(answerId, true);

        // Try to vote again
        vm.prank(user1);
        vm.expectRevert(IStarkOverflow.AlreadyVoted.selector);
        starkOverflow.voteOnAnswer(answerId, false);
    }

    function testRevertSelfVote() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 10 ether);

        vm.prank(user2);
        uint256 answerId = starkOverflow.submitAnswer(questionId, "A");

        // User2 tries to vote on their own answer
        vm.prank(user2);
        vm.expectRevert(IStarkOverflow.CannotVoteOnOwnAnswer.selector);
        starkOverflow.voteOnAnswer(answerId, true);
    }

    function testGetAnswersPagination() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 10 ether);

        // Submit 5 answers
        for(uint i = 0; i < 5; i++) {
            vm.prank(user2);
            starkOverflow.submitAnswer(questionId, "A");
        }

        (IStarkOverflow.Answer[] memory answers, uint64 total, bool hasNext) = starkOverflow.getAnswers(questionId, 2, 1);
        assertEq(answers.length, 2);
        assertEq(total, 5);
        assertEq(hasNext, true);

        (answers, total, hasNext) = starkOverflow.getAnswers(questionId, 2, 3);
        assertEq(answers.length, 1);
        assertEq(hasNext, false);
    }

    // --- Resolution Tests ---

    function testMarkCorrectAnswer() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "QmQuestionCid", "R", tags, 10 ether);

        vm.prank(user2);
        uint256 answerId = starkOverflow.submitAnswer(questionId, "QmAnswerCid");

        uint256 initialBalance = token.balanceOf(user2);

        vm.prank(user1);
        starkOverflow.markAnswerAsCorrect(questionId, answerId);

        uint256 finalBalance = token.balanceOf(user2);
        assertEq(finalBalance - initialBalance, 10 ether);
        
        assertEq(starkOverflow.getCorrectAnswer(questionId), answerId);
        
        IStarkOverflow.QuestionResponse memory q = starkOverflow.getQuestion(questionId);
        assertEq(uint(q.status), uint(IStarkOverflow.QuestionStatus.Resolved));
    }

    function testRevertMarkCorrectAnswerNotAuthor() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 10 ether);

        vm.prank(user2);
        uint256 answerId = starkOverflow.submitAnswer(questionId, "A");

        // User3 tries to mark as correct
        vm.prank(user3);
        vm.expectRevert(IStarkOverflow.Unauthorized.selector);
        starkOverflow.markAnswerAsCorrect(questionId, answerId);
    }

    function testRevertMarkCorrectAnswerAlreadyResolved() public {
        starkOverflow.createForum("General", "QmIconCid");
        string[] memory tags = new string[](1);
        tags[0] = "solidity";

        vm.prank(user1);
        uint256 questionId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 10 ether);

        vm.prank(user2);
        uint256 answerId = starkOverflow.submitAnswer(questionId, "A");

        vm.prank(user1);
        starkOverflow.markAnswerAsCorrect(questionId, answerId);

        // Try to mark again
        vm.prank(user1);
        vm.expectRevert(IStarkOverflow.QuestionResolved.selector);
        starkOverflow.markAnswerAsCorrect(questionId, answerId);
    }

    // --- Coverage Edge Case Tests ---

    function testGetForumsInvalidPagination() public {
        vm.expectRevert(IStarkOverflow.InvalidPageSize.selector);
        starkOverflow.getForums(0, 1);

        vm.expectRevert(IStarkOverflow.InvalidPage.selector);
        starkOverflow.getForums(10, 0);

        // Page out of bounds
        (IStarkOverflow.Forum[] memory forums, uint64 total, bool hasNext) = starkOverflow.getForums(10, 999);
        assertEq(forums.length, 0);
        assertEq(total, 0); // Total is 0 if no forums exist yet, or actual total
        assertEq(hasNext, false);
    }

    function testGetQuestionsInvalidPagination() public {
        starkOverflow.createForum("F", "C");
        
        vm.expectRevert(IStarkOverflow.InvalidPageSize.selector);
        starkOverflow.getQuestions(1, 0, 1);

        vm.expectRevert(IStarkOverflow.InvalidPage.selector);
        starkOverflow.getQuestions(1, 10, 0);

        // Page out of bounds
        (IStarkOverflow.QuestionResponse[] memory qs, uint64 total, bool hasNext) = starkOverflow.getQuestions(1, 10, 999);
        assertEq(qs.length, 0);
        assertEq(hasNext, false);
    }

    function testGetAnswersInvalidPagination() public {
        starkOverflow.createForum("F", "C");
        string[] memory tags = new string[](1);
        tags[0] = "t";
        vm.prank(user1);
        uint256 qId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 1 ether);

        vm.expectRevert(IStarkOverflow.QuestionDoesNotExist.selector);
        starkOverflow.getAnswers(999, 10, 1);

        vm.expectRevert(IStarkOverflow.InvalidPageSize.selector);
        starkOverflow.getAnswers(qId, 0, 1);

        vm.expectRevert(IStarkOverflow.InvalidPage.selector);
        starkOverflow.getAnswers(qId, 10, 0);

        // Page out of bounds
        (IStarkOverflow.Answer[] memory as_, uint64 total, bool hasNext) = starkOverflow.getAnswers(qId, 10, 999);
        assertEq(as_.length, 0);
        assertEq(hasNext, false);
    }

    function testSubmitAnswerResolvedQuestion() public {
        starkOverflow.createForum("F", "C");
        string[] memory tags = new string[](1);
        tags[0] = "t";
        vm.prank(user1);
        uint256 qId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 1 ether);
        
        vm.prank(user2);
        uint256 aId = starkOverflow.submitAnswer(qId, "A");

        vm.prank(user1);
        starkOverflow.markAnswerAsCorrect(qId, aId);

        vm.prank(user2);
        vm.expectRevert(IStarkOverflow.QuestionResolved.selector);
        starkOverflow.submitAnswer(qId, "A2");
    }

    function testMarkAnswerAsCorrectInvalidAnswer() public {
        starkOverflow.createForum("F", "C");
        string[] memory tags = new string[](1);
        tags[0] = "t";
        vm.prank(user1);
        uint256 qId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 1 ether);
        
        // Create another question to get a valid answer ID that doesn't belong to qId
        vm.prank(user1);
        uint256 qId2 = starkOverflow.askQuestion(1, "Q2", "D", "R", tags, 1 ether);
        vm.prank(user2);
        uint256 aId2 = starkOverflow.submitAnswer(qId2, "A");

        vm.prank(user1);
        vm.expectRevert(IStarkOverflow.AnswerDoesNotExist.selector);
        starkOverflow.markAnswerAsCorrect(qId, aId2);
    }

    function testVoteOnAnswerInvalid() public {
        vm.prank(user1);
        vm.expectRevert(IStarkOverflow.AnswerDoesNotExist.selector);
        starkOverflow.voteOnAnswer(999, true);
    }

    function testVoteDownZeroReputation() public {
        starkOverflow.createForum("F", "C");
        string[] memory tags = new string[](1);
        tags[0] = "t";
        vm.prank(user1);
        uint256 qId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 1 ether);
        
        vm.prank(user2);
        uint256 aId = starkOverflow.submitAnswer(qId, "A");

        // User2 has 0 rep. Downvote should keep it at 0.
        vm.prank(user1);
        starkOverflow.voteOnAnswer(aId, false);

        assertEq(starkOverflow.getUserReputation(user2), 0);
    }

    function testViewFunctions() public {
        starkOverflow.createForum("F", "C");
        string[] memory tags = new string[](1);
        tags[0] = "t";
        vm.prank(user1);
        uint256 qId = starkOverflow.askQuestion(1, "Q", "D", "R", tags, 1 ether);
        vm.prank(user2);
        uint256 aId = starkOverflow.submitAnswer(qId, "A");

        vm.prank(user1);
        starkOverflow.voteOnAnswer(aId, true);

        assertTrue(starkOverflow.hasVoted(user1, aId));
        assertTrue(starkOverflow.getVote(user1, aId)); // true = upvote

        IStarkOverflow.User memory u = starkOverflow.getUser(user2);
        assertEq(u.walletAddress, user2);
        assertEq(u.reputation, 1);
    }
}
