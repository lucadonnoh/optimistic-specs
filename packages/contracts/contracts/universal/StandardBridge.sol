// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Interface Imports */
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Library Imports */
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {
    Lib_PredeployAddresses
} from "@eth-optimism/contracts/libraries/constants/Lib_PredeployAddresses.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { CrossDomainMessenger } from "./CrossDomainMessenger.sol";
import { OptimismMintableERC20 } from "./OptimismMintableERC20.sol";

abstract contract StandardBridge {
    using SafeERC20 for IERC20;

    /**********
     * Events *
     **********/

    event ETHBridgeInitiated(
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        bytes _data
    );

    event ETHBridgeFinalized(
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        bytes _data
    );

    event ERC20BridgeInitiated(
        address indexed _localToken,
        address indexed _remoteToken,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event ERC20BridgeFinalized(
        address indexed _localToken,
        address indexed _remoteToken,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    /*************
     * Variables *
     *************/

    CrossDomainMessenger public messenger;
    StandardBridge public otherBridge;

    mapping(address => mapping(address => uint256)) public deposits;

    /*************
     * Modifiers *
     *************/

    modifier onlyEOA() {
        require(!Address.isContract(msg.sender), "Account not EOA");
        _;
    }

    /**
     * @notice Ensures that the caller is the portal, and that it has the l2Sender value
     * set to the address of the L2 Token Bridge.
     */
    modifier onlyOtherBridge() {
        require(
            msg.sender == address(messenger) && messenger.xDomainMessageSender() == address(otherBridge),
            "Could not authenticate bridge message."
        );
        _;
    }

    /********************
     * Public Functions *
     ********************/

    function donateETH() external payable {}

    receive() external payable onlyEOA {
        _initiateBridgeETH(msg.sender, msg.sender, msg.value, 200_000, bytes(""));
    }

    function bridgeETH(uint32 _minGasLimit, bytes calldata _data) public payable onlyEOA {
        _initiateBridgeETH(msg.sender, msg.sender, msg.value, _minGasLimit, _data);
    }

    function bridgeETHTo(
        address _to,
        uint32 _minGasLimit,
        bytes calldata _data
    ) public payable {
        _initiateBridgeETH(msg.sender, _to, msg.value, _minGasLimit, _data);
    }

    function bridgeERC20(
        address _localToken,
        address _remoteToken,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _data
    ) public virtual onlyEOA {
        _initiateBridgeERC20(_localToken, _remoteToken, msg.sender, msg.sender, _amount, _minGasLimit, _data);
    }

    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _data
    ) public virtual {
        _initiateBridgeERC20(_localToken, _remoteToken, msg.sender, _to, _amount, _minGasLimit, _data);
    }

    function finalizeBridgeETH(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) public payable onlyOtherBridge {
        require(
            msg.value == _amount,
            "Amount sent does not match amount required."
        );

        emit ETHBridgeFinalized(_from, _to, _amount, _data);
        (bool success, ) = _to.call{ value: _amount }(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }

    function finalizeBridgeERC20(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) public onlyOtherBridge {
        if (_isOptimismMintable(_localToken, _remoteToken)) {
            OptimismMintableERC20(_localToken).mint(_to, _amount);
        } else {
            deposits[_localToken][_remoteToken] = deposits[_localToken][_remoteToken] - _amount;
            IERC20(_localToken).safeTransfer(_to, _amount);
        }

        emit ERC20BridgeFinalized(_localToken, _remoteToken, _from, _to, _amount, _data);
    }

    /**********************
     * Internal Functions *
     **********************/

    function _initialize(
        CrossDomainMessenger _messenger,
        StandardBridge _otherBridge
    )
        internal
    {
        // TODO: Figure out if we want this behind a proxy with Initializable.
        require(
            address(_messenger) == address(0),
            "Contract has already been initialized."
        );

        messenger = _messenger;
        otherBridge = _otherBridge;
    }

    function _initiateBridgeETH(
        address _from,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes memory _data
    ) internal {
        emit ETHBridgeInitiated(_from, _to, _amount, _data);

        messenger.sendMessage{ value: _amount }(
            address(otherBridge),
            abi.encodeWithSelector(
                this.finalizeBridgeETH.selector,
                _from,
                _to,
                _amount,
                _data
            ),
            _minGasLimit
        );
    }

    function _initiateBridgeERC20(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _data
    ) internal {
        if (_isOptimismMintable(_localToken, _remoteToken)) {
            OptimismMintableERC20(_localToken).burn(msg.sender, _amount);
        } else {
            IERC20(_localToken).safeTransferFrom(_from, address(this), _amount);
            deposits[_localToken][_remoteToken] = deposits[_localToken][_remoteToken] + _amount;
        }

        messenger.sendMessage(
            address(otherBridge),
            abi.encodeWithSelector(
                this.finalizeBridgeERC20.selector,
                _remoteToken,
                _localToken,
                _from,
                _to,
                _amount,
                _data
            ),
            _minGasLimit
        );

        emit ERC20BridgeInitiated(_localToken, _remoteToken, _from, _to, _amount, _data);
    }

    function _isOptimismMintable(
        address _localToken,
        address _remoteToken
    )
        internal
        view
        returns (bool)
    {
        return (
            (ERC165Checker.supportsInterface(_localToken, 0x1d1d8b63) && _remoteToken == OptimismMintableERC20(_localToken).l1Token()) ||
            (ERC165Checker.supportsInterface(_localToken, 0xFFFFFFFF) && _remoteToken == OptimismMintableERC20(_localToken).l2Token())
        );
    }
}
