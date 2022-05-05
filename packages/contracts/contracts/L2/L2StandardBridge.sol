// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {
    Lib_PredeployAddresses
} from "@eth-optimism/contracts/libraries/constants/Lib_PredeployAddresses.sol";
import { AddressAliasHelper } from "@eth-optimism/contracts/standards/AddressAliasHelper.sol";

/* Contract Imports */
import { CrossDomainMessenger } from "../universal/CrossDomainMessenger.sol";
import { StandardBridge } from "../universal/StandardBridge.sol";
import { IL2StandardERC20 } from "../interfaces/IL2StandardERC20.sol";

contract L2StandardBridge is StandardBridge {
    /**********
     * Events *
     **********/

    event WithdrawalInitiated(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    /********************
     * Public Functions *
     ********************/

    function withdraw(
        address _l2Token,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _data
    ) external payable virtual {
        _initiateWithdrawal(_l2Token, msg.sender, msg.sender, _amount, _minGasLimit, _data);
    }

    function withdrawTo(
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _data
    ) external payable virtual {
        _initiateWithdrawal(_l2Token, msg.sender, _to, _amount, _minGasLimit, _data);
    }

    /**********************
     * Internal Functions *
     **********************/

    function _initiateWithdrawal(
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _data
    ) internal {
        address l1Token = IL2StandardERC20(_l2Token).l1Token();
        emit WithdrawalInitiated(l1Token, _l2Token, msg.sender, _to, _amount, _data);
        if (_l2Token == Lib_PredeployAddresses.OVM_ETH) {
            _initiateBridgeETH(_from, _to, _amount, _minGasLimit, _data);
        } else {
            _initiateBridgeERC20(_l2Token, l1Token, _from, _to, _amount, _minGasLimit, _data);
        }
    }
}
