// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {StudentBadge} from "../src/nft/StudentBadge.sol";

contract StudentBadgeTest is Test {
    StudentBadge public studentBadge;
    address public constant USER = address(1);
    address public constant USER_2 = address(2);

    function setUp() public {
        studentBadge = new StudentBadge();
    }

    function test_Mint_SuccessfullyMintsAndIncrementsId() public {
        // Mint do primeiro token (ID 0) para o USER
        vm.prank(USER);
        studentBadge.mint();
        assertEq(studentBadge.ownerOf(0), USER);

        // Mint do segundo token (ID 1) para o USER_2 para testar o incremento
        vm.prank(USER_2);
        studentBadge.mint();
        assertEq(studentBadge.ownerOf(1), USER_2);
    }

    // ==============================================================
    // Fuzz Tests
    // ==============================================================

    function testFuzz_Mint_ByMultipleUsers(address user1, address user2) public {
        // ARRANGE: Garantir que os usuários são EOAs (contas de carteira),
        // não são o endereço zero e são diferentes entre si.
        vm.assume(
            user1.code.length == 0 && user2.code.length == 0 && user1 != address(0) && user2 != address(0)
                && user1 != user2
        );

        // ACT & ASSERT
        vm.prank(user1);
        studentBadge.mint(); // Minta o token 0
        assertEq(studentBadge.ownerOf(0), user1);

        vm.prank(user2);
        studentBadge.mint(); // Minta o token 1
        assertEq(studentBadge.ownerOf(1), user2);
    }
}
