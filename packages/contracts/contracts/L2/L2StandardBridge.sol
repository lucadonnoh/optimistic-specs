// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Interface Imports */
import { IL1ERC20Bridge } from "@eth-optimism/contracts/L1/messaging/IL1ERC20Bridge.sol";
import { IL2ERC20Bridge } from "../interfaces/IL2ERC20Bridge.sol";
import { IL1StandardBridge } from "../interfaces/IL1StandardBridge.sol";

/* Library Imports */
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {
    Lib_PredeployAddresses
} from "@eth-optimism/contracts/libraries/constants/Lib_PredeployAddresses.sol";
import { AddressAliasHelper } from "@eth-optimism/contracts/standards/AddressAliasHelper.sol";

/* Contract Imports */
import { IL2StandardERC20 } from "@eth-optimism/contracts/standards/IL2StandardERC20.sol";
import { CrossDomainMessenger } from "../universal/CrossDomainMessenger.sol";

/**
 * @title L2StandardBridge
 * @dev The L2 Standard bridge is a contract which works together with the L1 Standard bridge to
 * enable ETH and ERC20 transitions between L1 and L2.
 * This contract acts as a minter for new tokens when it hears about deposits into the L1 Standard
 * bridge.
 * This contract also acts as a burner of the tokens intended for withdrawal, informing the L1
 * bridge to release L1 funds.
 */
