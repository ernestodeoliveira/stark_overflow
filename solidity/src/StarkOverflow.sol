// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IStarkOverflow.sol";

contract StarkOverflow is IStarkOverflow, Ownable, ReentrancyGuard {
    // State Variables
    uint256 public lastForumId;
    uint256 public lastQuestionId;
    uint256 public lastAnswerId;

    IERC20 public starkToken;

    // Mappings
    mapping(uint256 => Forum) public forumById;
    mapping(uint256 => Question) public questionById;
    mapping(uint256 => uint256[]) public questionsIdsByForumId;
    mapping(address => mapping(uint256 => uint256)) public stakedInQuestionByUser;
    mapping(uint256 => uint256) public totalStakedByQuestionId;
    mapping(uint256 => Answer) public answerById;
    mapping(uint256 => uint256[]) public answersIdsByQuestionId;
    mapping(uint256 => uint256) public chosenAnswerByQuestionId;
    mapping(address => uint256) public reputation;
    mapping(address => mapping(uint256 => bool)) public hasUserVoted;
    mapping(address => mapping(uint256 => bool)) public userVotes; // true = upvote, false = downvote

    // Array to track active forum IDs for easier pagination
    uint256[] public activeForumIds;

    constructor(address initialOwner, address _starkToken) Ownable(initialOwner) {
        starkToken = IERC20(_starkToken);
    }

    // Forums
    function createForum(string calldata name, string calldata iconCid) external onlyOwner returns (uint256) {
        lastForumId++;
        uint256 forumId = lastForumId;

        forumById[forumId] = Forum({
            id: forumId,
            name: name,
            iconCid: iconCid,
            amount: 0,
            totalQuestions: 0,
            deleted: false
        });

        activeForumIds.push(forumId);

        return forumId;
    }

    function deleteForum(uint256 forumId) external onlyOwner {
        if (forumById[forumId].deleted) revert ForumDeleted();
        forumById[forumId].deleted = true;
        
        // Remove from activeForumIds (swap and pop for efficiency)
        uint256 length = activeForumIds.length;
        for (uint256 i = 0; i < length;) {
            if (activeForumIds[i] == forumId) {
                activeForumIds[i] = activeForumIds[length - 1];
                activeForumIds.pop();
                break;
            }
            unchecked { ++i; }
        }
    }

    function updateForum(uint256 forumId, string calldata name, string calldata iconCid) external onlyOwner {
        Forum storage forum = forumById[forumId];
        forum.name = name;
        forum.iconCid = iconCid;
    }

    function getForum(uint256 forumId) external view returns (Forum memory) {
        return forumById[forumId];
    }

    function getForums(uint64 pageSize, uint64 page) external view returns (Forum[] memory, uint64, bool) {
        if (pageSize == 0) revert InvalidPageSize();
        if (page == 0) revert InvalidPage();

        uint256 totalForums = activeForumIds.length;

        if (totalForums == 0) {
            return (new Forum[](0), 0, false);
        }

        uint256 pageFirstIdx = uint256(pageSize) * (uint256(page) - 1);
        
        if (pageFirstIdx >= totalForums) {
            return (new Forum[](0), uint64(totalForums), false);
        }

        uint256 pageLastIdx = pageFirstIdx + pageSize - 1;
        if (pageLastIdx >= totalForums) {
            pageLastIdx = totalForums - 1;
        }

        uint256 count = pageLastIdx - pageFirstIdx + 1;
        Forum[] memory forums = new Forum[](count);
        
        for (uint256 i = 0; i < count;) {
            forums[i] = forumById[activeForumIds[pageFirstIdx + i]];
            unchecked { ++i; }
        }

        bool hasNextPage = (pageLastIdx + 1) < totalForums;

        return (forums, uint64(totalForums), hasNextPage);
    }

    // Questions
    function askQuestion(
        uint256 forumId,
        string calldata title,
        string calldata descriptionCid,
        string calldata repositoryUrl,
        string[] calldata tags,
        uint256 amount
    ) external nonReentrant returns (uint256) {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (forumById[forumId].deleted) revert ForumDeleted();
        
        starkToken.transferFrom(msg.sender, address(this), amount);

        Forum storage forum = forumById[forumId];
        forum.amount += amount;
        forum.totalQuestions += 1;

        lastQuestionId++;
        uint256 questionId = lastQuestionId;

        Question storage question = questionById[questionId];
        question.id = questionId;
        question.forumId = forumId;
        question.title = title;
        question.author = msg.sender;
        question.descriptionCid = descriptionCid;
        question.repositoryUrl = repositoryUrl;
        question.status = QuestionStatus.Open;
        question.amount = amount;
        
        uint256 tagsLength = tags.length;
        for (uint256 i = 0; i < tagsLength;) {
            question.tags.push(tags[i]);
            unchecked { ++i; }
        }

        questionsIdsByForumId[forumId].push(questionId);
        totalStakedByQuestionId[questionId] = amount;

        return questionId;
    }

    function getQuestion(uint256 questionId) external view returns (QuestionResponse memory) {
        Question storage q = questionById[questionId];
        return QuestionResponse({
            id: q.id,
            forumId: q.forumId,
            title: q.title,
            author: q.author,
            descriptionCid: q.descriptionCid,
            amount: q.amount,
            repositoryUrl: q.repositoryUrl,
            tags: q.tags,
            status: q.status
        });
    }

    function getQuestions(uint256 forumId, uint64 pageSize, uint64 page) external view returns (QuestionResponse[] memory, uint64, bool) {
        if (pageSize == 0) revert InvalidPageSize();
        if (page == 0) revert InvalidPage();

        uint256 totalForumQuestions = questionsIdsByForumId[forumId].length;

        if (totalForumQuestions == 0) {
            return (new QuestionResponse[](0), 0, false);
        }

        uint256 pageFirstQuestionIdx = uint256(pageSize) * (uint256(page) - 1);
        
        if (pageFirstQuestionIdx >= totalForumQuestions) {
            return (new QuestionResponse[](0), uint64(totalForumQuestions), false);
        }

        uint256 pageLastQuestionIdx = pageFirstQuestionIdx + pageSize - 1;
        if (pageLastQuestionIdx >= totalForumQuestions) {
            pageLastQuestionIdx = totalForumQuestions - 1;
        }

        uint256 count = pageLastQuestionIdx - pageFirstQuestionIdx + 1;
        QuestionResponse[] memory questionsForPage = new QuestionResponse[](count);
        
        for (uint256 i = 0; i < count;) {
            uint256 questionId = questionsIdsByForumId[forumId][pageFirstQuestionIdx + i];
            Question storage q = questionById[questionId];
            questionsForPage[i] = QuestionResponse({
                id: q.id,
                forumId: q.forumId,
                title: q.title,
                author: q.author,
                descriptionCid: q.descriptionCid,
                amount: q.amount,
                repositoryUrl: q.repositoryUrl,
                tags: q.tags,
                status: q.status
            });
            unchecked { ++i; }
        }

        bool hasNextPage = (pageLastQuestionIdx + 1) < totalForumQuestions;

        return (questionsForPage, uint64(totalForumQuestions), hasNextPage);
    }

    function stakeOnQuestion(uint256 questionId, uint256 amount) external nonReentrant {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        
        Question storage question = questionById[questionId];
        if (question.status != QuestionStatus.Open) revert QuestionResolved();

        starkToken.transferFrom(msg.sender, address(this), amount);
        
        question.amount += amount;

        stakedInQuestionByUser[msg.sender][questionId] += amount;
        totalStakedByQuestionId[questionId] += amount;

        Forum storage forum = forumById[question.forumId];
        forum.amount += amount;

        emit QuestionStaked(msg.sender, questionId, amount);
    }

    function getTotalStakedOnQuestion(uint256 questionId) external view returns (uint256) {
        return totalStakedByQuestionId[questionId];
    }

    function getStakedAmount(address staker, uint256 questionId) external view returns (uint256) {
        return stakedInQuestionByUser[staker][questionId];
    }

    // Answers
    function submitAnswer(uint256 questionId, string calldata descriptionCid) external returns (uint256) {
        if (questionById[questionId].status != QuestionStatus.Open) revert QuestionResolved();
        
        lastAnswerId++;
        uint256 answerId = lastAnswerId;

        answerById[answerId] = Answer({
            id: answerId,
            author: msg.sender,
            descriptionCid: descriptionCid,
            questionId: questionId,
            upvotes: 0,
            downvotes: 0
        });

        answersIdsByQuestionId[questionId].push(answerId);

        emit QuestionAnswered(answerId, questionId, answerId, block.timestamp);

        return answerId;
    }

    function getAnswer(uint256 answerId) external view returns (Answer memory) {
        return answerById[answerId];
    }

    function getAnswers(uint256 questionId, uint64 pageSize, uint64 page) external view returns (Answer[] memory, uint64, bool) {
        if (questionById[questionId].id != questionId) revert QuestionDoesNotExist();
        if (pageSize == 0) revert InvalidPageSize();
        if (page == 0) revert InvalidPage();

        uint256 totalAnswers = answersIdsByQuestionId[questionId].length;

        if (totalAnswers == 0) {
            return (new Answer[](0), 0, false);
        }

        uint256 pageFirstIdx = uint256(pageSize) * (uint256(page) - 1);
        
        if (pageFirstIdx >= totalAnswers) {
            return (new Answer[](0), uint64(totalAnswers), false);
        }

        uint256 pageLastIdx = pageFirstIdx + pageSize - 1;
        if (pageLastIdx >= totalAnswers) {
            pageLastIdx = totalAnswers - 1;
        }

        uint256 count = pageLastIdx - pageFirstIdx + 1;
        Answer[] memory answers = new Answer[](count);
        
        uint256[] memory answerIds = answersIdsByQuestionId[questionId];
        for (uint256 i = 0; i < count;) {
            answers[i] = answerById[answerIds[pageFirstIdx + i]];
            unchecked { ++i; }
        }

        bool hasNextPage = (pageLastIdx + 1) < totalAnswers;

        return (answers, uint64(totalAnswers), hasNextPage);
    }

    function markAnswerAsCorrect(uint256 questionId, uint256 answerId) external nonReentrant {
        Question storage question = questionById[questionId];
        if (msg.sender != question.author) revert Unauthorized();
        
        Answer storage answer = answerById[answerId];
        if (answer.questionId != questionId) revert AnswerDoesNotExist();
        if (question.status != QuestionStatus.Open) revert QuestionResolved();

        question.status = QuestionStatus.Resolved;
        chosenAnswerByQuestionId[questionId] = answerId;

        _distributeRewards(questionId, answerId);

        emit ChosenAnswer(answerId, questionId, answerId, answer.author, block.timestamp);
    }

    function getCorrectAnswer(uint256 questionId) external view returns (uint256) {
        return chosenAnswerByQuestionId[questionId];
    }

    function _distributeRewards(uint256 questionId, uint256 answerId) internal {
        Answer storage answer = answerById[answerId];
        address answerAuthor = answer.author;
        uint256 totalStaked = totalStakedByQuestionId[questionId];

        starkToken.transfer(answerAuthor, totalStaked);
    }

    // Reputation System
    function voteOnAnswer(uint256 answerId, bool vote) external {
        Answer storage answer = answerById[answerId];
        if (answer.id != answerId) revert AnswerDoesNotExist();
        if (answer.author == msg.sender) revert CannotVoteOnOwnAnswer();

        if (hasUserVoted[msg.sender][answerId]) revert AlreadyVoted();

        hasUserVoted[msg.sender][answerId] = true;
        userVotes[msg.sender][answerId] = vote;

        if (vote) {
            answer.upvotes += 1;
        } else {
            answer.downvotes += 1;
        }

        address answerAuthor = answer.author;
        uint256 oldReputation = reputation[answerAuthor];
        uint256 newReputation;

        if (vote) {
            newReputation = oldReputation + 1;
        } else {
            if (oldReputation > 0) {
                newReputation = oldReputation - 1;
            } else {
                newReputation = 0;
            }
        }
        
        reputation[answerAuthor] = newReputation;

        uint256 actualReputationChange;
        if (newReputation >= oldReputation) {
            actualReputationChange = newReputation - oldReputation;
        } else {
            actualReputationChange = oldReputation - newReputation;
        }

        emit VoteCast(msg.sender, answerId, vote, answerAuthor, actualReputationChange);
    }

    function getUserReputation(address user) external view returns (uint256) {
        return reputation[user];
    }

    function getUser(address user) external view returns (User memory) {
        return User({
            walletAddress: user,
            reputation: reputation[user]
        });
    }

    function hasVoted(address voter, uint256 answerId) external view returns (bool) {
        return hasUserVoted[voter][answerId];
    }

    function getVote(address voter, uint256 answerId) external view returns (bool) {
        return userVotes[voter][answerId];
    }
}
