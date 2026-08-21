# TrueCash Protocol - Security & Architecture Audit

## 1. Presale Contract & Withdrawal Controls
Blockaid and other automated security scanners may flag the `TrueCashPresale.sol` contract due to the presence of the `withdrawNative()` function, which allows the contract owner to withdraw raised BNB.

**Justification for Centralized Withdrawal:**
TrueCash operates a **Zero-Gas Meta-Transaction Network**. In order to allow users to spend TCASH without paying BNB gas fees, the protocol utilizes a centralized Paymaster contract (`TrueCashPaymaster.sol`). The Paymaster must hold a constant reserve of native BNB to pay the network fees on behalf of the users. 
The BNB raised during the initial distribution (presale) is manually swept by the Treasury and deposited directly into the Paymaster contract to subsidize these zero-gas transactions. It is not an investment scam; it is a required architectural design to fund the relayer network.

## 2. Tokenomics & Distribution
- **Total Supply:** 10,000,000,000 TCASH
- **Presale Allocation:** 20%
- **Miner/Relayer Reward Pool:** 50% (Locked in Paymaster to reward node operators)
- **Marketplace Liquidity:** 20%
- **Team & Development:** 10% (Vested)

## 3. Yield & Miner Rewards
Node operators (Miners) earn a variable yield in TCASH for processing zero-gas transactions. This yield is strictly derived from the protocol's Treasury and network activity. TrueCash makes no guarantees of fixed APY or fiat value appreciation.
