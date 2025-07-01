// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ^0.8.21;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// src/offChainSignatureAggregator.sol

interface IERC20Mintable {
    function mint(address,uint256) external;
}

contract offChainSignatureAggregator is Ownable() {
    uint256 constant internal maxNumSigner = 8;
    bytes32 public constant REPORT_HASH = keccak256("Report(address receiver,uint256 amount,uint256 nonce)");
    bytes32 public immutable DOMAIN_SEPARATOR;
    address public immutable kBTC;

    uint256 public threshold = 1;
    uint256 public nonce;
    mapping(address => bool) public signers;

    event SignerUpdated(address signer, bool right);

    struct Report {
        address receiver;
        uint256 amount;
        uint256 nonce;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    constructor(address _kBTC) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("OffChainSignatureAggregator")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        kBTC = _kBTC;
        address[] memory signer = new address[](1);
        bool[] memory valid = new bool[](1);
        signer[0] = msg.sender;
        valid[0] = true;
        setSigners(signer, valid);
    }

    function mintBTC(Report calldata r,  Signature[] memory _rs) external {
        _verifySignature(r, _rs);

        IERC20Mintable(kBTC).mint(r.receiver, r.amount);
    }

    function _verifySignature(Report calldata _report, Signature[] memory _rs) internal {
        require(_rs.length >= threshold, "not enough signatures");
        require(_rs.length <= maxNumSigner, "too many signatures");
        require(_report.nonce == nonce + 1, "require sequential execution");
        bytes32 reportHash = reportDigest(_report);
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, reportHash));
        bytes32 r;

        for (uint i = 0; i < _rs.length; i++) {
            Signature memory s = _rs[i];
            address signer = ecrecover(digest, s.v, s.r, s.s);
            require(signers[signer], "unauthorized");
            // signature duplication check using bytes32 r, sufficient when sorted in ascending order.
            require(uint256(s.r) >= uint256(r), "not sorted r");
            require(s.r != r, "non-unique signature");
            r = s.r;
      }
      nonce += 1;
    }
    // what the reporter has to sign off-chain
    function reportDigest(Report memory report) pure public returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    REPORT_HASH,
                    report.receiver,
                    report.amount,
                    report.nonce
                )
            );
    }

    function updateThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold <= maxNumSigner, "max number of signer breached");
        threshold = _newThreshold;
    }

    function setSigners(address[] memory _signers, bool[] memory _rights) public onlyOwner {
        for (uint i = 0; i < _signers.length; i++) {
            signers[_signers[i]] = _rights[i];
            emit SignerUpdated(_signers[i], _rights[i]);
       }
    }
}
