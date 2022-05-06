// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IL2StandardERC20.sol";

contract OptimismMintableERC20 is IL2StandardERC20, ERC20 {
    address public remoteToken;
    address public bridge;

    /**
     * @param _bridge Address of the L2 standard bridge.
     * @param _remoteToken Address of the corresponding L1 token.
     * @param _name ERC20 name.
     * @param _symbol ERC20 symbol.
     */
    constructor(
        address _bridge,
        address _remoteToken,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        remoteToken = _remoteToken;
        bridge = _bridge;
    }

    function l1Token() public view returns (address) {
        return remoteToken;
    }

    function l2Bridge() public view returns (address) {
        return bridge;
    }

    modifier onlyBridge() {
        require(msg.sender == bridge, "Only L2 Bridge can mint and burn");
        _;
    }

    // slither-disable-next-line external-function
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        bytes4 iface1 = bytes4(keccak256("supportsInterface(bytes4)")); // ERC165

        bytes4 iface2 = this.l1Token.selector ^
            this.mint.selector ^
            this.burn.selector;

        // this value here
        bytes4 iface3 = this.remoteToken.selector ^
            this.mint.selector ^
            this.burn.selector;

        return _interfaceId == iface1 || _interfaceId == iface3 || _interfaceId == iface2;
    }

    // slither-disable-next-line external-function
    function mint(address _to, uint256 _amount) public virtual onlyBridge {
        _mint(_to, _amount);

        emit Mint(_to, _amount);
    }

    // slither-disable-next-line external-function
    function burn(address _from, uint256 _amount) public virtual onlyBridge {
        _burn(_from, _amount);

        emit Burn(_from, _amount);
    }
}
