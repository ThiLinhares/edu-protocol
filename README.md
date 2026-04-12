# 🎓 Edu Protocol (EduStake)

[![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.24-363636.svg?style=flat&logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FF5934.svg)](https://getfoundry.sh/)
[![ethers.js](https://img.shields.io/badge/ethers.js-v6.7.0-274291.svg)](https://docs.ethers.org/v6/)
[![Network](https://img.shields.io/badge/Network-Sepolia_Testnet-8C8C8C.svg)](https://sepolia.etherscan.io/)

O **Edu Protocol** é uma infraestrutura descentralizada (Web3) criada para revolucionar o engajamento educacional. Utilizando incentivos criptoeconômicos, o protocolo recompensa alunos por sua permanência e mérito em cursos, transformando o histórico acadêmico em identidades verificáveis (NFTs) e concedendo poder de governança (Tokens ERC-20).

Projeto desenvolvido como trabalho prático para a **Residência em TIC - Trilha Web3 / Blockchain**.

---

## 🏗️ Arquitetura de Smart Contracts

O ecossistema é modular e composto por 4 contratos inteligentes principais integrados:

1. **`StudentBadge.sol` (ERC-721):** O "Crachá" do estudante. Um NFT *Soulbound-like* (limitado a 1 por carteira) que atua como identidade base e chave de acesso ao ecossistema.
2. **`EduToken.sol` (ERC-20):** O token utilitário e de governança (`$EDU`). Possui emissão controlada exclusivamente pelo contrato de Staking.
3. **`EduStaking.sol` (Vault):** Cofre de custódia onde o aluno deposita seu NFT para minerar tokens `$EDU` passivamente. Possui trava de tempo (*TimeLock*) e integra um Oráculo da Chainlink para aplicar multiplicadores de bônus baseados no preço do Ethereum.
4. **`EduDAO.sol` (Governança):** Sistema de votação descentralizada. Exige um *Proposal Threshold* (100 EDU) para criação de propostas e um *Minimum Vote Power* (10 EDU) para participação.

---

## 🌐 Deploy na Sepolia Testnet

Todos os contratos estão verificados e operacionais na rede de testes Ethereum Sepolia:

- **StudentBadge (NFT):** `0x22DDBfddb9A3df2865a4B97091231cA96D7d4880`
- **EduToken (ERC-20):** `0x85F5E7BefA3B6b7213CfF427A5b06b86EBDcFD0B`
- **EduStaking:** `0x7ef23793cC13AD6F83e9DF1bfE2C14D0Aa8A1DC2`
- **EduDAO:** `0xb02E4B381bd565BDd53607e0583fd012Ef67e939`

---

## ⚙️ Tecnologias Utilizadas

- **Blockchain / Backend:** Solidity, Foundry (Forge, Cast, Anvil, Chisel), OpenZeppelin Contracts.
- **Oráculos:** Chainlink Data Feeds (ETH/USD).
- **Frontend:** HTML5, CSS3, Vanilla JavaScript.
- **Integração Web3:** Ethers.js v6, MetaMask.
- **Segurança / Auditoria:** Slither Analyzer.

---

## 🚀 Guia de Uso (Frontend DApp)

O frontend é construído de forma leve e fluida, sem a necessidade de *bundlers* complexos como Webpack ou Vite.

### Jornada do Usuário
1. **Conectar Carteira:** O usuário autentica sua MetaMask na rede Sepolia.
2. **Mint do Crachá:** O aluno emite seu `StudentBadge` (Transação única).
3. **Stake:** O aluno aprova e trava seu NFT no contrato de Staking. O tempo de carência para saque é de 30 segundos (configuração de MVP para testes).
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

Este projeto utiliza o *framework* de desenvolvimento Foundry. 

### Instalação e Compilação
```bash
# Instalar dependências (OpenZeppelin e Chainlink)
forge install

# Compilar os contratos
forge build

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