// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Talkify
 * @dev Podcast hosting platform for users to upload, listen and tip(increase rating)
    prodcasts.
 */
contract Talkify is Ownable {
    // Store Talks
    uint256 public talkCount = 0;

    mapping(uint256 => Talk) public talks;
    mapping(uint256 => bool) private _exists;
    mapping(address => mapping(uint => bool)) public listened;

    // Talk details
    struct Talk {
        string audioHash;
        string description;
        uint256 tipAmount;
        uint256 ratings;
        uint256 timesListened;
        address payable author;
    }

    // A talk is created
    event TalkCreated(
        uint256 indexed id,
        string audioHash,
        string description,
        address payable author
    );

    // A talk is tipped and rated
    event TalkTipped(
        uint256 indexed id,
        string imageHash,
        string description,
        uint256 tipAmount,
        uint256 ratings,
        address payable author
    );

    // Number of times a talk was listened to
    event timesListened(uint indexed id, uint256 timesListened);

    // the talk is valid
    modifier exists(uint _id) {
        require(_exists[_id], "Talk does not exist");
        _;
    }

    /**
     * @dev Upload a talk
     * @param _audioHash: ipfs , _description: description of the talk.
     */
    function uploadTalk(
        string calldata _audioHash,
        string calldata _description
    ) public {
        // description is not empty
        require(bytes(_description).length > 0, "Description cannot be empty");

        // audio hash is not empty
        require(bytes(_audioHash).length > 0, "Audio cannot be empty");

        // increment post id
        talkCount++;

        // adding talk to the contract
        talks[talkCount] = Talk({
            audioHash: _audioHash,
            description: _description,
            tipAmount: 0,
            ratings: 0,
            timesListened: 0,
            author: payable(msg.sender)
        });

        // talk exists
        _exists[talkCount] = true;

        // emit the event of talk created
        emit TalkCreated(
            talkCount,
            _audioHash,
            _description,
            payable(msg.sender)
        );
    }

    /**
     * @dev Tip the user that made a talk and increase ratings
     * @param _id: the id of the talk to tip
     */
    function tipTalker(uint256 _id) public payable exists(_id) {
        // Cannot tip talker 0 ETH
        require(msg.value > 0, "Cannot tip talker 0 ETH");

        // get the talk
        Talk storage _talk = talks[_id];

        // Owner cannot tip themselves
        require(_talk.author != msg.sender, "You can't tip yourself");

        // update the tip amount
        uint newTipAmount = _talk.tipAmount + msg.value;
        _talk.tipAmount = newTipAmount;

        // increase the ratings by 100
        _talk.ratings += 100;

        // pay the author by the tip
        (bool success, ) = payable(_talk.author).call{value: msg.value}("");
        require(success, "Transfer of tip failed");

        // emit the event of a tip
        emit TalkTipped(
            _id,
            _talk.audioHash,
            _talk.description,
            _talk.tipAmount,
            _talk.ratings,
            _talk.author
        );
    }

    /**
     * @dev Listen to talk uploaded
     * @param _id: the id of the talk to listen
     */
    function listenToTalk(uint256 _id) public exists(_id) {
        // User has already listened
        require(!listened[msg.sender][_id], "Already listened to podcast");

        // get the talk
        Talk storage _talk = talks[_id];
        
        // listened to the talk
        listened[msg.sender][_id] = true;

        // increment listeners
        _talk.timesListened++;

        // emit the number of times listened
        emit timesListened(_id, _talk.timesListened);
    }

    /**
     * @dev Remove a talk
     * @param _id: the id of the talk to be removed
     */
    function removeTalk(uint256 _id) public onlyOwner exists(_id) {
        // talk does not exit
        _exists[_id] = false;
        // delete the talk
        delete talks[_id];
    }

    /**
     * @dev Returns the details of a talk
     * @param _id: the id of the talk to get the details
     */
    function getTalkDetails(uint256 _id)
        public
        view
        exists(_id)
        returns (
            string memory audioHash,
            string memory description,
            uint256 tipAmount,
            uint256 ratings,
            uint256 timeListened,
            address payable author
        )
    {
        // get the talk
        Talk memory _talk = talks[_id];

        // details of the talk
        audioHash = _talk.audioHash;
        description = _talk.description;
        tipAmount = _talk.tipAmount;
        ratings = _talk.ratings;
        timeListened = _talk.timesListened;
        author = _talk.author;
    }
}
