// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EduToken} from "../src/token/EduToken.sol";

contract EduTokenTest is Test {
    EduToken public eduToken;

    address public constant OWNER = address(1);
    address public constant OTHER_USER = address(2);
    address public constant STAKING_CONTRACT = address(3);

    function setUp() public {
        vm.prank(OWNER);
        eduToken = new EduToken(OWNER);
    }

    function test_SetStakingContract_RevertsIf_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, OTHER_USER));
        vm.prank(OTHER_USER);
        eduToken.setStakingContract(STAKING_CONTRACT);
    }

    function test_SetStakingContract_RevertsIf_ZeroAddress() public {
        vm.expectRevert(EduToken.EduToken__ZeroAddress.selector);
        vm.prank(OWNER);
        eduToken.setStakingContract(address(0));
    }

    function test_Mint_RevertsIf_CallerIsNotStakingContract() public {
        vm.prank(OWNER);
        eduToken.setStakingContract(STAKING_CONTRACT);

        vm.expectRevert(EduToken.EduToken__OnlyStakingContract.selector);
        vm.prank(OTHER_USER); // Não é o contrato de staking
        eduToken.mint(OTHER_USER, 100);
    }

    function test_Mint_SuccessfullyMintsTokens() public {
        vm.prank(OWNER);
        eduToken.setStakingContract(STAKING_CONTRACT);

        vm.prank(STAKING_CONTRACT);
        eduToken.mint(OTHER_USER, 100 * 10 ** 18);

        assertEq(eduToken.balanceOf(OTHER_USER), 100 * 10 ** 18);
    }

    // ==============================================================
    // Fuzz Tests
    // ==============================================================

    function testFuzz_Mint_CorrectlyUpdatesBalanceForAnyAmount(uint96 amount) public {
        // ARRANGE
        vm.prank(OWNER);
        eduToken.setStakingContract(STAKING_CONTRACT);

        // ACT & ASSERT
        vm.prank(STAKING_CONTRACT);
        eduToken.mint(OTHER_USER, amount);
        assertEq(eduToken.balanceOf(OTHER_USER), amount);
    }
}
