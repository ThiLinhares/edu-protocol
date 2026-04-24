// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {EduStaking} from "../src/staking/EduStaking.sol";
import {StudentBadge} from "../src/nft/StudentBadge.sol";
import {EduToken} from "../src/token/EduToken.sol";
import {MockV3Aggregator} from "chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract EduStakingTest is Test {
    EduStaking public eduStaking;
    StudentBadge public studentBadge;
    EduToken public eduToken;
    MockV3Aggregator public mockPriceFeed;

    address public constant USER = address(1);
    address public constant USER_2 = address(2);
    uint256 public constant FIRST_TOKEN_ID = 0;
    uint256 public constant STAKE_DURATION = 1 days;
    int256 public constant PRICE_ABOVE_THRESHOLD = 3000 * 10 ** 8; // $3000
    int256 public constant PRICE_BELOW_THRESHOLD = 1500 * 10 ** 8; // $1500

    function setUp() public {
        // 1. Deploy das dependências
        studentBadge = new StudentBadge();
        eduToken = new EduToken(address(this)); // O contrato de teste é o owner inicial

        // 2. Deploy do Mock do Oráculo com um preço inicial de $2500
        // (8 decimais, como no Chainlink real). Preço inicial acima do limiar.
        mockPriceFeed = new MockV3Aggregator(8, PRICE_ABOVE_THRESHOLD);

        // 3. Deploy do contrato principal a ser testado
        eduStaking = new EduStaking(address(studentBadge), address(eduToken), address(mockPriceFeed));

        // 4. Configuração final: Dar permissão de mint ao contrato de staking
        eduToken.setStakingContract(address(eduStaking));
    }

    // ==============================================================
    // Testes da Função `stake`
    // ==============================================================

    function test_Stake_RevertsIf_CallerIsNotOwnerOfNFT() public {
        // ARRANGE: Mintar o NFT para o USER, mas tentar fazer stake como USER_2
        vm.prank(USER);
        studentBadge.mint();

        vm.expectRevert(EduStaking.EduStaking__NotOwnerOfNFT.selector);
        vm.prank(USER_2);
        eduStaking.stake(FIRST_TOKEN_ID);
    }

    function test_Stake_CorrectlyStakesNFT() public {
        // ARRANGE: Preparar o ambiente
        vm.startPrank(USER);
        studentBadge.mint();
        studentBadge.approve(address(eduStaking), FIRST_TOKEN_ID);
        vm.stopPrank();

        // ACT: Executar a função
        vm.expectEmit(true, true, true, true);
        emit EduStaking.Staked(USER, FIRST_TOKEN_ID);
        vm.prank(USER);
        eduStaking.stake(FIRST_TOKEN_ID);

        // ASSERT: Verificar os resultados
        address newOwner = studentBadge.ownerOf(FIRST_TOKEN_ID);
        assertEq(newOwner, address(eduStaking));

        (address stakedOwner, uint64 stakedTimestamp) = eduStaking.stakes(FIRST_TOKEN_ID);
        assertEq(stakedOwner, USER);
        assertEq(stakedTimestamp, block.timestamp);
    }

    // ==============================================================
    // Testes da Função `unstake`
    // ==============================================================

    modifier _userHasStakedNft() {
        vm.startPrank(USER);
        studentBadge.mint();
        studentBadge.approve(address(eduStaking), FIRST_TOKEN_ID);
        eduStaking.stake(FIRST_TOKEN_ID);
        vm.stopPrank();
        _;
    }

    function test_Unstake_RevertsIf_CallerIsNotOwnerOfStakedNFT() public _userHasStakedNft {
        vm.expectRevert(EduStaking.EduStaking__NotOwnerOfNFT.selector);
        vm.prank(USER_2); // Outro usuário tenta fazer unstake
        eduStaking.unstake(FIRST_TOKEN_ID);
    }

    function test_Unstake_CorrectlyTransfersNFTAndRewards() public _userHasStakedNft {
        // ARRANGE: Simular a passagem do tempo
        vm.warp(block.timestamp + STAKE_DURATION);

        uint256 expectedReward = eduStaking.calculateReward(FIRST_TOKEN_ID);
        assertTrue(expectedReward > 0);

        // ACT: Fazer o unstake
        vm.expectEmit(true, true, true, true);
        emit EduStaking.Unstaked(USER, FIRST_TOKEN_ID, expectedReward);
        vm.prank(USER);
        eduStaking.unstake(FIRST_TOKEN_ID);

        // ASSERT:
        // 1. O NFT foi devolvido ao usuário
        assertEq(studentBadge.ownerOf(FIRST_TOKEN_ID), USER);
        // 2. O usuário recebeu as recompensas
        assertEq(eduToken.balanceOf(USER), expectedReward);
        // 3. As informações do stake foram removidas
        (address stakedOwner,) = eduStaking.stakes(FIRST_TOKEN_ID);
        assertEq(stakedOwner, address(0));
    }

    function test_Unstake_ImmediatelyAfterStake_YieldsZeroReward() public _userHasStakedNft {
        // ARRANGE: Nenhum tempo passa.

        // ACT
        vm.prank(USER);
        eduStaking.unstake(FIRST_TOKEN_ID);

        // ASSERT
        assertEq(eduToken.balanceOf(USER), 0);
    }

    function test_Staking_WithMultipleUsers_IsIsolated() public {
        // Este teste será implementado em uma etapa futura para cobrir interações de múltiplos usuários.
        // Por enquanto, ele serve como um lembrete da necessidade deste cenário.
    }

    // ==============================================================
    // Testes da Função `calculateReward`
    // ==============================================================

    function test_CalculateReward_ReturnsZeroForNonStakedNFT() public view {
        assertEq(eduStaking.calculateReward(FIRST_TOKEN_ID), 0);
    }

    function test_CalculateReward_CorrectlyCalculatesReward_WithoutBonus() public _userHasStakedNft {
        // ARRANGE: Garantir que o preço está ACIMA do limiar (sem bônus)
        mockPriceFeed.updateAnswer(PRICE_ABOVE_THRESHOLD);
        vm.warp(block.timestamp + STAKE_DURATION);

        // ACT: Calcular a recompensa
        uint256 reward = eduStaking.calculateReward(FIRST_TOKEN_ID);

        // ASSERT: Verificar se o cálculo está correto (sem bônus)
        uint256 expectedReward = STAKE_DURATION * eduStaking.BASE_REWARD_RATE();
        assertEq(reward, expectedReward);
    }

    function test_CalculateReward_CorrectlyCalculatesReward_WithBonus() public _userHasStakedNft {
        // ARRANGE: Mudar o preço para ABAIXO do limiar (com bônus)
        mockPriceFeed.updateAnswer(PRICE_BELOW_THRESHOLD);
        vm.warp(block.timestamp + STAKE_DURATION);

        // ACT: Calcular a recompensa
        uint256 reward = eduStaking.calculateReward(FIRST_TOKEN_ID);

        // ASSERT: Verificar se o cálculo está correto (com bônus)
        uint256 expectedReward = STAKE_DURATION * eduStaking.BASE_REWARD_RATE() * eduStaking.BONUS_MULTIPLIER();
        assertEq(reward, expectedReward);
    }

    function test_CalculateReward_IsCorrectAtPriceThreshold() public _userHasStakedNft {
        // ARRANGE: Mudar o preço para EXATAMENTE o limiar
        mockPriceFeed.updateAnswer(eduStaking.ETH_PRICE_THRESHOLD());
        vm.warp(block.timestamp + STAKE_DURATION);

        // ACT: Calcular a recompensa
        uint256 reward = eduStaking.calculateReward(FIRST_TOKEN_ID);

        // ASSERT: O bônus NÃO deve ser aplicado, pois a condição é `price < threshold`
        uint256 expectedReward = STAKE_DURATION * eduStaking.BASE_REWARD_RATE();
        assertEq(reward, expectedReward);
    }

    function test_CalculateReward_RevertsIf_PriceIsInvalid() public _userHasStakedNft {
        // ARRANGE: Mudar o preço para um valor inválido (zero)
        mockPriceFeed.updateAnswer(0);

        vm.expectRevert(EduStaking.EduStaking__InvalidPrice.selector);
        eduStaking.calculateReward(FIRST_TOKEN_ID);
    }

    // ==============================================================
    // Fuzz Tests
    // ==============================================================

    function testFuzz_Stake_RevertsForUnownedOrNonexistentTokenId(uint256 tokenId) public {
        // ARRANGE
        // Mintamos o token 0 para o USER.
        vm.prank(USER);
        studentBadge.mint();
        // O fuzzer irá testar com `tokenId`s aleatórios.
        // Garantimos que ele não teste o único caso válido (0).
        vm.assume(tokenId != FIRST_TOKEN_ID);

        // ACT & ASSERT: Esperamos um revert, pois o USER não possui o `tokenId` aleatório.
        vm.expectRevert();
        eduStaking.stake(tokenId);
    }

    function testFuzz_Unstake_RevertsForUnstakedOrUnownedToken(uint256 tokenId) public _userHasStakedNft {
        // ARRANGE
        // O usuário USER já fez stake do FIRST_TOKEN_ID (0) no modifier.
        // O fuzzer irá testar com `tokenId`s aleatórios.
        // Garantimos que ele não teste o único caso válido para o USER.
        vm.assume(tokenId != FIRST_TOKEN_ID);

        // ACT & ASSERT: Esperamos um revert, pois o USER não é o dono do stake do `tokenId` aleatório.
        vm.expectRevert(EduStaking.EduStaking__NotOwnerOfNFT.selector);
        vm.prank(USER);
        eduStaking.unstake(tokenId);
    }
}
