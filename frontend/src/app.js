import { ethers } from "https://cdnjs.cloudflare.com/ajax/libs/ethers/6.7.0/ethers.min.js";
import { BadgeABI, StakingABI, DaoABI, EduTokenABI } from "./abis.js";

/** @notice Endereços dos contratos inteligentes deployados na rede. */
const ADDRESS_BADGE = "0x22DDBfddb9A3df2865a4B97091231cA96D7d4880"; 
const ADDRESS_STAKING = "0x7ef23793cC13AD6F83e9DF1bfE2C14D0Aa8A1DC2";
const ADDRESS_DAO = "0xb02E4B381bd565BDd53607e0583fd012Ef67e939";

/** @notice Variáveis de estado que armazenam a conexão com a blockchain e as instâncias dos contratos. */
let provider, signer, userAddress;
let studentBadge, eduStaking, eduDAO, eduToken;
/** @notice Armazena o ID do NFT mintado na sessão atual para ser usado em outras funções (stake, unstake). */
let currentTokenId = null;

/** @notice Referências aos elementos da interface do usuário (HTML). */
const statusDiv = document.getElementById("status");
const walletInfoDiv = document.getElementById("wallet-info");
const userAddressSpan = document.getElementById("user-address");
const nftIdSpan = document.getElementById("nft-id");
const eduBalanceSpan = document.getElementById("edu-balance");
const btnConnect = document.getElementById("btn-connect");
const btnMint = document.getElementById("btn-mint");
const btnStake = document.getElementById("btn-stake");
const btnUnstake = document.getElementById("btn-unstake");
const btnVote = document.getElementById("btn-vote");
const btnCreateProposal = document.getElementById("btn-create-proposal");

/**
 * Atualiza a div de status com uma nova mensagem.
 * @param {string} message A mensagem a ser exibida.
 * @param {boolean} [isError=false] Se verdadeiro, exibe a mensagem em vermelho.
 */
function updateStatus(message, isError = false) {
    if (isError) {
        console.error(message);
        statusDiv.innerHTML = `<strong style="color: red;">Status:</strong> ${message}`;
    } else {
        console.log(message);
        statusDiv.innerHTML = `<strong>Status:</strong> ${message}`;
    }
}

/**
 * Traduz um erro técnico da blockchain para uma mensagem amigável ao usuário.
 * @param {Error} error O objeto de erro retornado pelo ethers.js.
 * @returns {string} Uma mensagem de erro legível.
 */
