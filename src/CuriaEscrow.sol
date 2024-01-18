// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CuriaEscrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    uint256 public escrowDeadline;
    uint256 public gracePeriodEnd;
    bool public depositsLocked;

    mapping(address => uint256) public deposits;

    event DepositReceived(address depositor, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event Settled(uint256 amountDepositor, uint256 amountBeneficiary);
    event GracePeriodWithdrawal(uint256 amountDepositor, uint256 amountBeneficiary);
    event DepositsLocked();

    constructor(
      address _depositor,
      address _beneficiary,
      address _arbiter,
      uint256 _deadlineInHours,
      uint256 _gracePeriodInHours
      ){
      depositor = _depositor;
      beneficiary = _beneficiary;
      arbiter = _arbiter;
      escrowDeadline = block.timestamp + _deadlineInHours * 1 hours;
      gracePeriodEnd = block.timestamp + _gracePeriodInHours * 1 hours;
      depositsLocked = false;
    }

    // allow both parties to deposit to the escrow, since some might simply want skin in the game
    function deposit() external payable {
      require(!depositsLocked, "No deposits allowed at this time");
      require(msg.sender == depositor || msg.sender == beneficiary, "Only parties can deposit");
      deposits[msg.sender] += msg.value;
      emit DepositReceived(msg.sender, msg.value);
    }

    function lockDeposits() public {
      require(msg.sender == arbiter, "Only arbiter can lock deposits");
      depositsLocked = true;
      emit DepositsLocked();
    }

    function settle(uint256 amountToDepositor, uint256 amountToBeneficiary) public {
      require(msg.sender == arbiter, "Only arbiter can approve");
      require(depositsLocked, "Deposits must be locked for settlement");
      require(amountToDepositor <= deposits[depositor], "Insufficient balance for depositor");
      require(amountToBeneficiary <= deposits[beneficiary], "Insufficient balance for beneficiary");
      require(amountToBeneficiary <= deposits[beneficiary], "Insufficient balance for beneficiary");

      if(amountToDepositor > 0) {
        deposits[depositor] -= amountToDepositor;
        payable(depositor).transfer(amountToDepositor);
        emit Withdrawn(depositor, amountToDepositor);
      }

      if(amountToBeneficiary >0) {
        deposits[beneficiary] -= amountToBeneficiary;
        payable(beneficiary).transfer(amountToBeneficiary);
        emit Withdrawn(beneficiary, amountToBeneficiary);
      }

      emit Settled(amountToDepositor, amountToBeneficiary);
    }

    function gracePeriodWithdraw() public {
      require(block.timestamp <= gracePeriodEnd, "Grace period has ended");
      require(block.timestamp < escrowDeadline, "Escrow deadline has passed");
      require(msg.sender == beneficiary || msg.sender == depositor,"Only the parties can withdraw during grace period");
      uint256 depositorRefund = deposits[depositor];
      uint256 beneficiaryRefund = deposits[beneficiary];

      if (depositorRefund > 0) {
        deposits[depositor] = 0;
        payable(depositor).transfer(depositorRefund);
        emit Withdrawn(depositor, depositorRefund);
      }

      if (beneficiaryRefund > 0) {
        deposits[beneficiary] = 0;
        payable(beneficiary).transfer(beneficiaryRefund);
        emit Withdrawn(beneficiary, beneficiaryRefund);
      }

      emit GracePeriodWithdrawal(depositorRefund, beneficiaryRefund);

    }

    function withdrawByDepositor() public {
      require(msg.sender == depositor, "Only depositor can withdraw");
      require(block.timestamp >= escrowDeadline, "Deadline has not passed");
      require(address(this).balance > 0, "No funds to release");
      emit WithdrawnByDepositor(address(this).balance);
      payable(depositor).transfer(address(this).balance);
    }
}
