# TrueCash Protocol - Full Architectural Flow

This document outlines the end-to-end technical architecture and transaction lifecycle of the TrueCash ecosystem. It is designed to serve as a high-level reference for developers, security analysts, and team members.

---

## 1. The Core Infrastructure
TrueCash is currently built on the **Binance Smart Chain (BSC)** using a **Zero-Gas Meta-Transaction Architecture (EIP-712)**. 
- **TrueCash Token (`TrueCash.sol`)**: A standard ERC-20 token with a fixed supply of 10 Billion and built-in EIP-712 permit capabilities.
- **Paymaster (`TrueCashPaymaster.sol`)**: A centralized treasury contract that executes transactions on behalf of users and distributes yields to node operators.

---

## 2. The Transaction Lifecycle (Step-by-Step)

### Step 1: The User Checkout (Frontend)
1. A customer browses a merchant storefront (e.g., `shop.truecash.cc`).
2. They click "Purchase" on an item.
3. Instead of sending a standard blockchain transaction, their MetaMask wallet prompts them to **Sign a Message** (EIP-712 Permit). 
4. The user pays **0 BNB** in gas fees. They only provide a cryptographic signature proving they authorized the transfer of TCASH.

### Step 2: The Mempool (Backend)
1. The frontend sends the user's signature, order ID, and wallet address to the Express.js backend via a `POST /api/checkout` request.
2. The backend validates the input and inserts a `PENDING` job into the PostgreSQL `mempool` database.
3. The HTTP request is kept open, waiting for the blockchain transaction to process.

### Step 3: The Relayer Nodes (Miners)
1. Decentralized "Miners" run the TrueCash Node script (`truecash_miner_node`) on their local computers.
2. These nodes constantly ping the backend's `mempool` looking for pending transactions.
3. A node picks up the pending transaction, packages the user's signature into a real blockchain transaction, and submits it to the Binance Smart Chain.
4. **The Miner pays the BSC gas fee (BNB) out of their own pocket.**

### Step 4: The Smart Contract Execution (On-Chain)
1. The transaction hits the `TrueCashPaymaster.sol` contract.
2. **Anti-Spam Check:** The contract verifies the customer holds at least 2,000 TCASH. If not, the transaction reverts.
3. **Execution:** The contract uses the signature to instantly transfer the purchase amount (e.g., 15 TCASH) directly from the Customer to the Merchant.
4. **Miner Reward:** The contract automatically withdraws a fixed **1 TCASH** from the Paymaster Treasury and sends it to the Miner to reimburse them for the BNB gas they spent.

### Step 5: The Confirmation (Resolution)
1. The backend detects that the transaction was successfully mined on the blockchain.
2. It updates the PostgreSQL database status to `COMPLETED`.
3. The pending HTTP request resolves, and the customer's browser displays a "Success" modal with the final on-chain Transaction Hash.

---

## 3. The Phase 3 Evolution (The AppChain)
The current architecture (Phase 1) is a strategic bridge. It uses the Paymaster Treasury to subsidize BNB gas fees to aggressively acquire users and build a merchant network through a frictionless "zero-gas" experience.

Once the network reaches critical mass (Phase 3), the protocol will migrate from Binance Smart Chain to a proprietary **TrueCash L1 AppChain** (e.g., via Polygon CDK or Cosmos SDK). 
On the native L1 network, external gas fees are eliminated by design, ending the Treasury's reliance on BNB and fully decentralizing the consensus mechanism.