function getFriendlyErrorMessage(error) {
    console.error("Raw error:", error); // Log do erro completo para depuração

    // Usuário da MetaMask rejeitou a transação
    if (error.code === 4001 || error.info?.error?.code === 4001) {
        return "Transação rejeitada pelo usuário na MetaMask.";
    }

    // Extrai o código de erro (data) de forma segura
    let errorData = error.data || error.info?.error?.data || error.error?.data || error.info?.data;

    // Erros customizados de contrato (via errorData)
    if (errorData && typeof errorData === 'string') {
        
        // Parse dinâmico dos erros utilizando as ABIs dos contratos
        try {
            if (eduDAO) {
                const parsed = eduDAO.interface.parseError(errorData);
                if (parsed?.name === "EduDAO__InsufficientTokens") return "Erro de Votação: Você não possui a quantidade mínima de tokens EDU exigida pela DAO.";
                if (parsed?.name === "EduDAO__AlreadyVoted") return "Erro de Votação: Você já votou nesta proposta.";
                if (parsed?.name === "EduDAO__VotingClosed") return "Erro de Votação: A votação não está mais aberta. O período para esta proposta já encerrou.";
                if (parsed?.name === "EduDAO__ProposalDoesNotExist") return "Erro de Votação: A proposta na qual você tentou votar não existe.";
            }
            if (eduStaking) {
                const parsed = eduStaking.interface.parseError(errorData);
                if (parsed?.name === "EduStaking__NotOwnerOfNFT") return "Erro de Stake: Você não é o dono deste NFT para poder fazer o stake.";
                if (parsed?.name === "EduStaking__StakingTimeNotMet") return "Acesso Negado: O tempo mínimo de 30 segundos ainda não passou! Aguarde mais um pouco.";
            }
            if (studentBadge) {
                const parsed = studentBadge.interface.parseError(errorData);
                if (parsed?.name === "ERC721InvalidApprover") return "Erro de Permissão: Você tentou aprovar/stakar um NFT que não pertence a você.";
            }
            if (eduToken) {
                const parsed = eduToken.interface.parseError(errorData);
                if (parsed?.name === "EduToken__OnlyStakingContract") return "Acesso Negado: Segurança do Contrato! Apenas o contrato de Staking tem permissão para mintar novos tokens EDU.";
                if (parsed?.name === "OwnableUnauthorizedAccount") return "Acesso Negado: Apenas a carteira criadora (Dona) do contrato pode mintar tokens de teste diretamente.";
            }
        } catch (e) {
            // Ignora silenciosamente e continua para o fallback manual abaixo
        }

        const errorSelector = errorData.slice(0, 10);
        switch (errorSelector) {
            // Erros do EduDAO
            case "0x6f68cda9": // keccak256("EduDAO__InsufficientTokens()")
                return "Erro de Votação: Você não possui a quantidade mínima de tokens EDU exigida pela DAO.";
            case "0x152d5045": // keccak256("EduDAO__AlreadyVoted()")
                return "Erro de Votação: Você já votou nesta proposta.";
            case "0xe0b8d95f": // keccak256("EduDAO__VotingClosed()")
                return "Erro de Votação: O período de votação para esta proposta já encerrou.";
            case "0x1dcc4df1": // keccak256("EduDAO__ProposalDoesNotExist()")
                return "Erro de Votação: A proposta na qual você tentou votar não existe.";
            
            // Erros do EduStaking
            case "0x84578482": // keccak256("EduStaking__NotOwnerOfNFT()")
                return "Erro de Stake: Você não é o dono deste NFT para poder fazer o stake.";
            case "0xba3ed109": // keccak256("EduStaking__StakingTimeNotMet()")
                return "Acesso Negado: O tempo mínimo de 30 segundos ainda não passou! Aguarde mais um pouco.";
                
            // Erros do OpenZeppelin ERC721
            case "0xa9fbf51f": // ERC721InvalidApprover(address)
                return "Erro de Permissão: Você tentou aprovar/stakar um NFT que não pertence a você.";
                
            // Erros do OpenZeppelin Ownable
            case "0x118cdaa7": // OwnableUnauthorizedAccount(address)
                return "Acesso Negado: Apenas a carteira criadora (Dona) do contrato pode mintar tokens de teste diretamente.";
                
            // Erros do EduToken
            case "0xb8b0ba03": // keccak256("EduToken__OnlyStakingContract()")
                return "Acesso Negado: Segurança do Contrato! Apenas o contrato de Staking tem permissão para mintar novos tokens EDU.";
        }
    }

    // Erros mais genéricos do ethers
    if (error.message && error.message.toLowerCase().includes("insufficient funds")) {
        return "Erro: Saldo insuficiente de ETH para pagar as taxas de gás da transação.";
    }

    // Fallback para erros não mapeados
    return `Ocorreu um erro inesperado. Verifique o console (F12) para mais detalhes.`;
}

/**
 * Busca e atualiza as informações da carteira do usuário na interface (endereço, saldo de EDU, etc.).
 */
async function updateWalletInfo() {
    if (!eduToken || !userAddress) return;
    userAddressSpan.textContent = userAddress;
    const balance = await eduToken.balanceOf(userAddress);
    eduBalanceSpan.textContent = ethers.formatEther(balance);
    if (currentTokenId !== null) {
        nftIdSpan.textContent = currentTokenId.toString();
    } else {
        nftIdSpan.textContent = "Nenhum";
    }
    
    // Checagem inteligente do poder de voto
    if (eduDAO) {
        const minVotePower = await eduDAO.MIN_VOTE_POWER();
        if (balance >= minVotePower) {
            btnVote.disabled = false;
            btnVote.textContent = "4. Votar na DAO";
            btnCreateProposal.disabled = false;
        } else {
            btnVote.disabled = true;
            btnVote.textContent = `4. Votar na DAO (Requer ${ethers.formatEther(minVotePower)} EDU)`;
            btnCreateProposal.disabled = true;
        }
    }

    walletInfoDiv.style.display = 'block';
}

/**
 * Zera a interface caso o usuário desconecte a carteira.
 */
function resetUI() {
    userAddress = null;
    currentTokenId = null;
    walletInfoDiv.style.display = 'none';
    btnConnect.textContent = "1. Conectar Carteira";
    btnConnect.disabled = false;
    btnMint.disabled = true;
    btnStake.disabled = true;
    btnUnstake.disabled = true;
    btnVote.disabled = true;
    btnCreateProposal.disabled = true;
    updateStatus("Carteira desconectada. Por favor, conecte novamente.", true);
}

