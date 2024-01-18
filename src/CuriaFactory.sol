// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./CuriaEscrow.sol";

contract CuriaFactory {
    CuriaEscrow[] public escrows;

    event EscrowCreated(address indexed depositor, address escrowAddress);

    function createEscrow(
        address _beneficiary,
        address _arbiter,
        uint256 _deadlineInHours,
        uint256 _gracePeriodInHours
    ) public {
        CuriaEscrow newEscrow = new CuriaEscrow(
            msg.sender,
            _beneficiary,
            _arbiter,
            _deadlineInHours,
            _gracePeriodInHours
        );
        escrows.push(newEscrow);
        emit EscrowCreated(msg.sender, address(newEscrow));
    }

    function getAllEscrows() external view returns (CuriaEscrow[] memory) {
        return escrows;
    }
}
