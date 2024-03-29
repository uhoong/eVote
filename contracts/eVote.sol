pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "./Crypto.sol";

contract eVote {
    address public admin;
    bool public disputed;
    Crypto crypto;
    mapping(address => uint256[2]) public publicKeys;
    mapping(address => uint256[2]) public votes;
    mapping(address => bool) public refunded;
    address[] public voters;
    bytes32 public usersMerkleTreeRoot;
    bytes32 public computationMerkleTreeRoot;
    uint256 public finishRegistartionBlockNumber;
    uint256 public finishVotingBlockNumber;
    uint256 public finishTallyBlockNumber;
    uint256 public finishChallengeBlockNumber;
    uint256 public constant DEPOSIT = 1 ether;
    uint256 public voteResult;

    constructor(
        address _cryptoAddress,
        bytes32 _usersMerkleTreeRoot,
        uint256 _registrationBlockInterval,
        uint256 _votingBlockInterval,
        uint256 _tallyBlockInterval,
        uint256 _challengeBlockInterval
    ) payable {
        require(msg.value == DEPOSIT, "Invalid deposit value");
        crypto = Crypto(_cryptoAddress);
        admin = msg.sender;
        usersMerkleTreeRoot = _usersMerkleTreeRoot;
        finishRegistartionBlockNumber =
            block.number +
            _registrationBlockInterval;
        finishVotingBlockNumber =
            finishRegistartionBlockNumber +
            _votingBlockInterval;
        finishTallyBlockNumber = finishVotingBlockNumber + _tallyBlockInterval;
        finishChallengeBlockNumber =
            finishTallyBlockNumber +
            _challengeBlockInterval;
    }

    function registerVoter(
        uint256[2] memory _pubKey,
        uint256[3] memory _discreteLogProof,
        bytes32[] memory _merkleProof
    ) public payable {
        require(msg.value == DEPOSIT, "Invalid deposit value");
        require(
            block.number < finishRegistartionBlockNumber,
            "Registration phase is already closed"
        );
        require(
            crypto.verifyMerkleProof(
                _merkleProof,
                usersMerkleTreeRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Invalid Merkle proof"
        );
        require(
            crypto.verifyDL(_pubKey, _discreteLogProof),
            "Invalid DL proof"
        );
        voters.push(msg.sender);
        publicKeys[msg.sender] = _pubKey;
    }

    // function castVote(uint[2] memory _vote, uint[2] memory _Y, uint[7] memory _zeroOrOneProof) public {
    function castVote(
        uint256[2] memory _vote,
        uint256[2] memory _Y,
        uint256[18] memory _zeroOrOneProof
    ) public {
        require(
            block.number >= finishRegistartionBlockNumber &&
                block.number < finishVotingBlockNumber,
            "Voting phase is already closed"
        );
        require(publicKeys[msg.sender][0] != 0, "Unregistered voter");
        require(
            crypto.verifyZeroOrOne(_vote, _Y, _zeroOrOneProof),
            "Invalid zero or one proof"
        );
        votes[msg.sender] = _vote;
    }

    function setTallyResult(uint256 _result, bytes32 _computationRoot) public {
        require(msg.sender == admin, "Only admin can set the tally result");
        require(
            block.number >= finishVotingBlockNumber &&
                block.number < finishTallyBlockNumber,
            "Tallying phase is already closed"
        );
        voteResult = _result;
        computationMerkleTreeRoot = _computationRoot;
    }

    function disputeTallyResult(
        uint256[3] memory t1,
        uint256[3] memory t2,
        bytes32[] memory proof1,
        bytes32[] memory proof2
    ) public {
        require(
            block.number >= finishTallyBlockNumber &&
                block.number < finishChallengeBlockNumber,
            "Dispute phase is already closed"
        );
        require(
            crypto.verifyMerkleProof(
                proof2,
                computationMerkleTreeRoot,
                keccak256(abi.encodePacked(t2))
            ),
            "Invalid Merkle proof for t2"
        );
        uint256 index = t2[0];
        if (index == 0) {
            //case 1
            uint256[2] memory c1 = votes[voters[index]];
            disputed = !crypto.Equal(c1, [t2[1], t2[2]]);
        } else if (index == t1[0] + 1) {
            //case 2
            require(
                crypto.verifyMerkleProof(
                    proof1,
                    computationMerkleTreeRoot,
                    keccak256(abi.encodePacked(t1))
                ),
                "Invalid Merkle proof for t1"
            );
            uint256[2] memory temp = crypto.ecAdd(
                votes[voters[index]],
                [t1[1], t1[2]]
            );
            disputed = !crypto.Equal(temp, [t2[1], t2[2]]);
        } else {
            //case 3
            disputed = !crypto.Equal(crypto.ecMul(voteResult), [t2[1], t2[2]]);
        }
        if (disputed) {
            voteResult = 0;
            payable(msg.sender).transfer(DEPOSIT);
        }
    }

    function reclaimDeposit() public {
        require(
            block.number >= finishChallengeBlockNumber,
            "Invalid reclaim deposit phase"
        );
        require(
            refunded[msg.sender] == false &&
                (votes[msg.sender][0] != 0 ||
                    (!disputed && msg.sender == admin)),
            "Illegal reclaim"
        );
        refunded[msg.sender] = true;
        payable(msg.sender).transfer(DEPOSIT);
    }
}
