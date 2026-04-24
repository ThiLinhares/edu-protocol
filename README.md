# 🎓 Edu Protocol (EduStake)

[![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.24-363636.svg?style=flat&logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FF5934.svg)](https://getfoundry.sh/)
[![Hardhat](https://img.shields.io/badge/Built%20with-Hardhat-FFF100.svg)](https://hardhat.org/)
[![ethers.js](https://img.shields.io/badge/ethers.js-v6.7.0-274291.svg)](https://docs.ethers.org/v6/)
[![Network](https://img.shields.io/badge/Network-Sepolia_Testnet-8C8C8C.svg)](https://sepolia.etherscan.io/)

O **Edu Protocol** é uma infraestrutura descentralizada (Web3) criada para revolucionar o engajamento educacional. Utilizando incentivos criptoeconômicos, o protocolo recompensa alunos por sua permanência e mérito em cursos, transformando o histórico acadêmico em identidades verificáveis (NFTs) e concedendo poder de governança (Tokens ERC-20).

Projeto desenvolvido como trabalho prático para a **Residência em TIC - Trilha Web3 / Blockchain**.

**👤 Aluno:** Francisco Thiago Linhares Morais  
**🎥 Vídeo Demonstrativo:** [Acessar no Google Drive](https://drive.google.com/drive/folders/1NFO-NWGSICSvFuoYheZOaqgqLOws_DlW?usp=sharing)  

---

## 📖 Modelagem do Problema
O ambiente educacional digital contemporâneo, notadamente os cursos online de longa duração (EAD), enfrenta um desafio sistêmico: a alta taxa de evasão e a dificuldade em manter o engajamento contínuo dos discentes. 

O Edu Protocol surge como uma solução que introduz incentivos criptoeconômicos no processo de aprendizagem. Ao modelar a permanência e o mérito acadêmico como ativos digitais verificáveis, o protocolo alinha os interesses educacionais com recompensas financeiras e poder de governança, mitigando a evasão através da tokenização da atenção.

---

## 🏗️ Arquitetura de Smart Contracts

O ecossistema possui uma arquitetura modular orientada a contratos inteligentes, fundamentada em Padrões Ethereum (ERC) rigorosos, com clara separação de responsabilidades:

1. **`StudentBadge.sol` (Padrão ERC-721):** O "Crachá" do estudante. Diferente da fungibilidade, um histórico acadêmico não é intercambiável. Implementado como um NFT *Soulbound-like* restrito a um *mint* por carteira, ele atua como identidade base e chave de acesso, prevenindo ataques de Sybil.
2. **`EduStaking.sol` (Cofre / Vault):** O aluno transfere a custódia temporária de seu NFT para este contrato. Durante o *TimeLock* (carência), o contrato mensura o tempo decorrido e calcula organicamente o rendimento passivo. Ele é o único agente com permissão de emitir recompensas.
3. **`EduToken.sol` (Padrão ERC-20):** Token utilitário e de governança (`$EDU`). Com divisibilidade granular (18 casas decimais), permite que o staking pague recompensas proporcionais até ao nível dos segundos. Possui emissão infinita (*∞ Minting*), porém bloqueada por rígido Controle de Acesso (*Access Control*) restrito ao Vault.
4. **`EduDAO.sol` (Governança):** O protocolo verifica os saldos instantâneos para conceder poder de participação. Exige um *Proposal Threshold* (100 EDU) para criação de propostas (proteção anti-spam) e um *Minimum Vote Power* (10 EDU) para votação ativa.

---

## 🔮 Integração com Oráculos (Chainlink)

Para neutralizar o impacto da volatilidade do mercado de criptomoedas sobre a percepção de valor da recompensa do estudante, o protocolo implementa uma integração com os Data Feeds Descentralizados da Chainlink.

O contrato `EduStaking` consome ativamente o par **ETH/USD**. A lógica parametrizada estabelece um limiar (*threshold*) fixo de USD $2.000. Se o preço do Ethereum sofrer desvalorização e cruzar esse limite inferior, o protocolo aciona um mecanismo de subsídio automático (`BONUS_MULTIPLIER`), **dobrando a taxa de emissão** de `$EDU` para proteger o engajamento do aluno.

---

## 🌐 Deploy na Sepolia Testnet

Todos os contratos estão verificados e operacionais na rede de testes Ethereum Sepolia:

- **StudentBadge (NFT):** `0x22DDBfddb9A3df2865a4B97091231cA96D7d4880`
- **EduToken (ERC-20):** `0x85F5E7BefA3B6b7213CfF427A5b06b86EBDcFD0B`
- **EduStaking:** `0x7ef23793cC13AD6F83e9DF1bfE2C14D0Aa8A1DC2`
- **EduDAO:** `0xb02E4B381bd565BDd53607e0583fd012Ef67e939`

---

## ⚙️ Tecnologias Utilizadas

- **Blockchain / Backend:** Solidity (EVM target: Cancun), Foundry, Hardhat, OpenZeppelin Contracts v5.
- **Oráculos:** Chainlink Data Feeds (ETH/USD).
- **Frontend:** HTML5, CSS3, Vanilla JavaScript.
- **Integração Web3:** Ethers.js v6, MetaMask.
- **Segurança / Qualidade:** Slither Analyzer, Mythril, Padrão CEI (Checks-Effects-Interactions).

---

##  Frontend e Integração Web3 (DApp)

A camada de interação cliente-blockchain foi desenvolvida com a biblioteca **ethers.js (v6)**. A arquitetura de injeção de dependência interage com o `window.ethereum`, delegando ao usuário a assinatura criptográfica de cada ação. Destaques da implementação:

- **Gestão Assíncrona (Transações Atômicas):** A rotina de stake foi orquestrada com a invocação do `approve()` no ERC-721, seguida imediatamente pelo `stake()` no contrato cofre.
- **Decodificação Dinâmica de Erros (ABI Parsing):** Reversões de bloco são interceptadas e traduzidas de códigos de baixo nível para mensagens legíveis na UI (ex: `EduDAO__VotingClosed`).
- **Consumo de Eventos (Log Polling):** O estado da DApp é montado filtrando historicamente eventos (como `Transfer`) emitidos pelos nós, através da função `queryFilter()`, dispensando iterações custosas on-chain.

### Jornada do Usuário
1. **Conectar Carteira:** O usuário autentica sua MetaMask na rede Sepolia.
2. **Mint do Crachá:** O aluno emite seu `StudentBadge` (Transação única).
3. **Stake:** O aluno aprova e trava seu NFT no contrato de Staking. O tempo de carência (*TimeLock*) é de 30 segundos para fins de testes do MVP.
4. **Acúmulo de Recompensas:** Enquanto travado, o contrato calcula organicamente os rendimentos em `$EDU`.
5. **Governança (DAO):** Ao atingir os limites estipulados de Tokens EDU, o usuário pode interagir com a DAO, seja criando novas propostas de votação ou votando em propostas abertas.

### Rodando Localmente

A maneira mais rápida de rodar a interface:
1. Clone o repositório.
2. Abra a pasta no **VS Code**.
3. Certifique-se de ter a extensão **Live Server** instalada.
4. Navegue até a pasta `/frontend` e abra o `index.html`.
5. Clique com o botão direito no código e selecione **"Open with Live Server"**.

---

## 🛠️ Desenvolvimento e Testes de Smart Contracts

Este projeto utiliza uma infraestrutura robusta e híbrida de testes, integrando as vantagens do **Foundry** (rápido e nativo em Solidity) e do **Hardhat** (flexível e baseado em JavaScript/Ethers.js).

### Instalação e Compilação
```bash
# Instalar dependências (OpenZeppelin e Chainlink)
forge install

# Compilar os contratos
forge build

# Instalar dependências do ecossistema JS/Hardhat
npm install

# Configurar Variáveis de Ambiente
# Copie o arquivo .env.example para .env e preencha com a sua PRIVATE_KEY
```

### Rodando os Testes
A base de código possui testes unitários e testes de propriedade (Fuzzing).
```bash
# Executar toda a suíte de testes com logs detalhados
forge test -vvv
```

### Análise Estática (Segurança)
Auditoria automatizada realizada com a ferramenta Slither:
```bash
# Exige Python e a biblioteca slither-analyzer instalada via pip
slither .
```
*Nota: Os relatórios detalhados gerados encontram-se em formato `.txt` na raiz do repositório, com os devidos tratamentos para falsos positivos originados de dependências.*

---

## 📄 Licença

Distribuído sob a licença MIT. Veja o arquivo LICENSE para mais informações.

---
**Desenvolvido por:** Thiago Linhares