// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EduToken} from "../src/token/EduToken.sol";
import {StudentBadge} from "../src/nft/StudentBadge.sol";
import {EduStaking} from "../src/staking/EduStaking.sol";
import {EduDAO} from "../src/dao/EduDAO.sol";

contract DeployEduProtocol is Script {
    function run() external {
        // Pega a chave privada do arquivo .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // CORREÇÃO AQUI: Descobre o endereço público a partir da chave!
        address deployerAddress = vm.addr(deployerPrivateKey);

        address priceFeed = vm.envAddress("PRICE_FEED_ADDRESS");
        address newOwner = vm.envAddress("NEW_OWNER_ADDRESS"); // Endereço da Multisig ou Timelock

        // INÍCIO DAS TRANSAÇÕES REAIS
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy do NFT
        StudentBadge badge = new StudentBadge();
        console.log("StudentBadge (NFT) implantado em:", address(badge));

        // 2. Deploy do Token (CORREÇÃO AQUI: Passando o seu endereço real como DONO!)
        EduToken token = new EduToken(deployerAddress);
        console.log("EduToken implantado em:", address(token));

        // 3. Deploy do Staking
        EduStaking staking = new EduStaking(address(badge), address(token), priceFeed);
        console.log("EduStaking implantado em:", address(staking));

        // 4. Configuração de Segurança (Controle de Acesso)
        // Passamos a permissão de "mintar" tokens exclusivamente para o contrato de Staking
        token.setStakingContract(address(staking));
        console.log("Permissao de mint concedida ao contrato de Staking.");

        // 5. Deploy da DAO
        EduDAO dao = new EduDAO(address(token));
        console.log("EduDAO implantado em:", address(dao));

        // 6. Transferência de Propriedade (Passo de Segurança Crítico)
        // Inicia a transferência da propriedade do EduToken para um endereço seguro.
        // O novo dono precisará chamar `acceptOwnership()` para completar o processo.
        console.log("Iniciando transferencia de propriedade do EduToken para:", newOwner);
        token.transferOwnership(newOwner);

        // FIM DAS TRANSAÇÕES REAIS
        vm.stopBroadcast();
    }
}
