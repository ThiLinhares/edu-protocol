// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title EduToken - Token de Recompensa e Governança
contract EduToken is ERC20, Ownable2Step {
    error EduToken__OnlyStakingContract();
    error EduToken__ZeroAddress();

    /// @notice Endereço do contrato de Staking, o único com permissão para emitir novos tokens.
    address public stakingContract;

    /// @dev Inicializa o token, definindo o nome, símbolo e o dono inicial.
    /// @param initialOwner O endereço que terá o controle administrativo do contrato (ex: para definir o `stakingContract`).
    constructor(address initialOwner) ERC20("EduToken", "EDU") Ownable(initialOwner) {
        // Adicionar esta verificação previne a criação de um contrato sem dono desde o início.
        if (initialOwner == address(0)) revert EduToken__ZeroAddress();
    }

    /// @notice Define qual contrato tem permissão para emitir tokens
    /// @dev Apenas o `owner` pode chamar esta função. Essencial para a segurança do protocolo.
    /// @param _stakingContract O endereço do contrato de Staking.
    function setStakingContract(address _stakingContract) external onlyOwner {
        if (_stakingContract == address(0)) revert EduToken__ZeroAddress();
        stakingContract = _stakingContract;
    }

    /// @notice Função de emissão restrita ao contrato de Staking
    /// @dev Garante que novos tokens só possam ser criados como recompensa pelo staking.
    /// @param to O endereço que receberá os novos tokens.
    /// @param amount A quantidade de tokens a ser emitida.
    function mint(address to, uint256 amount) external {
        if (msg.sender != stakingContract) {
            revert EduToken__OnlyStakingContract();
        }
        _mint(to, amount);
    }
}
