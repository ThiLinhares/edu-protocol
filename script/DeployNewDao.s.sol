// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EduDAO} from "../src/dao/EduDAO.sol";

contract DeployNewDao is Script {
    function run() external {
        // Carrega a chave privada do deployer a partir das variáveis de ambiente
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Endereço do contrato EduToken já implantado na rede
        address existingToken = 0x85F5E7BefA3B6b7213CfF427A5b06b86EBDcFD0B;

        // Inicia o broadcast da transação
        vm.startBroadcast(deployerPrivateKey);

        // Realiza o deploy do contrato EduDAO
        EduDAO newDao = new EduDAO(existingToken);
        
        console.log("--- Deploy Concluido ---");
        console.log("EduDAO (Novo):", address(newDao));

        vm.stopBroadcast();
    }
}