contract L2StandardBridge is IL2ERC20Bridge {
    /**********
     * Errors *
     **********/

    /// @notice Represents invalid value handling to prevent stuck ETH
    error InvalidWithdrawalAmount();

    /********************************
     * External Contract References *
     ********************************/

    address public l1TokenBridge;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _l1TokenBridge Address of the L1 bridge deployed to the main chain.
     */
    constructor(address _l1TokenBridge) {
        l1TokenBridge = _l1TokenBridge;
    }

    /***************
     * Withdrawing *
     ***************/

    /**
     * @inheritdoc IL2ERC20Bridge
     */
    function withdraw(
        address _l2Token,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) external payable virtual {
        _initiateWithdrawal(_l2Token, msg.sender, msg.sender, _amount, _l1Gas, _data);
    }

    /**
     * @inheritdoc IL2ERC20Bridge
     */
    function withdrawTo(
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) external payable virtual {
        _initiateWithdrawal(_l2Token, msg.sender, _to, _amount, _l1Gas, _data);
    }

    function withdrawETH() external payable {
        _initiateETHWithdrawal(msg.sender, msg.sender, msg.value, 30000, hex"");
    }

    function withdrawETHTo(
        address _to,
        uint256 _l1Gas,
        bytes calldata _data
    ) external payable {
        _initiateETHWithdrawal(msg.sender, _to, msg.value, _l1Gas, _data);
    }

    function _initiateETHWithdrawal(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _l1Gas,
        bytes memory _data
    ) internal {
        // Send message up to L1 bridge
        CrossDomainMessenger(Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER).sendMessage{
            value: _amount
        }(
            l1TokenBridge,
            abi.encodeWithSelector(
                IL1StandardBridge.finalizeETHWithdrawal.selector,
                _from,
                _to,
                _amount,
                _data
            ),
            uint32(_l1Gas) // TODO(tynes): this isn't safe
        );

        emit WithdrawalInitiated(
            address(0),
            Lib_PredeployAddresses.OVM_ETH,
            msg.sender,
            _to,
            _amount,
            _data
        );
    }

    function _initiateERC20Withdrawal(
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) internal {
        // When a withdrawal is initiated, we burn the withdrawer's funds to prevent
        // subsequent L2 usage
        // slither-disable-next-line reentrancy-events
        IL2StandardERC20(_l2Token).burn(msg.sender, _amount);

        // slither-disable-next-line reentrancy-events
        address l1Token = IL2StandardERC20(_l2Token).l1Token();

        // Send message up to L1 bridge
        CrossDomainMessenger(Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER).sendMessage(
            l1TokenBridge,
            abi.encodeWithSelector(
                IL1ERC20Bridge.finalizeERC20Withdrawal.selector,
                l1Token,
                _l2Token,
                _from,
                _to,
                _amount,
                _data
            ),
            _l1Gas
        );

        // slither-disable-next-line reentrancy-events
        emit WithdrawalInitiated(l1Token, _l2Token, msg.sender, _to, _amount, _data);
    }

    /**
     * @dev Performs the logic for withdrawals by burning the token and informing
     *      the L1 token Gateway of the withdrawal.
     * @param _l2Token Address of L2 token where withdrawal is initiated.
     * @param _from Account to pull the withdrawal from on L2.
     * @param _to Account to give the withdrawal to on L1.
     * @param _amount Amount of the token to withdraw.
     * @param _l1Gas Unused, but included for potential forward compatibility considerations.
     * @param _data Optional data to forward to L1. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function _initiateWithdrawal(
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) internal {
        if (_l2Token == Lib_PredeployAddresses.OVM_ETH) {
            if (msg.value != _amount) {
                revert InvalidWithdrawalAmount();
            }

            _initiateETHWithdrawal(_from, _to, _amount, _l1Gas, _data);
        } else {
            if (msg.value != 0) {
                revert InvalidWithdrawalAmount();
            }

            _initiateERC20Withdrawal(_l2Token, _from, _to, _amount, _l1Gas, _data);
        }
    }

    /************************************
     * Cross-chain Function: Depositing *
     ************************************/

    /**
     * @inheritdoc IL2ERC20Bridge
     */

    function finalizeDeposit(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable virtual {
        // Since it is impossible to deploy a contract to an address on L2 which matches
        // the alias of the l1TokenBridge, this check can only pass when it is called in
        // the first call frame of a deposit transaction. Thus reentrancy is prevented here.
        require(
            AddressAliasHelper.undoL1ToL2Alias(msg.sender) == l1TokenBridge,
            "Can only be called by a the l1TokenBridge"
        );

        // Check to see if the bridge is being used to deposit ETH.
        // The `msg.value` must match the `_amount` to prevent
        // ETH from getting stuck in the contract
        if (
            _l1Token == address(0) &&
            _l2Token == Lib_PredeployAddresses.OVM_ETH &&
            msg.value == _amount
        ) {
            // An ETH deposit is being made via the Token Bridge.
            // We simply forward it on. If this call fails, ETH will be stuck, but the L1Bridge
            // uses onlyEOA on the receive function, so anyone sending to a contract knows
            // what they are doing.
            address(_to).call{ value: _amount }(hex"");
            emit DepositFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
        } else if (
            // Check the target token is compliant and
            // verify the deposited token on L1 matches the L2 deposited token representation here
            // slither-disable-next-line reentrancy-events
            ERC165Checker.supportsInterface(_l2Token, 0x1d1d8b63) &&
            _l1Token == IL2StandardERC20(_l2Token).l1Token()
        ) {
            // When a deposit is finalized, we credit the account on L2 with the same amount of
            // tokens.
            // slither-disable-next-line reentrancy-events
            IL2StandardERC20(_l2Token).mint(_to, _amount);
            // slither-disable-next-line reentrancy-events
            emit DepositFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
        } else {
            // Either the L2 token which is being deposited-into disagrees about the correct address
            // of its L1 token, or does not support the correct interface.
            // This should only happen if there is a  malicious L2 token, or if a user somehow
            // specified the wrong L2 token address to deposit into.
            // In either case, we stop the process here and construct a withdrawal
            // message so that users can get their funds out in some cases.
            // There is no way to prevent malicious token contracts altogether, but this does limit
            // user error and mitigate some forms of malicious contract behavior.

            emit DepositFailed(_l1Token, _l2Token, _from, _to, _amount, _data);

            // Withdraw ETH in the case that the user submitted a bad ETH
            // deposit to prevent ETH from getting stuck
            if (_l1Token == address(0) && _l2Token == Lib_PredeployAddresses.OVM_ETH) {
                CrossDomainMessenger(Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER).sendMessage{
                    value: msg.value
                }(
                    l1TokenBridge,
                    abi.encodeWithSelector(
                        IL1StandardBridge.finalizeETHWithdrawal.selector,
                        _to, // switch the _to and _from to send deposit back to the sender
                        _from,
                        msg.value,
                        _data
                    ),
                    0 // TODO: does a 0 gaslimit work here?
                );
            } else {
                CrossDomainMessenger(Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER).sendMessage(
                    l1TokenBridge,
                    abi.encodeWithSelector(
                        IL1ERC20Bridge.finalizeERC20Withdrawal.selector,
                        _l1Token,
                        _l2Token,
                        _to, // switch the _to and _from to send deposit back to the sender
                        _from,
                        _amount,
                        _data
                    ),
                    0 // TODO: does a 0 gaslimit work here?
                );
            }
        }
    }
}