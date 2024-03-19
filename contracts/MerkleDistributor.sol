// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleDistributor {
    using SafeERC20 for IERC20;
    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public dropAmount;

    mapping(address => uint) private addressesClaimed;
    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    event Claimed(address indexed _from, uint256 _dropAmount);
    constructor(address token_, bytes32 merkleRoot_, uint256 dropAmount_) {
        token = token_;
        merkleRoot = merkleRoot_;
        dropAmount = dropAmount_;
    }
    function claim(bytes32[] calldata merkleProof) external {
        require(
            addressesClaimed[msg.sender] == 0,
            "MerkleDistributor: Drop already claimed"
        );
        // Verify merkle proof
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof"
        );
        // Generate random drop amount
        uint256 randomSeed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );
        // Add 1 to avoid getting zero
        uint256 randomAmount = (randomSeed % dropAmount) + 1;
        // Mark it claimed
        addressesClaimed[msg.sender] = 1;
        // Send the token
        IERC20(token).safeTransfer(msg.sender, randomAmount);
        emit Claimed(msg.sender, randomAmount);
    }
}
