// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title EduDAO - Governança Simplificada
contract EduDAO {
    error EduDAO__InsufficientTokens();
    error EduDAO__InsufficientTokensToPropose();
    error EduDAO__ProposalDoesNotExist();
    error EduDAO__AlreadyVoted();
    error EduDAO__VotingClosed();
    error EduDAO__BalanceTooLargeForVoteWeight();

    /// @notice O token de governança do protocolo.
    IERC20 public immutable EDU_TOKEN;
    /// @notice A quantidade mínima de tokens EDU que um usuário deve possuir para criar ou votar em uma proposta.
    uint256 public constant MIN_VOTE_POWER = 10 * 10 ** 18; // Mínimo de 10 EDU para votar
    /// @notice A quantidade mínima de tokens EDU que um usuário deve possuir para criar uma proposta (proteção contra spam).
    uint256 public constant PROPOSAL_THRESHOLD = 100 * 10 ** 18; // Mínimo de 100 EDU para criar proposta

    /// @dev Estrutura que armazena os detalhes de cada proposta.
    struct Proposal {
        bytes32 descriptionHash; // Hash da descrição da proposta (armazenada off-chain, ex: IPFS).
        uint128 votesFor; // Soma dos saldos dos votantes a favor.
        uint128 votesAgainst; // Soma dos saldos dos votantes contra.
        uint64 deadline; // Timestamp de quando a votação encerra.
    }

    /// @notice Contador para o ID da próxima proposta, garantindo IDs únicos.
    uint256 public nextProposalId;
    /// @notice Mapeamento do ID da proposta para seus detalhes.
    mapping(uint256 => Proposal) public proposals;
    /// @notice Rastreia se um endereço já votou em uma determinada proposta para evitar votos duplos.
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    /// @dev Emitido quando uma nova proposta é criada.
    event ProposalCreated(uint256 indexed id, bytes32 descriptionHash, uint256 deadline);
    /// @dev Emitido quando um voto é computado.
    event Voted(uint256 indexed id, address indexed voter, bool support, uint256 weight);

    /// @dev Inicializa a DAO com o endereço do token de governança.
    /// @param _token O endereço do contrato do token EDU.
    constructor(address _token) {
        EDU_TOKEN = IERC20(_token);
    }

    /// @notice Cria uma nova proposta de governança.
    /// @dev O criador da proposta deve possuir o saldo mínimo definido em `PROPOSAL_THRESHOLD`.
    /// @param _descriptionHash O hash da descrição da proposta (ex: keccak256 da descrição em texto).
    function createProposal(bytes32 _descriptionHash) external {
        if (EDU_TOKEN.balanceOf(msg.sender) < PROPOSAL_THRESHOLD) revert EduDAO__InsufficientTokensToPropose();

        uint256 id = nextProposalId++;
        proposals[id] = Proposal({
            descriptionHash: _descriptionHash, votesFor: 0, votesAgainst: 0, deadline: uint64(block.timestamp + 3 days)
        });
        emit ProposalCreated(id, _descriptionHash, proposals[id].deadline);
    }

    /// @notice Registra um voto em uma proposta ativa.
    /// @param proposalId O ID da proposta a ser votada.
    /// @param support `true` para votar a favor, `false` para votar contra.
    function vote(uint256 proposalId, bool support) external {
        uint256 voterBalance = EDU_TOKEN.balanceOf(msg.sender);

        // [CHECKS]
        // Garante que o saldo do votante cabe em um uint128 para evitar overflow no peso do voto.
        // Esta verificação é feita primeiro para evitar um pânico de overflow em vez de um erro personalizado.
        if (voterBalance > type(uint128).max) revert EduDAO__BalanceTooLargeForVoteWeight();
        if (voterBalance < MIN_VOTE_POWER) revert EduDAO__InsufficientTokens();

        Proposal storage p = proposals[proposalId];
        if (p.deadline == 0) revert EduDAO__ProposalDoesNotExist();
        if (block.timestamp > p.deadline) revert EduDAO__VotingClosed();
        if (hasVoted[proposalId][msg.sender]) revert EduDAO__AlreadyVoted();

        // [EFFECTS]
        hasVoted[proposalId][msg.sender] = true;
        if (support) {
            // The cast is safe because we've already checked that voterBalance <= type(uint128).max
            // forge-lint: disable-next-line
            p.votesFor += uint128(voterBalance);
        } else {
            // The cast is safe because we've already checked that voterBalance <= type(uint128).max
            // forge-lint: disable-next-line
            p.votesAgainst += uint128(voterBalance);
        }

        // [INTERACTIONS]
        emit Voted(proposalId, msg.sender, support, voterBalance);
    }
}
