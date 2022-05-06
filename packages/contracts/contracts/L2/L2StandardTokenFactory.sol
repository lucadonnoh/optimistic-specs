// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Contract Imports */
import { OptimismMintableERC20 } from "../universal/OptimismMintableERC20.sol";
import {
    Lib_PredeployAddresses
} from "@eth-optimism/contracts/libraries/constants/Lib_PredeployAddresses.sol";

/**
 * @title L2StandardTokenFactory
 * @dev Factory contract for creating standard L2 token representations of L1 ERC20s
 * compatible with and working on the standard bridge.
 */
contract L2StandardTokenFactory {
    event StandardL2TokenCreated(address indexed _l1Token, address indexed _l2Token);

    address bridge;

    // On L2 _bridge should be Lib_PredeployAddresses.L2_STANDARD_BRIDGE,
    // On L1 _bridge should be the L1StandardBridge
    constructor(address _bridge) {
        bridge = _bridge;
    }

    /**
     * @dev Creates an instance of the standard ERC20 token on L2.
     * @param _l1Token Address of the corresponding L1 token.
     * @param _name ERC20 name.
     * @param _symbol ERC20 symbol.
     */
    function createStandardL2Token(
        address _l1Token,
        string memory _name,
        string memory _symbol
    ) external {
        require(_l1Token != address(0), "Must provide L1 token address");

        OptimismMintableERC20 l2Token = new OptimismMintableERC20(
            bridge,
            _l1Token,
            _name,
            _symbol
        );

        emit StandardL2TokenCreated(_l1Token, address(l2Token));
    }
}
