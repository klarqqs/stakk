# Stellar Integration – Stakk USDC Savings App

> Technical documentation for Stellar Community Fund (SCF) submissions.  
> Describes how Stakk uses the Stellar network and USDC.

---

## 1. Overview

Stakk is a mobile-first USDC savings app targeting the Nigerian market. **Stellar is central to the product**: all user funds are held as USDC on Stellar, and the app integrates with Stellar for custody, transfers, and yield.

---

## 2. Stellar Use Cases

| Use Case | Stellar Role | Implementation |
|----------|--------------|-----------------|
| **USDC custody** | Users hold USDC (Stellar native asset) in Stakk-managed wallets | Backend creates / manages Stellar accounts; mobile shows balance |
| **Fund wallet** | Deposit via NGN virtual account (converted to USDC) or direct Stellar transfer | Backend anchors NGN→USDC; users can fund via Stellar address |
| **P2P transfers** | Send USDC between Stakk users | Backend issues Stellar payment operations |
| **Withdraw to Stellar** | Send USDC to any Stellar address (e.g. Lobstr, Binance) | Backend issues Stellar payment to external address |
| **Blend yield** | Earn APY on idle USDC via Blend Protocol | Backend interacts with Blend on Stellar |
| **Transparency** | Verify reserves on-chain | Treasury address visible on Stellar Expert |

---

## 3. Technical Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         STAKK MOBILE APP (Flutter)                        │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │
                                  │ HTTPS (REST API)
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         STAKK BACKEND (Node.js)                          │
│  • Auth, user management                                                 │
│  • Wallet balance (aggregated from Stellar)                              │
│  • NGN virtual account (anchor)                                         │
│  • Bill payments (NGN)                                                  │
│  • Stellar operation orchestration                                      │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                    ▼             ▼             ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  STELLAR NETWORK │ │  BLEND PROTOCOL  │ │  ANCHOR (NGN)     │
│  • USDC custody  │ │  • Yield on USDC  │ │  • NGN on/off     │
│  • Payments      │ │  • Supply/withdraw│ │  • Virtual accts  │
│  • Stellar addrs │ │                  │ │                  │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

---

## 4. Data Flow – Key Operations

### 4.1 Balance & Stellar Address

- **API:** `GET /wallet/balance`
- **Response:** `{ usdc, stellar_address }`
- **Stellar:** Balance is derived from the user’s Stellar account(s). `stellar_address` is a G... address for receiving USDC.

### 4.2 Fund via Stellar (USDC Wallet)

- User copies Stellar address from the app.
- Sends USDC from any Stellar wallet (Lobstr, Binance, etc.) to that address.
- Backend detects incoming payment and updates user balance.
- **Network:** Stellar (USDC asset).

### 4.3 Send to Stellar Address

- **API:** `POST /wallet/withdraw-usdc` with `{ stellarAddress, amountUSDC }`
- **Stellar:** Backend creates a payment operation from the user’s wallet to the recipient G... address.
- **Network:** Stellar.

### 4.4 P2P Send (Stakk User → Stakk User)

- **API:** `POST /p2p/send` with `{ receiver, amount, note }`
- **Stellar:** Backend moves USDC between internal Stellar accounts (or uses path payments).
- **Network:** Stellar.

### 4.5 Blend (Earn APY)

- **API:** `GET /blend/earnings`, `POST /blend/enable`, `POST /blend/disable`
- **Stellar:** Backend supplies/withdraws USDC to/from Blend Protocol.
- **Network:** Stellar (Blend smart contracts).

---

## 5. Mobile App – Stellar Touchpoints

| Screen / Flow | Stellar Integration |
|---------------|---------------------|
| **Home** | Balance, Blend earnings, Fund/Send CTAs |
| **Fund → USDC Wallet** | Displays Stellar address + QR; instructs to use Stellar network |
| **Send → USDC Wallet** | Input: Stellar address (G...); backend sends USDC on Stellar |
| **Invest (Blend)** | Shows APY; enable/disable supplies USDC to Blend on Stellar |
| **Transparency** | Opens Stellar Expert for treasury address |
| **Referrals** | Rewards paid in USDC (Stellar) |

---

## 6. Why Stellar

- **USDC native:** USDC is issued on Stellar; low fees and fast settlement.
- **Blend Protocol:** Enables yield on idle USDC without leaving Stellar.
- **Anchors:** NGN on/off ramp via virtual account anchor.
- **Transparency:** Public ledger for reserve verification.
- **Ecosystem:** Stellar’s focus on payments and emerging markets aligns with Stakk’s Nigerian target.

---

## 7. Transparency & Reserves

- Treasury address is shown in the app.
- Users can verify on [Stellar Expert](https://stellar.expert).
- Reserves should be documented (e.g. attestation, audit) per Stellar ecosystem standards.

---

## 8. Future – Soroban

- **Current:** Stellar Classic operations (payments, etc.).
- **Potential:** Soroban smart contracts for savings goals, escrow, or automated strategies.
- **Open source:** Any Soroban contracts would be open-sourced per SCF expectations.

---

*Document version: 1.0 | Stakk | For SCF submission*
