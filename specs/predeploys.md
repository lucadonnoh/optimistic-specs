# Predeploys

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Overview](#overview)
- [OVM\_L2ToL1MessagePasser](#ovm%5C_l2tol1messagepasser)
- [OVM\_L1MessageSender](#ovm%5C_l1messagesender)
- [OVM\_DeployerWhitelist](#ovm%5C_deployerwhitelist)
- [OVM\_ETH](#ovm%5C_eth)
- [L2CrossDomainMessenger](#l2crossdomainmessenger)
- [Lib\_AddressManager](#lib%5C_addressmanager)
- [ProxyEOA](#proxyeoa)
- [L2StandardBridge](#l2standardbridge)
- [SequencerFeeVault](#sequencerfeevault)
- [L2StandardTokenFactory](#l2standardtokenfactory)
- [L1BlockNumber](#l1blocknumber)
- [OVM\_GasPriceOracle](#ovm%5C_gaspriceoracle)
- [L1Attributes](#l1attributes)
- [Withdrawer](#withdrawer)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Overview

Predeployed smart contracts exist on Optimism at predetermined addresses in
the genesis state. They are similar to precompiles but instead run directly
in the EVM instead of running native code outside of the EVM.

Predeploy addresses exist in 2 byte namespaces where the prefixes
are one of:

- `0x420000000000000000000000000000000000xxxx`
- `0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeADxxxx`

The following table includes each of the predeploys. The system version
indicates when the predeploy was introduced. The possible values are `Legacy`
or `Bedrock`.

| Name                         | Address                                    | System Version |
| ---------------------------- | ------------------------------------------ | -------------- |
| OVM\_L2ToL1MessagePasser     | 0x4200000000000000000000000000000000000000 | Legacy         |
| OVM\_L1MessageSender         | 0x4200000000000000000000000000000000000001 | Legacy         |
| OVM\_DeployerWhitelist       | 0x4200000000000000000000000000000000000002 | Legacy         |
| OVM\_ETH                     | 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000 | Legacy         |
| L2CrossDomainMessenger       | 0x4200000000000000000000000000000000000007 | Legacy         |
| LibAddressManager            | 0x4200000000000000000000000000000000000008 | Legacy         |
| ProxyEOA                     | 0x4200000000000000000000000000000000000009 | Legacy         |
| L2StandardBridge             | 0x4200000000000000000000000000000000000010 | Legacy         |
| SequencerFeeVault            | 0x4200000000000000000000000000000000000011 | Legacy         |
| L2StandardTokenFactory       | 0x4200000000000000000000000000000000000012 | Legacy         |
| L1BlockNumber                | 0x4200000000000000000000000000000000000013 | Legacy         |
| GasPriceOracle               | 0x420000000000000000000000000000000000000F | Legacy         |
| L1Attributes                 | 0x4200000000000000000000000000000000000015 | Bedrock        |
| Withdrawer                   | 0x4200000000000000000000000000000000000016 | Bedrock        |

## OVM\_L2ToL1MessagePasser

The `OVM_L2ToL1MessagePasser` is part of the legacy bridge. It is being
deprecated as part of the bedrock upgrade.

```solidity
/**
 * @title OVM_L2ToL1MessagePasser
 * @dev The L2 to L1 Message Passer is a utility contract which facilitate an L1 proof of the
 * of a message on L2. The L1 Cross Domain Messenger performs this proof in its
 * _verifyStorageProof function, which verifies the existence of the transaction hash in this
 * contract's `sentMessages` mapping.
 */
interface iOVM_L2ToL1MessagePasser {
    event L2ToL1Message(uint256 _nonce, address _sender, bytes _data);

    /**
     * Returns a bool if the message has been passed to L1
     * @param _msgHash Message hash
     */
    function sentMessages(bytes32 _msgHash) public returns (bool);

    /**
     * Passes a message to L1.
     * @param _message Message to pass to L1.
     */
    function passMessageToL1(bytes calldata _message) external;
}
```

## OVM\_L1MessageSender

The `OVM_L1MessageSender` is a legacy contract. `ORIGIN` and `CALLER` return
the aliased L1 message sender, for L1 to L2 cross domain transactions,
so calling this contract is a far more expensive way to get these values.

```solidity
/**
 * @title OVM_L1MessageSender returns the address of the L1 Message sender.
   During the execution of a cross-domain transaction, the L1 account (either an
   EOA or contract) that send the message to L2 via
   OVM_CanonicalTransactionChain.enqueue
 */
interface iOVM_L1MessageSender {
    function getL1MessageSender() external view returns (address _l1MessageSender);
}
```

## OVM\_DeployerWhitelist

The `OVM_DeployerWhitelist` had arbitrary contract deployment enabled. In the
legacy system, this contract was hooked into during `CREATE` and `CREATE2` to
ensure that the deployer was allowlisted. In the bedrock system, this will
be removed from the `CREATE` codepath since arbitrary contract deployment
has already been enabled.

```solidity
/**
 * @title OVM_DeployerWhitelist
 * @dev The Deployer Whitelist is a temporary predeploy used to provide additional safety during the
 * initial phases of our mainnet roll out. It is owned by the Optimism team, and defines accounts
 * which are allowed to deploy contracts on Layer2. The Execution Manager will only allow an
 * ovmCREATE or ovmCREATE2 operation to proceed if the deployer's address whitelisted.
 */
interface iOVM_DeployerWhitelist {
    event OwnerChanged(address,address);
    event WhitelistStatusChanged(address,bool);
    event WhitelistDisabled(address);

    /**
     * @dev Returns the owner of the contract
     */
    function owner() public return (address);
    /**
     * @dev Query if an address is in the allowlist
     */
    function whitelist(address) public returns (bool);

    /**
     * @dev Adds or removes an address from the deployment whitelist.
     * @param _deployer Address to update permissions for.
     * @param _isWhitelisted Whether or not the address is whitelisted.
     */
    function setWhitelistedDeployer(address _deployer, bool _isWhitelisted) external;

    /**
     * @dev Updates the owner of this contract.
     * @param _owner Address of the new owner.
     */
    function setOwner(address _owner) public;

    /**
     * @dev Permanently enables arbitrary contract deployment and deletes the owner.
     */
    function enableArbitraryContractDeployment() external;

    /**
     * @dev Checks whether an address is allowed to deploy contracts.
     * @param _deployer Address to check.
     * @return _allowed Whether or not the address can deploy contracts.
     */
    function isDeployerAllowed(address _deployer) external view returns (bool);
}
```

## OVM\_ETH

The `OVM_ETH` contains the ERC20 represented balances of ETH that has been
deposited to L2. As part of the bedrock upgrade, the balances will be migrated
from this contract to the actual Ethereum level accounts to preserve EVM
equivalence.

```solidity
interface IL2StandardERC20 {
    event Mint(address indexed _account, uint256 _amount);
    event Burn(address indexed _account, uint256 _amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function l1Token() external returns (address);
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
```

## L2CrossDomainMessenger

The `L2CrossDomainMessenger` is part of the legacy bridge system.

```solidity
/**
 * @title L2CrossDomainMessenger
 * @dev The L2 Cross Domain Messenger contract sends messages from L2 to L1, and is the entry point
 * for L2 messages sent via the L1 Cross Domain Messenger.
 *
 */
interface IL2CrossDomainMessenger is ICrossDomainMessenger {
    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /**
     * @dev Mapping of message hashes to whether or not the
     * message has been relayed to L2, successful or not
     */
    function relayedMessages(bytes32) public returns (bool);

    /**
     * @dev Mapping of message hashes to successful L2 relays
     */
    function successfulMessages(bytes32) public returns (bool);

    /**
     * @dev Mapping of messages that were sent to L1
     */
    function sentMessages(bytes32) public returns (bool);

    /**
     * @dev The current L1 to L2 message nonce
     */
    function messageNonce() public returns (uint256);

    /**
     * @dev The address of the L1 cross domain messenger
     */
    function l1CrossDomainMessenger() public returns (address);

    /**
     * @dev Returns the L1 message sender
     */
    function xDomainMessageSender() public view returns (address);

    /**
     * @dev Relays a cross domain message to a contract.
     * @param _target Target contract address.
     * @param _sender Message sender address.
     * @param _message Message to send to the target.
     * @param _messageNonce Nonce for the provided message.
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce
    ) external;

    /**
     * @dev Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}
```

## Lib\_AddressManager

The `Lib_AddressManager` is an ownable key/value store meant to hold the names
of important contracts in the system. It allows for contracts to be upgraded
by setting the name of the contract to a new value. Any offchain services must
be aware of this functionality and must be able to dynamically update the
contract addresses that they are interacting with for this upgrade strategy to
be able to work.

```solidity
interface Lib_AddressManager {
    event AddressSet(string indexed _name, address _newAddress, address _oldAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view returns (address);
    function renounceOwnership() public;
    function transferOwnership(address newOwner) public;

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(string memory _name, address _address) external;

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(string memory _name) external view returns (address);
}
```

## ProxyEOA

The `ProxyEOA` is deprecated and part of the legacy account abstraction
implementation. This functionality was deprecated as to enable EVM equivalence.

```solidity

interface OVM_ProxyEOA {
    event Upgraded(address indexed implementation);

    /**
     * Changes the implementation address.
     * @param _implementation New implementation address.
     */
    function upgrade(address _implementation) external;

    /**
     * Gets the address of the current implementation.
     * @return Current implementation address.
     */
    function getImplementation() public returns (address);
}
```

## L2StandardBridge

The `L2StandardBridge` is part of the bridge system.

```solidity

interface L2StandardBridge {
    event WithdrawalInitiated(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event DepositFinalized(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event DepositFailed(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    /**
     * @dev get the address of the messenger contract used to send
     * and receive messages from the other domain
     */
    function messenger() external returns (address);

    /**
     * @dev get the address of the corresponding L1 bridge contract.
     * @return Address of the corresponding L1 bridge contract.
     */
    function l1TokenBridge() external returns (address);

    /**
     * @dev initiate a withdraw of some tokens to the caller's account on L1
     * @param _l2Token Address of L2 token where withdrawal was initiated.
     * @param _amount Amount of the token to withdraw.
     * param _l1Gas Unused, but included for potential forward compatibility considerations.
     * @param _data Optional data to forward to L1. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function withdraw(
        address _l2Token,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) external;

    /**
     * @dev initiate a withdraw of some token to a recipient's account on L1.
     * @param _l2Token Address of L2 token where withdrawal is initiated.
     * @param _to L1 adress to credit the withdrawal to.
     * @param _amount Amount of the token to withdraw.
     * param _l1Gas Unused, but included for potential forward compatibility considerations.
     * @param _data Optional data to forward to L1. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function withdrawTo(
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) external;

    /**
     * @dev Complete a deposit from L1 to L2, and credits funds to the recipient's balance of this
     * L2 token. This call will fail if it did not originate from a corresponding deposit in
     * L1StandardTokenBridge.
     * @param _l1Token Address for the l1 token this is called with
     * @param _l2Token Address for the l2 token this is called with
     * @param _from Account to pull the deposit from on L2.
     * @param _to Address to receive the withdrawal at
     * @param _amount Amount of the token to withdraw
     * @param _data Data provider by the sender on L1. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function finalizeDeposit(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external;
}
```

## SequencerFeeVault

Transaction fees accumulate in this predeploy and can be withdrawn by anybody
but only to the set `l1FeeWallet`.

```solidity
interface SequencerFeeVault {
    /**
     * @dev The minimal withdrawal amount in wei for a single withdrawal
     */
    function MIN_WITHDRAWAL_AMOUNT() public returns (uint256);

    /**
     * @dev The address on L1 that fees are withdrawn to
     */
    function l1FeeWallet() public returns (address);

    /**
     * @dev Call this to withdraw the ether held in this
     * account to the L1 fee wallet on L1.
     */
    function withdraw() public;
}
```

## L2StandardTokenFactory

The `L2StandardTokenFactory` is part of the bridge system.

```solidity
interface L2StandardTokenFactory {
    event StandardL2TokenCreated(address indexed _l1Token, address indexed _l2Token);

    /**
     * @dev Creates an instance of the standard ERC20 token on L2.
     * @param _l1Token Address of the corresponding L1 token.
     * @param _name ERC20 name.
     * @param _symbol ERC20 symbol.
     */
    function createStandardL2Token(address _l1Token, string memory _name, string memory _symbol) external;
}
```

## L1BlockNumber

The `L1BlockNumber` returns the last known L1 block number. This contract was
introduced in the legacy system and should be backwards compatible by calling
out to the `L1Attributes` contract under the hood.

```solidity
interface iOVM_L1BlockNumber {
    /**
     * @dev Returns the most recent L1 blocknumber as known by the L2 system.
     */
    function getL1BlockNumber() external view returns (uint256);
}
```

## OVM\_GasPriceOracle

The `OVM_GasPriceOracle` is pushed the L1 basefee and the L2 gas price by
an offchain actor. The offchain actor observes the L1 blockheaders to get the
L1 basefee as well as the gas usage on L2 to compute what the L2 gas price
should be based on a congenstion control algorithm.

It is being deprecated in bedrock but its API should still function as to
enable backwards compatibility.

```solidity
contract OVM_GasPriceOracle {
    /**
     * @dev Returns the current gas price on L2
     */
    function gasPrice() public returns (uint256);

    /**
     * @dev Returns the latest known L1 basefee
     */
    function l1BaseFee() public returns (uint256);

    /**
     * @dev Returns the amortized cost of 
     * batch submission per transaction
     */
    function overhead() public returns (uint256);

    /**
     * @dev Returns the value to scale the fee up by
     */
    function scalar() public returns (uint256);

    /**
     * @dev The number of decimals of the scalar
     */
    function decimals() public returns (uint256);

    event GasPriceUpdated(uint256);
    event L1BaseFeeUpdated(uint256);
    event OverheadUpdated(uint256);
    event ScalarUpdated(uint256);
    event DecimalsUpdated(uint256);

    /**
     * Allows the owner to modify the l2 gas price.
     * @param _gasPrice New l2 gas price.
     */
    function setGasPrice(uint256 _gasPrice) public;

    /**
     * Allows the owner to modify the l1 base fee.
     * @param _baseFee New l1 base fee
     */
    function setL1BaseFee(uint256 _baseFee) public;

    /**
     * Allows the owner to modify the overhead.
     * @param _overhead New overhead
     */
    function setOverhead(uint256 _overhead) public;

    /**
     * Allows the owner to modify the scalar.
     * @param _scalar New scalar
     */
    function setScalar(uint256 _scalar) public;

    /**
     * Allows the owner to modify the decimals.
     * @param _decimals New decimals
     */
    function setDecimals(uint256 _decimals) public;

    /**
     * Computes the L1 portion of the fee
     * based on the size of the RLP encoded tx
     * and the current l1BaseFee
     * @param _data Unsigned RLP encoded tx, 6 elements
     * @return L1 fee that should be paid for the tx
     */
    // slither-disable-next-line external-function
    function getL1Fee(bytes memory _data) public view returns (uint256);

    /**
     * Computes the amount of L1 gas used for a transaction
     * The overhead represents the per batch gas overhead of
     * posting both transaction and state roots to L1 given larger
     * batch sizes.
     * 4 gas for 0 byte
     * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L33
     * 16 gas for non zero byte
     * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L87
     * This will need to be updated if calldata gas prices change
     * Account for the transaction being unsigned
     * Padding is added to account for lack of signature on transaction
     * 1 byte for RLP V prefix
     * 1 byte for V
     * 1 byte for RLP R prefix
     * 32 bytes for R
     * 1 byte for RLP S prefix
     * 32 bytes for S
     * Total: 68 bytes of padding
     * @param _data Unsigned RLP encoded tx, 6 elements
     * @return Amount of L1 gas used for a transaction
     */
    function getL1GasUsed(bytes memory _data) public view returns (uint256);
}
```

## L1Attributes

This contract was introduced in bedrock and is responsible for
mainting L1 context in L2. This allows for L1 state to be accessed in L2.

```solidity
interface L1Attributes {
    /**
     * @dev Returns the special account that can only send
     * transactions to this contract
     */
    function DEPOSITOR_ACCOUNT() public returns (address);

    /**
     * @dev Returns the latest known L1 block number
     */
    function number() public returns (uint256);

    /**
     * @dev Returns the latest known L1 timestamp
     */
    function timestamp() public returns (uint256);

    /**
     * @dev Returns the latest known L1 basefee
     */
    function basefee() public returns (uint256);

    /**
     * @dev Returns the latest known L1 transaction hash
     */
    function hash() public returns (bytes32);

    /**
     * @dev sets the latest L1 block attributes
     */
    function setL1BlockValues(
        uint256 _number,
        uint256 _timestamp,
        uint256 _basefee,
        bytes32 _hash
    ) external;
}

```

## Withdrawer

The `Withdrawer` is responsible for handling L2 to L1 interactions.

```solidity
/**
 * @title Withdrawer
 * @notice The Withdrawer contract facilitates sending both ETH value and data from L2 to L1.
 * It is predeployed in the L2 state at address 0x4200000000000000000000000000000000000016.
 */
contract Withdrawer {
    /**
     * @notice Emitted any time a withdrawal is initiated.
     * @param nonce Unique value corresponding to each withdrawal.
     * @param sender The L2 account address which initiated the withdrawal.
     * @param target The L1 account address the call will be send to.
     * @param value The ETH value submitted for withdrawal, to be forwarded to the target.
     * @param gasLimit The minimum amount of gas that must be provided when withdrawing on L1.
     * @param data The data to be forwarded to the target on L1.
     */
    event WithdrawalInitiated(
        uint256 indexed nonce,
        address indexed sender,
        address indexed target,
        uint256 value,
        uint256 gasLimit,
        bytes data
    );

    /// @notice Emitted when the balance of this contract is burned.
    event WithdrawerBalanceBurnt(uint256 indexed amount);

    /// @notice A unique value hashed with each withdrawal.
    function nonce() public returns (uint256);

    /// @notice A mapping listing withdrawals which have been initiated herein.
    function withdrawals(bytes32) public returns (bool);

    /**
     * @notice Initiates a withdrawal to execute on L1.
     * @param _target Address to call on L1 execution.
     * @param _gasLimit GasLimit to provide on L1.
     * @param _data Data to forward to L1 target.
     */
    function initiateWithdrawal(
        address _target,
        uint256 _gasLimit,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Removes all ETH held in this contract from the state, by deploying a contract which
     * immediately self destructs.
     */
    function burn() external;
}
```
