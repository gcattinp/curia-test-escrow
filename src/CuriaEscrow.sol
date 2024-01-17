// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CuriaEscrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    uint256 public escrowDeadline;
    uint256 public gracePeriodEnd;

    event DepositReceived(address depositor, uint256 amount);
    event Approved(uint256 amount);
    event WithdrawnByDepositor(uint256 amount);
    event GracePeriod(uint256 amount);

    constructor(
      address _beneficiary,
      address _arbiter,
      uint256 _deadlineInHours,
      uint256 _gracePeriodInHours
      ){
        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        escrowDeadline = block.timestamp + _deadlineInHours * 1 hours;
        gracePeriodEnd = block.timestamp + _gracePeriodInHours * 1 hours;
    }

    function deposit() external payable {
        require(msg.sender == depositor, "Only depositor can deposit");
        emit DepositReceived(msg.sender, msg.value);
    }

    function approve() public {
        require(msg.sender == arbiter, "Only arbiter can approve");
        require(address(this).balance > 0, "No funds to release");
        emit Approved(address(this).balance);
        payable(beneficiary).transfer(address(this).balance);
    }

    function withdrawByDepositor() public {
      require(msg.sender == depositor, "Only depositor can withdraw");
      require(block.timestamp >= escrowDeadline, "Deadline has not passed");
      require(address(this).balance > 0, "No funds to release");
      emit WithdrawnByDepositor(address(this).balance);
      payable(depositor).transfer(address(this).balance);
    }

    function gracePeriodWithdraw() public {
      require(msg.sender == beneficiary || msg.sender == depositor, "Only the parties can approve");
      require(block.timestamp <= gracePeriodEnd, "Grace period has ended");
      require(address(this).balance > 0, "No funds to release");
      emit GracePeriod(address(this).balance);
      payable(depositor).transfer(address(this).balance);
    }
}