/**
 * Conecta-se à carteira do usuário (ex: MetaMask), inicializa o provider, o signer
 * e as instâncias dos contratos para interação.
 */
async function connectWallet() {
    try {
        updateStatus("Conectando à carteira...");
        if (!window.ethereum) {
            updateStatus("MetaMask não detectado. Por favor, instale a extensão.", true);
            return;
        }
        provider = new ethers.BrowserProvider(window.ethereum);
        signer = await provider.getSigner();
        userAddress = await signer.getAddress();
        
        // Zera o token da sessão anterior para evitar conflito se o usuário trocou de conta
        currentTokenId = null; 
        
        // Atualiza e desabilita o botão de conectar
        btnConnect.textContent = `Conectado: ${userAddress.slice(0, 6)}...${userAddress.slice(-4)}`;
        btnConnect.disabled = true;
        
        updateStatus("Carteira conectada: " + userAddress);

        // Instancia os contratos principais com os quais o frontend irá interagir.
        studentBadge = new ethers.Contract(ADDRESS_BADGE, BadgeABI, signer);
        eduStaking = new ethers.Contract(ADDRESS_STAKING, StakingABI, signer);
        eduDAO = new ethers.Contract(ADDRESS_DAO, DaoABI, signer);
        
        // Descobre dinamicamente o endereço do token EDU a partir do contrato da DAO.
        const eduTokenAddress = await eduDAO.EDU_TOKEN();
        eduToken = new ethers.Contract(eduTokenAddress, EduTokenABI, signer);

        // Consulta o histórico de transferências de NFTs para identificar a posse atual
        const filter = studentBadge.filters.Transfer(null, userAddress);
        const logs = await studentBadge.queryFilter(filter);
        
        let foundInWallet = false;
        let foundInStake = false;
        let foundTokenId = null;

        // Itera os logs de eventos de forma reversa para encontrar o token ativo mais recente
        for (let i = logs.length - 1; i >= 0; i--) {
            const tokenId = logs[i].args.tokenId;
            try {
                const currentOwner = await studentBadge.ownerOf(tokenId);
                if (currentOwner === userAddress) {
                    foundTokenId = tokenId;
                    foundInWallet = true;
                    break;
                } else if (currentOwner.toLowerCase() === ADDRESS_STAKING.toLowerCase()) {
                    const stakeInfo = await eduStaking.stakes(tokenId);
                    if (stakeInfo.owner === userAddress) {
                        foundTokenId = tokenId;
                        foundInStake = true;
                        break;
                    }
                }
            } catch (e) {
                continue; // Ignora iteração em caso de falha na consulta de propriedade
            }
        }

        if (foundInWallet) {
            currentTokenId = foundTokenId;
            btnMint.disabled = true;
            btnStake.disabled = false;
            btnUnstake.disabled = true;
            updateStatus(`NFT (ID: ${currentTokenId}) na carteira. Pronto para Stake!`);
        } else if (foundInStake) {
            currentTokenId = foundTokenId;
            btnMint.disabled = true;
            btnStake.disabled = true;
            btnUnstake.disabled = false;
            updateStatus(`Seu NFT (ID: ${currentTokenId}) já está em Stake!`);
        } else {
            // Habilita a funcionalidade de Mint caso nenhum token seja encontrado
            btnMint.disabled = false;
            btnStake.disabled = true;
            btnUnstake.disabled = true;
        }

        await updateWalletInfo();
    } catch (error) {
        updateStatus(getFriendlyErrorMessage(error), true);
    }
}

/**
 * Executa a função de mint do NFT StudentBadge e atualiza a interface
 * com o ID do token recém-criado.
 */
