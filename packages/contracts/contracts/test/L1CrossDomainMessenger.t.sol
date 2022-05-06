//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/* Testing utilities */
import { CommonTest } from "./CommonTest.t.sol";
import { L2OutputOracle_Initializer } from "./L2OutputOracle.t.sol";

/* Libraries */
import {
    AddressAliasHelper
} from "@eth-optimism/contracts/standards/AddressAliasHelper.sol";
import {
    Lib_DefaultValues
} from "@eth-optimism/contracts/libraries/constants/Lib_DefaultValues.sol";
import {
    Lib_PredeployAddresses
} from "@eth-optimism/contracts/libraries/constants/Lib_PredeployAddresses.sol";
import {
    Lib_CrossDomainUtils
} from "@eth-optimism/contracts/libraries/bridge/Lib_CrossDomainUtils.sol";
import { WithdrawalVerifier } from "../libraries/Lib_WithdrawalVerifier.sol";

/* Target contract dependencies */
import { L2OutputOracle } from "../L1/L2OutputOracle.sol";
import { OptimismPortal } from "../L1/OptimismPortal.sol";

import { CrossDomainHashing } from "../libraries/Lib_CrossDomainHashing.sol";

/* Target contract */
import { L1CrossDomainMessenger } from "../L1/L1CrossDomainMessenger.sol";

import {
    ICrossDomainMessenger
} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

import { console } from "forge-std/console.sol";

contract L1CrossDomainMessenger_Test is CommonTest, L2OutputOracle_Initializer {
    // 'L2OutputOracle oracle' is declared in L2OutputOracle_Initializer
    OptimismPortal op;

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );

    event RelayedMessage(bytes32 indexed msgHash);

    event TransactionDeposited(
        address indexed from,
        address indexed to,
        uint256 mint,
        uint256 value,
        uint64 gasLimit,
        bool isCreation,
        bytes data
    );

    event WithdrawalFinalized(bytes32 indexed, bool success);

    // Contract under test
    L1CrossDomainMessenger messenger;

    // Receiver address for testing
    address recipient = address(0xabbaacdc);

    function setUp() external {
        // new portal with small finalization window
        op = new OptimismPortal(oracle, 100);
        messenger = new L1CrossDomainMessenger();
        messenger.initialize(op);
    }

    // pause: should pause the contract when called by the current owner
    function test_L1MessengerPause() external {
        messenger.pause();
        assert(messenger.paused());
    }

    // pause: should not pause the contract when called by account other than the owner
    function testCannot_L1MessengerPause() external {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(0xABBA));
        messenger.pause();
    }

    // the version is encoded in the nonce
    function test_L1MessengerMessageVersion() external {
        assertEq(
            CrossDomainHashing.getVersionFromNonce(messenger.messageNonce()),
            messenger.MESSAGE_VERSION()
        );
    }

    // sendMessage: should be able to send a single message
    // TODO: this same test needs to be done with the legacy message type
    // by setting the message version to 0
    function test_L1MessengerSendMessage() external {
        // deposit transaction on the optimism portal should be called
        vm.expectCall(
            address(op),
            abi.encodeWithSelector(
                OptimismPortal.depositTransaction.selector,
                Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER,
                0,
                100,
                false,
                CrossDomainHashing.getVersionedEncoding(
                    messenger.messageNonce(),
                    alice,
                    recipient,
                    0,
                    100,
                    hex"ff"
                )
            )
        );

        // TransactionDeposited event
        vm.expectEmit(true, true, true, true);
        emit TransactionDeposited(
            AddressAliasHelper.applyL1ToL2Alias(address(messenger)),
            Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER,
            0,
            0,
            100,
            false,
            CrossDomainHashing.getVersionedEncoding(
                messenger.messageNonce(),
                alice,
                recipient,
                0,
                100,
                hex"ff"
            )
        );

        // SentMessage event
        vm.expectEmit(true, true, true, true);
        emit SentMessage(
           recipient,
           alice,
           hex"ff",
           messenger.messageNonce(),
           100
        );

        vm.prank(alice);
        messenger.sendMessage(recipient, hex"ff", uint32(100));
    }

    // sendMessage: should be able to send the same message twice
    function test_L1MessengerTwiceSendMessage() external {
        uint256 nonce = messenger.messageNonce();
        messenger.sendMessage(recipient, hex"aa", uint32(500_000));
        messenger.sendMessage(recipient, hex"aa", uint32(500_000));
        // the nonce increments for each message sent
        assertEq(
            nonce + 2,
            messenger.messageNonce()
        );
    }

    function test_L1MessengerXDomainSenderReverts() external {
        vm.expectRevert("xDomainMessageSender is not set");
        messenger.xDomainMessageSender();
    }

    // xDomainMessageSender: should return the xDomainMsgSender address
    // TODO: might need a test contract
    // function test_xDomainSenderSetCorrectly() external {}

    // relayMessage: should send a successful call to the target contract
    function test_L1MessengerRelayMessageSucceeds() external {
        address target = address(0xabcd);
        address sender = Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER;

        vm.expectCall(target, hex"1111");

        // set the value of op.l2Sender() to be the L2 Cross Domain Messenger.
        vm.store(address(op), 0, bytes32(abi.encode(sender)));
        vm.prank(address(op));

        vm.expectEmit(true, true, true, true);

        bytes32 hash = CrossDomainHashing.getVersionedHash(
            0,
            sender,
            target,
            0,
            0,
            hex"1111"
        );

        emit RelayedMessage(hash);

        messenger.relayMessage(
            0, // nonce
            sender,
            target,
            0, // value
            0,
            hex"1111"
        );

        // the message hash is in the successfulMessages mapping
        assert(messenger.successfulMessages(hash));
        // it is not in the received messages mapping
        assertEq(messenger.receivedMessages(hash), false);
    }

    // relayMessage: should revert if attempting to relay a message sent to an L1 system contract
    function test_L1MessengerRelayMessageToSystemContract() external {
        // set the target to be the OptimismPortal
        address target = address(op);
        address sender = Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER;
        bytes memory message = hex"1111";

        // set the value of op.l2Sender() to be the L2 Cross Domain Messenger.
        vm.prank(address(op));
        vm.expectRevert("Message cannot be replayed.");
        messenger.relayMessage(0, sender, target, 0, 0, message);

        vm.store(address(op), 0, bytes32(abi.encode(sender)));
        vm.expectRevert("Message cannot be replayed.");
        messenger.relayMessage(0, sender, target, 0, 0, message);
    }

    // relayMessage: the xDomainMessageSender is reset to the original value
    function test_L1MessengerxDomainMessageSenderResets() external {
        vm.expectRevert("xDomainMessageSender is not set");
        messenger.xDomainMessageSender();

        address sender = Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER;
        vm.store(address(op), 0, bytes32(abi.encode(sender)));
        vm.prank(address(op));
        messenger.relayMessage(0, address(0), address(0), 0, 0, hex"");

        vm.expectRevert("xDomainMessageSender is not set");
        messenger.xDomainMessageSender();
    }

    // relayMessage: should revert if paused
    function test_L1MessengerRelayShouldRevertIfPaused() external {
        vm.prank(messenger.owner());
        messenger.pause();

        vm.expectRevert("Pausable: paused");
        messenger.relayMessage(0, address(0), address(0), 0, 0, hex"");
    }
}
