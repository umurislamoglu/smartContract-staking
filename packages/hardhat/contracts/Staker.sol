// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    //Constants
    uint256 public constant threshold = 1 ether;

    //Variables
    mapping(address => uint256) public balances;
    uint256 public deadline = block.timestamp + 30 seconds;

    //Events
    event Stake(address indexed sender, uint256 stakeAmount);

    //Modifiers
    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Staking already completed");
        _;
    }

    modifier deadlineReached(bool needsToBeReached) {
        uint256 timeRemaining = timeLeft();
        if (needsToBeReached) {
            require(timeRemaining == 0, "Deadline is not reached yet");
        } else {
            require(timeRemaining > 0, "Deadline is already reached");
        }
        _;
    }

    //Constructor
    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    //Functions
    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable deadlineReached(false) notCompleted {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() public deadlineReached(true) notCompleted {
        uint256 totalBalance = address(this).balance;
        if (totalBalance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() public deadlineReached(true) notCompleted {
        uint256 stakerBalance = balances[msg.sender];
        require(stakerBalance > 0, "You didn't staked on this contract");
        (bool sent, ) = msg.sender.call{value: stakerBalance}("");
        require(sent, "Failed to send user balance back to the user");
        balances[msg.sender] = 0;
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    receive() external payable {
        stake();
    }
}
