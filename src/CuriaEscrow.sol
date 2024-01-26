// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CuriaEscrow
 * @dev This contract implements an escrow mechanism with a grace period and deadline.
 * The depositor and beneficiary can deposit funds, and the arbiter can disable further
 * deposits and settle the escrow.
 */
contract CuriaEscrow {
  address public depositor;
  address public beneficiary;
  address public arbiter;
  uint256 public escrowDeadline;
  bool public depositsDisabled;
  uint256 public totalDeposits;

  mapping(address => uint256) public deposits;

  event DepositReceived(address indexed depositor, uint256 amount, uint256 totalDeposits);
  event Withdrawn(address indexed to, uint256 amount);
  event Settled(uint256 amountDepositor, uint256 amountBeneficiary);
  event DepositsDisabled();
  event DepositsEnabled();

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
   * @dev Initializes the contract by setting the parties involved, the escrow deadline, and the grace period end.
   * @param _depositor The address of the depositor.
   * @param _beneficiary The address of the beneficiary.
   * @param _arbiter The address of the arbiter.
   * @param _deadlineInHours The deadline of the escrow in hours.
   */
  constructor(
    address _depositor,
    address _beneficiary,
    address _arbiter,
    uint256 _deadlineInHours
    ){
    depositor = _depositor;
    beneficiary = _beneficiary;
    arbiter = _arbiter;
    escrowDeadline = block.timestamp + _deadlineInHours * 1 hours;
    depositsDisabled = false;
    totalDeposits = 0;
  }

  function _withdrawFunds(address recipient, uint256 amount) private {
    require(totalDeposits >= amount, "Insufficient balance to withdraw");
    totalDeposits -= amount;
    require(deposits[recipient] >= amount, "Insufficient balance to withdraw");
    deposits[recipient] -= amount;

    (bool success, ) = payable(recipient).call{value: amount}("");
    require(success, "Transfer failed");

    emit Withdrawn(recipient, amount);
  }

  /**
   * @dev Allows the depositor or beneficiary to deposit funds into the escrow.
   * Deposits are only permitted if they are not disabled.
   */
  function deposit() external payable onlyParties {
    require(!depositsDisabled, "No deposits allowed at this time");
    deposits[msg.sender] += msg.value;
    totalDeposits += msg.value;
    emit DepositReceived(msg.sender, msg.value, totalDeposits);
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
   * The total of amountToDepositor and amountToBeneficiary must equal the totalDeposits.
   * @param amountToDepositor The amount to be transferred to the depositor.
   * @param amountToBeneficiary The amount to be transferred to the beneficiary.
   */
  function settle(uint256 amountToDepositor, uint256 amountToBeneficiary) public onlyArbiter {
    require(depositsDisabled, "Deposits must be locked for settlement");
    uint256 totalPayout = amountToDepositor + amountToBeneficiary;
    require(totalPayout == totalDeposits, "Total payout must match total deposits");

    if (amountToDepositor > 0) {
      _withdrawFunds(depositor, amountToDepositor);
    }

    if (amountToBeneficiary > 0) {
      _withdrawFunds(beneficiary, amountToBeneficiary);
    }

    assert(address(this).balance == 0);

    emit Settled(amountToDepositor, amountToBeneficiary);
  }

    /**
     * @dev Allows either the depositor or beneficiary to withdraw their funds if the escrow deadline has passed and the escrow has not been settled.
     */
  function withdrawAfterDeadline() public onlyParties {
    require(block.timestamp >= escrowDeadline, "Deadline has not passed");

    uint256 refundAmount = deposits[msg.sender];

    if (refundAmount > 0) {
      _withdrawFunds(msg.sender, refundAmount);
    }
  }

}
