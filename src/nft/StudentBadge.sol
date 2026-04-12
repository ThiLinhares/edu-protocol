// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title StudentBadge - NFT de Acesso ao Protocolo
contract StudentBadge is ERC721 {
    error StudentBadge__AlreadyMinted();

    /// @dev Contador para garantir que cada NFT tenha um ID único.
    uint256 private _nextTokenId;

    /// @dev Rastreia se um endereço já mintou um badge para garantir um por estudante.
    mapping(address => bool) private _hasMinted;

    /// @dev Inicializa o NFT, definindo seu nome e símbolo.
    constructor() ERC721("StudentBadge", "STB") {}

    /// @notice Permite que qualquer usuário minte seu Badge de estudante
    /// @dev A função é aberta para simbolizar a entrada de um novo "estudante" no protocolo.
    /// @dev Adicionada verificação para permitir apenas um mint por endereço.
    function mint() external {
        if (_hasMinted[msg.sender]) revert StudentBadge__AlreadyMinted();

        _hasMinted[msg.sender] = true;
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }
}
