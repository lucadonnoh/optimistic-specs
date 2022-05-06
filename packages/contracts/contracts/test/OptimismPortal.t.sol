//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/* Testing utilities */
import { CommonTest } from "./CommonTest.t.sol";

/* Target contract dependencies */
import { L2OutputOracle } from "../L1/L2OutputOracle.sol";

/* Target contract */
import { OptimismPortal } from "../L1/OptimismPortal.sol";

contract OptimismPortal_Test is CommonTest {
    event TransactionDeposited(
        address indexed from,
        address indexed to,
        uint256 mint,
        uint256 value,
        uint64 gasLimit,
        bool isCreation,
        bytes data
    );

    // Dependencies
    L2OutputOracle oracle;
    OptimismPortal op;

    function setUp() external {
        oracle = new L2OutputOracle(
            1800,
            2,
            keccak256(abi.encode(0)),
            100,
            1,
            address(666)
        );
        op = new OptimismPortal(oracle, 7 days);
    }

    function test_OptimismPortalConstructor() external {
        assertEq(op.FINALIZATION_PERIOD(), 7 days);
        assertEq(address(op.L2_ORACLE()), address(oracle));
        assertEq(op.l2Sender(), 0x000000000000000000000000000000000000dEaD);
    }

    function test_OptimismPortalReceiveEth() external {
        vm.expectEmit(true, true, false, true);
        emit TransactionDeposited(
            alice,
            alice,
            100,
            100,
            100_000,
            false,
            hex""
        );

        // give alice money and send as an eoa
        vm.deal(alice, 2**64);
        vm.prank(alice, alice);
        (bool s, ) = address(op).call{ value: 100 }(hex"");

        assert(s);
        assertEq(address(op).balance, 100);
    }

    // function test_OptimismPortalDepositTransaction() external {}
}
