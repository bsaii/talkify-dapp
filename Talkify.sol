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
 
    // Talk details
    struct Talk {
        uint256 id;
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
    event timesListened(
        uint256 timesListened
    );

    // the talk is valid
    modifier isValid(uint256 _id) {
        require(_id > 0 && _id <= talkCount, "Talk does not exist");
        _;
    }

    /** 
     * @dev Upload a talk
     * @param _audioHash: ipfs , _description: description of the talk.
     */
    function uploadTalk(string memory _audioHash, string memory _description) public onlyOwner {
        // description is not empty
        require(bytes(_description).length > 0, "Description cannot be empty");

        // audio hash is not empty
        require(bytes(_audioHash).length > 0, "Audio cannot be empty");

        // increment post id
        talkCount++;

        // adding talk to the contract
        talks[talkCount] = Talk({
            id: talkCount, 
            audioHash: _audioHash, 
            description: _description, 
            tipAmount: 0, 
            ratings: 0,
            timesListened: 0,
            author: payable(msg.sender)
        });

        // emit the event of talk created
        emit TalkCreated(talkCount, _audioHash, _description, payable(msg.sender));
    }

    /** 
     * @dev Tip the user that made a talk and increase ratings
     * @param _id: the id of the talk to tip
     */
    function tipTalker(uint256 _id) public payable isValid(_id){
        // Cannot tip talker 0 ETH
        require(msg.value > 0, "Cannot tip talker 0 ETH");

        // get the talk
        Talk memory _talk = talks[_id];

        // get the author of the talk
        address payable _author = _talk.author;

        // pay the author by the tip
        _author.transfer(msg.value);

        // update the tip amount
        _talk.tipAmount += msg.value;

        // increase the ratings by 100
        _talk.ratings += 100;

        // update the talk
        talks[_id] = _talk;

        // emit the event of a tip
        emit TalkTipped(
            _id, 
            _talk.audioHash, 
            _talk.description, 
            _talk.tipAmount, 
            _talk.ratings, 
            _author
        );
    }

    /** 
     * @dev Listen to talk uploaded
     * @param _id: the id of the talk to listen
     */
    function listenToTalk(uint256 _id) public isValid(_id) {
        // get the talk
        Talk memory _talk = talks[_id];

        // increment listeners
        _talk.timesListened++;

        // update the talk
        talks[_id] = _talk;

        // emit the number of times listened
        emit timesListened(_talk.timesListened);
    }

    /** 
     * @dev Remove a talk
     * @param _id: the id of the talk to be removed
     */
    function removeTalk(uint256 _id) public onlyOwner isValid(_id) {
        // delete the talk
        delete talks[_id];
    }

    /** 
     * @dev Returns the details of a talk
     * @param _id: the id of the talk to get the details
     */
    function getTalkDetails(uint256 _id) public view isValid(_id) returns (
        uint256 id,
        string memory audioHash,
        string memory description,
        uint256 tipAmount,
        uint256 ratings,
        uint256 listened,
        address payable author
    ) {
        // get the talk
        Talk memory _talk = talks[_id];

        // details of the talk
        id = _talk.id;
        audioHash = _talk.audioHash;
        description = _talk.description;
        tipAmount = _talk.tipAmount;
        ratings = _talk.ratings;
        listened = _talk.timesListened;
        author = _talk.author;
    }
}
