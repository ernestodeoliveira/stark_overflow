// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v3.0.15 https://hardhat.org


// File npm/@openzeppelin/contracts@5.4.0/utils/Context.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File npm/@openzeppelin/contracts@5.4.0/access/Ownable.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File npm/@openzeppelin/contracts@5.4.0/token/ERC20/IERC20.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File npm/@openzeppelin/contracts@5.4.0/utils/ReentrancyGuard.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}


// File src/IStarkOverflow.sol

// Original license: SPDX_License_Identifier: MIT
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


// File src/StarkOverflow.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;




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

