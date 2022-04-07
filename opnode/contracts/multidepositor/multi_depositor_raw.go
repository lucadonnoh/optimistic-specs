// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package multidepositor

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
)

// MultidepositorMetaData contains all meta data concerning the Multidepositor contract.
var MultidepositorMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[],\"name\":\"deposit\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"}]",
	Bin: "0x608060405273deaddeaddeaddeaddeaddeaddeaddeaddead00016000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555034801561006457600080fd5b5061031d806100746000396000f3fe60806040526004361061001e5760003560e01c8063d0e30db014610023575b600080fd5b61002b61002d565b005b60005b60038110156100f75760008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663fa92670c7377700000000000000000000000000000000000006103e8622dc6c060006040518563ffffffff1660e01b81526004016100b29493929190610217565b600060405180830381600087803b1580156100cc57600080fd5b505af11580156100e0573d6000803e3d6000fd5b5050505080806100ef9061029e565b915050610030565b50565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610125826100fa565b9050919050565b6101358161011a565b82525050565b6000819050919050565b6000819050919050565b6000819050919050565b600061017461016f61016a8461013b565b61014f565b610145565b9050919050565b61018481610159565b82525050565b6000819050919050565b60006101af6101aa6101a58461018a565b61014f565b610145565b9050919050565b6101bf81610194565b82525050565b60008115159050919050565b6101da816101c5565b82525050565b600082825260208201905092915050565b50565b60006102016000836101e0565b915061020c826101f1565b600082019050919050565b600060a08201905061022c600083018761012c565b610239602083018661017b565b61024660408301856101b6565b61025360608301846101d1565b8181036080830152610264816101f4565b905095945050505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60006102a982610145565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8214156102dc576102db61026f565b5b60018201905091905056fea2646970667358221220fc936fa3dd4e944ce997f025a7a6ab95f222df877d23d518dcf62cbad3b111e464736f6c634300080a0033",
}

// MultidepositorABI is the input ABI used to generate the binding from.
// Deprecated: Use MultidepositorMetaData.ABI instead.
var MultidepositorABI = MultidepositorMetaData.ABI

// MultidepositorBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use MultidepositorMetaData.Bin instead.
var MultidepositorBin = MultidepositorMetaData.Bin

// DeployMultidepositor deploys a new Ethereum contract, binding an instance of Multidepositor to it.
func DeployMultidepositor(auth *bind.TransactOpts, backend bind.ContractBackend) (common.Address, *types.Transaction, *Multidepositor, error) {
	parsed, err := MultidepositorMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(MultidepositorBin), backend)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &Multidepositor{MultidepositorCaller: MultidepositorCaller{contract: contract}, MultidepositorTransactor: MultidepositorTransactor{contract: contract}, MultidepositorFilterer: MultidepositorFilterer{contract: contract}}, nil
}

// Multidepositor is an auto generated Go binding around an Ethereum contract.
type Multidepositor struct {
	MultidepositorCaller     // Read-only binding to the contract
	MultidepositorTransactor // Write-only binding to the contract
	MultidepositorFilterer   // Log filterer for contract events
}

// MultidepositorCaller is an auto generated read-only Go binding around an Ethereum contract.
type MultidepositorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MultidepositorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type MultidepositorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MultidepositorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MultidepositorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MultidepositorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MultidepositorSession struct {
	Contract     *Multidepositor   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// MultidepositorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MultidepositorCallerSession struct {
	Contract *MultidepositorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// MultidepositorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MultidepositorTransactorSession struct {
	Contract     *MultidepositorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// MultidepositorRaw is an auto generated low-level Go binding around an Ethereum contract.
type MultidepositorRaw struct {
	Contract *Multidepositor // Generic contract binding to access the raw methods on
}

// MultidepositorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MultidepositorCallerRaw struct {
	Contract *MultidepositorCaller // Generic read-only contract binding to access the raw methods on
}

// MultidepositorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MultidepositorTransactorRaw struct {
	Contract *MultidepositorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewMultidepositor creates a new instance of Multidepositor, bound to a specific deployed contract.
func NewMultidepositor(address common.Address, backend bind.ContractBackend) (*Multidepositor, error) {
	contract, err := bindMultidepositor(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Multidepositor{MultidepositorCaller: MultidepositorCaller{contract: contract}, MultidepositorTransactor: MultidepositorTransactor{contract: contract}, MultidepositorFilterer: MultidepositorFilterer{contract: contract}}, nil
}

// NewMultidepositorCaller creates a new read-only instance of Multidepositor, bound to a specific deployed contract.
func NewMultidepositorCaller(address common.Address, caller bind.ContractCaller) (*MultidepositorCaller, error) {
	contract, err := bindMultidepositor(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MultidepositorCaller{contract: contract}, nil
}

// NewMultidepositorTransactor creates a new write-only instance of Multidepositor, bound to a specific deployed contract.
func NewMultidepositorTransactor(address common.Address, transactor bind.ContractTransactor) (*MultidepositorTransactor, error) {
	contract, err := bindMultidepositor(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MultidepositorTransactor{contract: contract}, nil
}

// NewMultidepositorFilterer creates a new log filterer instance of Multidepositor, bound to a specific deployed contract.
func NewMultidepositorFilterer(address common.Address, filterer bind.ContractFilterer) (*MultidepositorFilterer, error) {
	contract, err := bindMultidepositor(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MultidepositorFilterer{contract: contract}, nil
}

// bindMultidepositor binds a generic wrapper to an already deployed contract.
func bindMultidepositor(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(MultidepositorABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Multidepositor *MultidepositorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Multidepositor.Contract.MultidepositorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Multidepositor *MultidepositorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Multidepositor.Contract.MultidepositorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Multidepositor *MultidepositorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Multidepositor.Contract.MultidepositorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Multidepositor *MultidepositorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Multidepositor.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Multidepositor *MultidepositorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Multidepositor.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Multidepositor *MultidepositorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Multidepositor.Contract.contract.Transact(opts, method, params...)
}

// Deposit is a paid mutator transaction binding the contract method 0xd0e30db0.
//
// Solidity: function deposit() payable returns()
func (_Multidepositor *MultidepositorTransactor) Deposit(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Multidepositor.contract.Transact(opts, "deposit")
}

// Deposit is a paid mutator transaction binding the contract method 0xd0e30db0.
//
// Solidity: function deposit() payable returns()
func (_Multidepositor *MultidepositorSession) Deposit() (*types.Transaction, error) {
	return _Multidepositor.Contract.Deposit(&_Multidepositor.TransactOpts)
}

// Deposit is a paid mutator transaction binding the contract method 0xd0e30db0.
//
// Solidity: function deposit() payable returns()
func (_Multidepositor *MultidepositorTransactorSession) Deposit() (*types.Transaction, error) {
	return _Multidepositor.Contract.Deposit(&_Multidepositor.TransactOpts)
}
