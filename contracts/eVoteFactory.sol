pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./CloneFactory.sol";
import "./eVote.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract eVoteFactory is CloneFactory, Ownable{
    eVote[] public eVoteAddresses;
    event eVoteCreated(eVote evote);

    address public masterImplementAdr;
    address private eVoteOwner;

    function setMasterImplementAdr(address _masterImplementAdr) external onlyOwner{
        masterImplementAdr=_masterImplementAdr;
    }

    function createeVote() external{
        eVote evote = eVote(createClone(masterImplementAdr));
        evote.initialize();
        eVoteAddresses.push(evote);
        emit eVoteCreated(evote);
    }
}