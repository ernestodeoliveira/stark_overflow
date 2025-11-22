// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStarkOverflow {
    // Custom Errors
    error AmountMustBeGreaterThanZero();
    error Unauthorized();
    error ForumDeleted();
    error QuestionResolved();
    error QuestionNotResolved();
    error QuestionDoesNotExist();
    error AnswerDoesNotExist();
    error AlreadyVoted();
    error CannotVoteOnOwnAnswer();
    error InvalidPageSize();
    error InvalidPage();

    // Structs
    struct Forum {
        uint256 id;
        string name;
        string iconCid;
        uint256 amount;
        uint256 totalQuestions;
        bool deleted;
    }

    struct Answer {
        uint256 id;
        address author;
        string descriptionCid;
        uint256 questionId;
        uint128 upvotes;   // Optimized: uint128
        uint128 downvotes; // Optimized: uint128
    }

    struct User {
        address walletAddress;
        uint256 reputation;
    }

    enum QuestionStatus {
        Open,
        Resolved
    }

    struct Question {
        uint256 id;
        uint256 forumId;
        string title;
        address author;
        string descriptionCid;
        uint256 amount;
        string repositoryUrl;
        string[] tags;
        QuestionStatus status;
    }

    struct QuestionResponse {
        uint256 id;
        uint256 forumId;
        string title;
        address author;
        string descriptionCid;
        uint256 amount;
        string repositoryUrl;
        string[] tags;
        QuestionStatus status;
    }

    // Events
    event QuestionAnswered(uint256 indexed id, uint256 indexed questionId, uint256 indexed answerId, uint256 date);
    event ChosenAnswer(uint256 indexed id, uint256 indexed questionId, uint256 indexed answerId, address authorAddress, uint256 date);
    event QuestionStaked(address indexed staker, uint256 indexed questionId, uint256 amount);
    event ReputationAdded(address indexed user, uint256 amount, uint256 newTotal);
    event VoteCast(address indexed voter, uint256 indexed answerId, bool isUpvote, address answerAuthor, uint256 reputationChange);

    // Forums
    function createForum(string calldata name, string calldata iconCid) external returns (uint256);
    function deleteForum(uint256 forumId) external;
    function updateForum(uint256 forumId, string calldata name, string calldata iconCid) external;
    function getForum(uint256 forumId) external view returns (Forum memory);
    function getForums(uint64 pageSize, uint64 page) external view returns (Forum[] memory, uint64, bool);

    // Questions
    function askQuestion(uint256 forumId, string calldata title, string calldata descriptionCid, string calldata repositoryUrl, string[] calldata tags, uint256 amount) external returns (uint256);
    function getQuestion(uint256 questionId) external view returns (QuestionResponse memory);
    function getQuestions(uint256 forumId, uint64 pageSize, uint64 page) external view returns (QuestionResponse[] memory, uint64, bool);
    function stakeOnQuestion(uint256 questionId, uint256 amount) external;
    function getTotalStakedOnQuestion(uint256 questionId) external view returns (uint256);
    function getStakedAmount(address staker, uint256 questionId) external view returns (uint256);

    // Answers
    function submitAnswer(uint256 questionId, string calldata descriptionCid) external returns (uint256);
    function getAnswer(uint256 answerId) external view returns (Answer memory);
    function getAnswers(uint256 questionId, uint64 pageSize, uint64 page) external view returns (Answer[] memory, uint64, bool);
    function markAnswerAsCorrect(uint256 questionId, uint256 answerId) external;
    function getCorrectAnswer(uint256 questionId) external view returns (uint256);

    // Reputation System
    function voteOnAnswer(uint256 answerId, bool vote) external;
    function getUserReputation(address user) external view returns (uint256);
    function getUser(address user) external view returns (User memory);
    function hasVoted(address voter, uint256 answerId) external view returns (bool);
    function getVote(address voter, uint256 answerId) external view returns (bool);
}
