// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";

/// @dev Interface mínima para interagir com o contrato EduToken.
interface IEduToken {
    function mint(address to, uint256 amount) external;
}

/// @title EduStaking - Contrato de Staking com Subsídio via Oráculo
contract EduStaking is ReentrancyGuard {
    // Custom Errors
    error EduStaking__NotOwnerOfNFT();
    error EduStaking__InvalidPrice();
    error EduStaking__StakingTimeNotMet();

    /// @notice O contrato do NFT StudentBadge, necessário para o staking.
    IERC721 public immutable STUDENT_BADGE;
    /// @notice O contrato do token de recompensa EDU.
    IEduToken public immutable EDU_TOKEN;
    /// @notice A interface do oráculo de preços ETH/USD do Chainlink.
    IAggregatorV3 public immutable PRICE_FEED;

    /// @notice A taxa base de emissão de recompensas em EDU por segundo.
    uint256 public constant BASE_REWARD_RATE = 1 * 10 ** 15; // 0.001 EDU por segundo
    /// @notice O multiplicador de bônus aplicado às recompensas quando o preço do ETH está baixo.
    uint256 public constant BONUS_MULTIPLIER = 2; // Bônus de 2x
    /// @notice Tempo mínimo que o NFT deve permanecer em stake antes de poder ser retirado.
    uint256 public constant MIN_STAKING_TIME = 30 seconds;
    /// @notice O limiar de preço do ETH em USD. Se o preço cair abaixo disso, o bônus é ativado.
    int256 public constant ETH_PRICE_THRESHOLD = 2000 * 10 ** 8; // $2000 USD (Chainlink usa 8 decimais)

    /// @dev Estrutura para armazenar informações sobre cada NFT em stake.
    struct StakeInfo {
        address owner; // O dono original do NFT (160 bits).
        uint64 timestamp; // O momento em que o stake foi realizado (64 bits).
    }

    /// @notice Mapeamento do ID do token para as informações do seu stake.
    mapping(uint256 => StakeInfo) public stakes;

    /// @dev Emitido quando um NFT é colocado em stake.
    event Staked(address indexed user, uint256 indexed tokenId);
    /// @dev Emitido quando um NFT é retirado do stake.
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 reward);

    /// @dev Inicializa o contrato com os endereços das suas dependências.
    /// @param _badge O endereço do contrato StudentBadge (NFT).
    /// @param _token O endereço do contrato EduToken (ERC20).
    /// @param _priceFeed O endereço do oráculo de preços ETH/USD do Chainlink.
    constructor(address _badge, address _token, address _priceFeed) {
        STUDENT_BADGE = IERC721(_badge);
        EDU_TOKEN = IEduToken(_token);
        PRICE_FEED = IAggregatorV3(_priceFeed);
    }

    /// @notice Trava o NFT no contrato
    /// @param tokenId O ID do NFT StudentBadge a ser colocado em stake.
    function stake(uint256 tokenId) external nonReentrant {
        // [CHECKS]
        if (STUDENT_BADGE.ownerOf(tokenId) != msg.sender) revert EduStaking__NotOwnerOfNFT();

        // [EFFECTS]
        stakes[tokenId] = StakeInfo({owner: msg.sender, timestamp: uint64(block.timestamp)});

        // [INTERACTIONS]
        STUDENT_BADGE.transferFrom(msg.sender, address(this), tokenId);

        emit Staked(msg.sender, tokenId);
    }

    /// @notice Destrava o NFT e minera as recompensas baseadas no Oráculo
    /// @param tokenId O ID do NFT a ser retirado do stake.
    function unstake(uint256 tokenId) external nonReentrant {
        // [CHECKS]
        StakeInfo memory info = stakes[tokenId];
        if (info.owner != msg.sender) revert EduStaking__NotOwnerOfNFT();
        if (block.timestamp < info.timestamp + MIN_STAKING_TIME) revert EduStaking__StakingTimeNotMet();

        // [EFFECTS]
        uint256 reward = _calculateReward(info);
        delete stakes[tokenId]; // Previne reentrância lógica

        // [INTERACTIONS]
        if (reward > 0) {
            EDU_TOKEN.mint(msg.sender, reward);
        }
        STUDENT_BADGE.transferFrom(address(this), msg.sender, tokenId);

        emit Unstaked(msg.sender, tokenId, reward);
    }

    /// @notice Calcula a recompensa com base no tempo e no preço do ETH
    /// @param tokenId O ID do NFT para o qual a recompensa será calculada.
    /// @return A quantidade de recompensa em EDU acumulada.
    function calculateReward(uint256 tokenId) public view returns (uint256) {
        StakeInfo memory info = stakes[tokenId];
        if (info.owner == address(0)) return 0;
        return _calculateReward(info);
    }

    /// @dev Lógica interna para o cálculo da recompensa, evitando SLOADs duplicados.
    /// @param info A struct `StakeInfo` do NFT, já carregada em memória.
    function _calculateReward(StakeInfo memory info) private view returns (uint256) {
        uint256 timeStaked = block.timestamp - info.timestamp;
        uint256 reward = timeStaked * BASE_REWARD_RATE;

        // Leitura do Oráculo Chainlink
        (, int256 price,,,) = PRICE_FEED.latestRoundData();
        if (price <= 0) revert EduStaking__InvalidPrice();

        // Subsídio: Se o ETH estiver barato (abaixo do limiar), ganha bônus
        if (price < ETH_PRICE_THRESHOLD) {
            reward = reward * BONUS_MULTIPLIER;
        }

        return reward;
    }
}
