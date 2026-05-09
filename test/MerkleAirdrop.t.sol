//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {PrdxToken} from "../src/PrdxToken.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    PrdxToken public token;

    bytes32 public merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    uint256 userPrivateKey;

    function setUp() public {
        token = new PrdxToken();
        airdrop = new MerkleAirdrop(merkleRoot, token);
        (user, userPrivateKey) = makeAddrAndKey("user");
    }

    function testUsersCanClaim() public {
        console.log("User address: ", user);
    }
}
