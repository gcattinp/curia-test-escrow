// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CuriaEscrow
 * @dev This contract implements an escrow mechanism with a grace period and deadline.
 * The depositor and beneficiary can deposit funds, and the arbiter can disable further
 * deposits and settle the escrow. Parties can withdraw funds during the grace period
 * or after the deadline.
 */
contract CuriaEscrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    uint256 public escrowDeadline;
    uint256 public gracePeriodEnd;
    bool public depositsDisabled;

    mapping(address => uint256) public deposits;

    event DepositReceived(address depositor, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event Settled(uint256 amountDepositor, uint256 amountBeneficiary);
    event GracePeriodWithdrawal(uint256 amountDepositor, uint256 amountBeneficiary);
    event DepositsDisabled();
    event DepositsEnabled();

    /**
     * @dev Initializes the contract by setting the parties involved, the escrow deadline, and the grace period end.
     * @param _depositor The address of the depositor.
     * @param _beneficiary The address of the beneficiary.
     * @param _arbiter The address of the arbiter.
     * @param _deadlineInHours The deadline of the escrow in hours.
     * @param _gracePeriodInHours The end of the grace period in hours.
     */
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
      depositsDisabled = false;
    }

    /**
     * @dev Ensures the function is called only by the arbiter.
     */
    modifier onlyArbiter() {
      require(msg.sender == arbiter, "Only arbiter can call this function");
      _;
    }

    /**
     * @dev Ensures the function is called only by the depositor or the beneficiary.
     */
    modifier onlyParties() {
      require(msg.sender == depositor || msg.sender == beneficiary, "Only the parties can perform this action");
      _;
    }

    /**
     * @dev Allows the depositor or beneficiary to deposit funds into the escrow.
     * Deposits are only permitted if they are not disabled.
     */
    function deposit() external payable onlyParties {
      require(!depositsDisabled, "No deposits allowed at this time");
      deposits[msg.sender] += msg.value;
      emit DepositReceived(msg.sender, msg.value);
    }

    /**
     * @dev Allows the arbiter to disable further deposits into the escrow.
     */
    function disableDeposits() public onlyArbiter {
      depositsDisabled = true;
      emit DepositsDisabled();
    }

    /**
     * @dev Allows the arbiter to re-enable deposits into the escrow.
     */
    function enableDeposits() public onlyArbiter {
      depositsDisabled = false;
      emit DepositsEnabled();
    }

    /**
     * @dev Allows the arbiter to settle the escrow by specifying the amounts to be sent to the depositor and beneficiary.
     * Requires that deposits are disabled before settlement.
     * @param amountToDepositor The amount to be transferred to the depositor.
     * @param amountToBeneficiary The amount to be transferred to the beneficiary.
     */
    function settle(uint256 amountToDepositor, uint256 amountToBeneficiary) public onlyArbiter {
      require(depositsDisabled, "Deposits must be locked for settlement");
      require(amountToDepositor <= deposits[depositor], "Insufficient balance for depositor");
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

    /**
     * @dev Allows either the depositor or beneficiary to withdraw their funds if the escrow is canceled during the grace period.
     */
    function gracePeriodWithdraw() public onlyParties {
      require(block.timestamp <= gracePeriodEnd, "Grace period has ended");
      require(block.timestamp < escrowDeadline, "Escrow deadline has passed");

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

    /**
     * @dev Allows either the depositor or beneficiary to withdraw their funds if the escrow deadline has passed and the escrow has not been settled.
     */
    function withdrawAfterDeadline() public onlyParties {
      require(block.timestamp >= escrowDeadline, "Deadline has not passed");

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
    }
}
