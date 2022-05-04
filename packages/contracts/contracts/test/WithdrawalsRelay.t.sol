//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/* Testing utilities */
import { CommonTest } from "./CommonTest.t.sol";

/* Target contract dependencies */
import { L2OutputOracle } from "../L1/L2OutputOracle.sol";
import { WithdrawalVerifier } from "../libraries/Lib_WithdrawalVerifier.sol";

/* Target contract */
import { WithdrawalsRelay } from "../L1/abstracts/WithdrawalsRelay.sol";

contract Target is WithdrawalsRelay {
    constructor(L2OutputOracle _l2Oracle, uint256 _finalizationPeriod)
        WithdrawalsRelay(_l2Oracle, _finalizationPeriod)
    {}
}

contract WithdrawalsRelay_finalizeWithdrawalTransaction_Test is CommonTest {
    event TransactionDeposited(
        address indexed from,
        address indexed to,
        uint256 mint,
        uint256 value,
        uint256 additionalGasPrice,
        uint64 additionalGasLimit,
        uint64 guaranteedGas,
        bool isCreation,
        bytes data
    );

    // Dependencies
    L2OutputOracle oracle;

    // Oracle constructor arguments
    address sequencer = 0x000000000000000000000000000000000000AbBa;
    uint256 submissionInterval = 1800;
    uint256 l2BlockTime = 2;
    bytes32 genesisL2Output = keccak256(abi.encode(0));
    uint256 historicalTotalBlocks = 100;

    // Test target
    Target wr;

    // Target constructor arguments
    address withdrawalsPredeploy = 0x4200000000000000000000000000000000000015;

    // Cache of timestamps
    uint256 startingBlockTimestamp;
    uint256 appendedTimestamp;

    // By default the first block has timestamp zero, which will cause underflows in the tests,
    // so we jump ahead to the exact time that I wrote this line.
    uint256 initTime = 1648757197;

    // Withdrawal call parameters
    uint256 wdNonce = 1;
    address wdSender = address(0x02);
    address wdTarget = address(0x03);
    uint256 wdValue = 4;
    uint256 wdGasLimit = 500000;
    bytes wdData = hex"06";

    // Generate an output and corresponding proof that we can work with. We can use whatever values
    // we want except for the withdrawerStorageRoot. These roots and the proof were generated by
    // running scripts/makeProof.ts with the above withdrawal call parameters as arguments.
    bytes32 version = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 stateRoot = 0x187c35d79aa836b74475ff4940e0eff42e2ee5661f136995b4470bb92cf0813d;
    bytes32 withdrawerStorageRoot =
        0x7f58036a634aca208c3e571f8306f314f83964313bc0725ceec76d839a097e79; // eth_getProof (storageHash)
    bytes32 latestBlockhash = 0x0000000000000000000000000000000000000000000000000000000000000000;

    bytes withdrawalProof =
        hex"e5a4e3a120453242a1d87fab6d401bd84b3d16c8d3f6a65142a069568067e7c2980af50e2801";

    // we'll set this value in the `setUp` function and cache it here for reuse in each test
    WithdrawalVerifier.OutputRootProof outputRootProof;

    constructor() {
        // Move time forward so we have a non-zero starting timestamp
        vm.warp(initTime);

        // Deploy the L2OutputOracle and transfer owernship to the sequencer
        oracle = new L2OutputOracle(
            submissionInterval,
            l2BlockTime,
            genesisL2Output,
            historicalTotalBlocks,
            initTime,
            sequencer
        );
        startingBlockTimestamp = block.timestamp;

        wr = new Target(oracle, 7 days);
    }

    function setUp() external {
        vm.warp(initTime);
        bytes32 outputRoot = keccak256(
            abi.encode(version, stateRoot, withdrawerStorageRoot, latestBlockhash)
        );

        uint256 nextTimestamp = oracle.nextTimestamp();
        // Warp to 1 second after the timestamp we'll append
        vm.warp(nextTimestamp + 1);
        vm.prank(sequencer);
        oracle.appendL2Output(outputRoot, nextTimestamp, 0, 0);

        // cache the appendedTimestamp
        appendedTimestamp = nextTimestamp;
        outputRootProof = WithdrawalVerifier.OutputRootProof({
            version: version,
            stateRoot: stateRoot,
            withdrawerStorageRoot: withdrawerStorageRoot,
            latestBlockhash: latestBlockhash
        });

    }

    function test_verifyWithdrawal() external {
        // todo: get FFI working for this test
        // string[] memory inputs = new string[](3);
        // inputs[0] = "ts-node";
        // inputs[1] = "scripts/makeProof";
        // inputs[2] = string(abi.encode(wdNonce, wdSender, wdTarget, wdValue, wdGasLimit, wdData));
        // Warp to after the finality window
        vm.warp(appendedTimestamp + 7 days);
        wr.finalizeWithdrawalTransaction(
            wdNonce,
            wdSender,
            wdTarget,
            wdValue,
            wdGasLimit,
            wdData,
            appendedTimestamp,
            outputRootProof,
            withdrawalProof
        );
    }

    function test_cannotVerifyRecentWithdrawal() external {
        // This call should fail because the output root we're using was appended 1 second ago.
        vm.expectRevert(abi.encodeWithSignature("NotYetFinal()"));
        wr.finalizeWithdrawalTransaction(
            wdNonce,
            wdSender,
            wdTarget,
            wdValue,
            wdGasLimit,
            wdData,
            appendedTimestamp,
            outputRootProof,
            hex"ffff"
        );
    }

    function test_cannotVerifyInvalidProof() external {
        // This call should fail because the output proof is modified
        vm.warp(appendedTimestamp + 7 days);
        vm.expectRevert(abi.encodeWithSignature("InvalidOutputRootProof()"));
        WithdrawalVerifier.OutputRootProof memory invalidOutpuRootProof = outputRootProof;
        invalidOutpuRootProof.latestBlockhash = bytes32(hex"01");
        wr.finalizeWithdrawalTransaction(
            wdNonce,
            wdSender,
            wdTarget,
            wdValue,
            wdGasLimit,
            wdData,
            appendedTimestamp,
            invalidOutpuRootProof,
            hex"ffff"
        );
    }
}
