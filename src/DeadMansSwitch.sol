// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DeadMansSwitch {

    address public owner;
    uint256 public checkInInterval;
    uint256 public gracePeriod;
    uint256 public lastCheckIn;

    enum Status { Active, GracePeriod, Triggered, Cancelled }
    Status public status;

    struct Beneficiary {
        address wallet;
        uint256 sharePercent;
    }

    Beneficiary[] public beneficiaries;

    event CheckedIn(address indexed owner, uint256 timestamp);
    event GracePeriodStarted(uint256 deadline);
    event SwitchTriggered(uint256 timestamp);
    event BeneficiaryClaimed(address indexed beneficiary, uint256 amount);
    event Cancelled(address indexed owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _checkInInterval, uint256 _gracePeriod) {
        owner = msg.sender;
        checkInInterval = _checkInInterval;
        gracePeriod = _gracePeriod;
        lastCheckIn = block.timestamp;
        status = Status.Active;
    }

    function deposit() external payable onlyOwner {
        require(msg.value > 0, "Send ETH");
    }

    function checkIn() external onlyOwner {
        require(status == Status.Active || status == Status.GracePeriod, "Cannot check in");
        lastCheckIn = block.timestamp;
        status = Status.Active;
        emit CheckedIn(msg.sender, block.timestamp);
    }

    function addBeneficiary(address wallet, uint256 share) external onlyOwner {
        require(wallet != address(0), "Invalid address");
        require(share > 0 && share <= 100, "Invalid share");
        beneficiaries.push(Beneficiary(wallet, share));
    }

    function removeBeneficiary(address wallet) external onlyOwner {
        for (uint i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i].wallet == wallet) {
                beneficiaries[i] = beneficiaries[beneficiaries.length - 1];
                beneficiaries.pop();
                break;
            }
        }
    }

    function triggerGracePeriod() external {
        require(status == Status.Active, "Not active");
        require(block.timestamp > lastCheckIn + checkInInterval, "Not overdue yet");
        status = Status.GracePeriod;
        emit GracePeriodStarted(block.timestamp + gracePeriod);
    }

    function claim() external {
        require(status == Status.GracePeriod, "Not in grace period");
        require(
            block.timestamp > lastCheckIn + checkInInterval + gracePeriod,
            "Grace period not over"
        );
        status = Status.Triggered;
        emit SwitchTriggered(block.timestamp);
        uint256 totalETH = address(this).balance;
        for (uint i = 0; i < beneficiaries.length; i++) {
            uint256 share = (totalETH * beneficiaries[i].sharePercent) / 100;
            (bool ok, ) = beneficiaries[i].wallet.call{value: share}("");
            require(ok, "ETH transfer failed");
            emit BeneficiaryClaimed(beneficiaries[i].wallet, share);
        }
    }

    function cancel() external onlyOwner {
        require(
            status == Status.Active || status == Status.GracePeriod,
            "Cannot cancel"
        );
        status = Status.Cancelled;
        (bool ok, ) = owner.call{value: address(this).balance}("");
        require(ok, "Transfer failed");
        emit Cancelled(owner);
    }

    receive() external payable {}
}