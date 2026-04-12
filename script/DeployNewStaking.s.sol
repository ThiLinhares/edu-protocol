// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EduStaking} from "../src/staking/EduStaking.sol";

contract DeployNewStaking is Script {
    function run() external {
        // Configuração de ambiente e oráculo
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address priceFeed = vm.envAddress("PRICE_FEED_ADDRESS");

        // Endereços dos contratos já implantados na rede
        address existingBadge = 0x22DDBfddb9A3df2865a4B97091231cA96D7d4880;
        address existingToken = 0x85F5E7BefA3B6b7213CfF427A5b06b86EBDcFD0B;

        // Inicia o broadcast da transação
        vm.startBroadcast(deployerPrivateKey);

        // Realiza o deploy do contrato EduStaking atualizado
        EduStaking newStaking = new EduStaking(existingBadge, existingToken, priceFeed);
        
        console.log("--- Deploy Concluido ---");
        console.log("EduStaking (Novo):", address(newStaking));

        vm.stopBroadcast();
    }
}