async function mintNFT() {
    try {
        updateStatus("Enviando transação de Mint do NFT...");
        const mintTx = await studentBadge.mint();
        updateStatus("Aguardando confirmação do Mint (Hash: " + mintTx.hash + ")...");
        const receipt = await mintTx.wait();

        // Para obter o ID do novo token, procuramos o evento 'Transfer' no recibo da transação.
        const transferEvent = receipt.logs.find(log => {
            try {
                const parsedLog = studentBadge.interface.parseLog(log);
                return parsedLog?.name === "Transfer";
            } catch (e) {
                // Ignora logs que não pertencem à interface do StudentBadge
                return false;
            }
        });

        if (!transferEvent) {
            updateStatus("Não foi possível encontrar o evento Transfer para determinar o tokenId.", true);
            return;
        }
        currentTokenId = studentBadge.interface.parseLog(transferEvent).args.tokenId;
        updateStatus(`NFT Mintado com sucesso! Token ID: ${currentTokenId.toString()}`);
        await updateWalletInfo();
        
        // Habilita o botão de Stake, pois agora o usuário possui um NFT.
        btnStake.disabled = false;
    } catch (error) {
        updateStatus(getFriendlyErrorMessage(error), true);
    }
}

/**
 * Realiza o stake do NFT que foi mintado.
 * Processo em duas transações: Aprovação (approve) e Depósito (stake).
 */
async function stakeNFT() {
    try {
        updateStatus(`1/2: Aprovando o contrato de Staking para gerenciar o NFT #${currentTokenId}...`);
        const approveTx = await studentBadge.approve(ADDRESS_STAKING, currentTokenId);
        await approveTx.wait();

        updateStatus(`2/2: Fazendo o Stake do NFT #${currentTokenId}...`);
        const stakeTx = await eduStaking.stake(currentTokenId);
        await stakeTx.wait();
        updateStatus("Stake realizado com sucesso!");
        
        // Atualiza a interface para refletir o estado de staking
        btnStake.disabled = true;
        btnUnstake.disabled = false;
    } catch (error) {
        updateStatus(getFriendlyErrorMessage(error), true);
    }
}

/**
 * Retira o NFT do Staking e recebe as recompensas acumuladas.
 */
async function unstakeNFT() {
    try {
        updateStatus(`Sacando o NFT #${currentTokenId} e resgatando recompensas...`);
        const unstakeTx = await eduStaking.unstake(currentTokenId);
        await unstakeTx.wait();
        updateStatus("NFT sacado com sucesso! Você recebeu seus tokens EDU de recompensa.");
        
        btnStake.disabled = false;
        btnUnstake.disabled = true;
        await updateWalletInfo();
    } catch (error) {
        updateStatus(getFriendlyErrorMessage(error), true);
    }
}

/**
 * Vota na última proposta ativa na DAO (voto favorável por padrão na demonstração).
 */
async function voteDAO() {
    try {
        // Identifica e seleciona a última proposta criada
        const nextId = await eduDAO.nextProposalId();
        if (Number(nextId) === 0) {
            updateStatus("Nenhuma proposta encontrada. Crie uma primeiro!", true);
            return;
        }
        const proposalId = nextId - 1n; // A última proposta é nextId - 1

        const support = true; // Votando a favor
        updateStatus(`Votando na proposta #${proposalId} da DAO...`);
        const voteTx = await eduDAO.vote(proposalId, support);
        await voteTx.wait();
        updateStatus("Voto computado com sucesso!");
    } catch (error) {
        updateStatus(getFriendlyErrorMessage(error), true);
    }
}

/**
 * Cria uma nova proposta na DAO para que os usuários possam votar.
 */
async function createProposal() {
    try {
        updateStatus("Criando nova proposta na DAO...");
        // Gera um hash único baseado no timestamp atual para representar a descrição da proposta
        const descHash = ethers.id("Proposta de Teste " + Date.now());
        const tx = await eduDAO.createProposal(descHash);
        await tx.wait();
        updateStatus("Proposta criada com sucesso! Agora você pode votar nela.");
    } catch (error) {
        updateStatus(getFriendlyErrorMessage(error), true);
    }
}

/** @notice Conecta as funções acima aos eventos de clique dos botões na interface. */
btnConnect.addEventListener("click", connectWallet);
btnMint.addEventListener("click", mintNFT);
btnStake.addEventListener("click", stakeNFT);
btnUnstake.addEventListener("click", unstakeNFT);
btnVote.addEventListener("click", voteDAO);
btnCreateProposal.addEventListener("click", createProposal);

/** @notice Monitora mudanças de conta ou desconexão diretamente na MetaMask */
if (window.ethereum) {
    window.ethereum.on('accountsChanged', async (accounts) => {
        if (accounts.length === 0) {
            // O usuário clicou em "Desconectar" na MetaMask
            resetUI();
        } else {
            // O usuário trocou para outra conta na MetaMask
            updateStatus("Conta alterada na MetaMask. Atualizando dados...");
            await connectWallet();
        }
    });
}