---
title: "Xochi: Why We're Building ETH's Friendly Dark Pool"
date: "2026-04-07"
description: "Private execution on Ethereum. No MEV. No footprint. Built by the axolotls at axol.io."
author: "DROO AMOR"
tags: ["ethereum", "privacy", "defi", "xochi", "zk", "web3", "hedge"]
slug: "xochi-ethereum-dark-pool"
pattern_style: "glass_cube"
---

<img src="/images/blog/Les_Poissons_rouges,_par_Henri_Matisse.webp" alt="Les Poissons rouges (The Goldfish) by Henri Matisse (1912) - Goldfish in a glass bowl, completely visible, completely exposed" loading="lazy" class="post-image-statement" />

<p class="post-caption"><em>Les Poissons rouges</em> (1912) - Henri Matisse. Pushkin Museum, Moscow.</p>

> Private DEX on Ethereum. Zero-knowledge compliance proofs. Solver live on five chains, ~2s settlement. Cofounded by ex-DOJ/FBI financial intelligence. Raising to capitalize a working system. [whitepaper](https://xochi.fi/whitepaper) | [appendix](https://xochi.fi/appendix) | [EIP draft](https://github.com/xochi-fi/erc-xochi-zkp)

# The fish bowl problem

Cortazar wrote about a man who stared at axolotls through aquarium glass until he realized he'd become one. The glass never moved. His understanding of which side he was on did.

Every transaction you've made on Ethereum is behind glass like that. Visible, permanent, indexed. You might not have noticed which side you're on yet.

Say you're running a DAO treasury. You need to convert $2M USDC to EURC for European contributors. The second you sign that transaction, every MEV bot on Ethereum sees it. They front-run you, sandwich you, and by the time your swap settles you've lost tens of thousands to actors who contribute nothing.

We've talked to protocol treasuries that got sandwiched on governance-approved swaps and had to explain the slippage to token holders in forum posts. Whales who lost five figures rebalancing a portfolio across a few swaps because their position was visible the whole time. A market maker who told us he can't quote competitive spreads on-chain because his inventory is public -- every counterparty knows his exposure before he does.

Some manage protocol treasuries and can't rotate without the whole market front-running the move. Some are born somewhere hard and can't move money without a government deciding they shouldn't. Different stakes. Same glass.

Your spawn point -- where you're born, what passport you hold, what financial system you inherit -- shouldn't determine whether you get privacy. But it does.

Xochi is what happens when you spend five years running bare-metal blockchain infrastructure -- validators, solvers, an Aztec sequencer -- and point all of it at one problem: private execution on Ethereum.

---

## What Xochi does

You sign an intent describing the trade you want. Solvers compete to fill it. Intents stay off-chain until they land on stealth smart accounts or Aztec L2.

Stealth smart accounts are worth explaining, because they're the thing that makes "private on Ethereum" mean something real. Normally, when someone sends you crypto, it goes to your public address -- visible forever, linked to every other transaction you've ever made. A stealth account is a one-time address derived from your public key that only you can unlock. Think of it as a P.O. box that nobody knows belongs to you, except it's also a full smart contract wallet. You can claim the funds without paying gas (a paymaster covers it), so even the claiming transaction doesn't link back to you. The standards are ERC-5564 for the address derivation and ERC-4337 for the smart wallet part.

```bash
Intent Submitted -> Riddler Routes -> Xochi ZKP -> Shielded Settlement
(private intent)    (solver network)  (compliance)    (stealth smart accounts)
```

Everything stays on Ethereum. You trade directly -- no wrapping assets in privacy pools, no swapping on a public DEX where the bots can see it.

Xochi hides the trade itself. Execution, amounts, counterparties.

Liquidity comes from solvers who hold inventory and fill peer-to-peer. Riddler maintains its own book; overflow goes through private RFQ channels with market makers who never see the original intent. The trade never touches a public pool.

Other solvers can join permissionlessly. More solvers, tighter spreads, more volume -- that's the flywheel thesis. Riddler is the only active solver today. The network effects are still ahead of us.

Privacy ships by default at Standard tier. Open to everyone, any size.

Using it is simple. Connect your wallet at xochi.fi, pick a pair, enter an amount. You sign one transaction -- the intent. Riddler fills it. Funds land in a stealth smart account. You claim them with one click, gasless. The whole flow takes about as long as a Uniswap swap, except nobody saw it happen.

Without MEV protection, sandwich bots extract 0.1-5%+ per trade ([EigenPhi via Cointelegraph Research, Dec 2025](https://cointelegraph.com/research/exclusive-data-from-eigenphi-reveals-that-sandwich-attacks-on-ethereum-have-waned)). On a $100K swap, that's anywhere from $100 to $5,000 gone before LP fees. In March 2025, one trader [lost $215,000 on a single stablecoin swap](https://cointelegraph.com/research/exclusive-data-from-eigenphi-reveals-that-sandwich-attacks-on-ethereum-have-waned) on Uniswap V3 when a bot drained pool liquidity milliseconds before execution. On Xochi, MEV extraction is zero -- the trade never touches a public pool. You pay solver spread: 0.15-0.30% depending on trust tier.

---

## Compliance without confession

Privacy in crypto has always forced a bad choice. Full transparency (Uniswap, CoW Protocol) keeps you compliant but exposes everything. Full privacy (Tornado Cash) gets sanctioned. Pick a side.

Xochi ZKP -- zero-knowledge compliance proofs -- proves a trade is AML/sanctions-compliant without revealing the trade itself. The regulator verifies a proof. They never see the data.

| Regulatory Requirement | What the ZK Proof Says     | What Stays Hidden   |
| ---------------------- | -------------------------- | ------------------- |
| Large value report     | "Amount exceeds threshold" | Exact amount        |
| Source of funds        | "Valid attestation exists" | Fund details        |
| Counterparty screening | "Not on sanctions list"    | Identity            |
| Anti-structuring       | "Pattern NOT detected"     | Transaction history |

Six proof types, formalized as an EIP draft with Solidity interfaces and Noir circuits. The reference implementation is CC0 public domain. Pre-audit, but the math is there to inspect.

The oracle synthesizes across multiple providers -- humanity proofs (Worldcoin, Idena), identity (ZKPassport, Coinbase), compliance screening (Chainalysis) -- to produce a composite trust signal. One provider saying "clean" is a data point. Three independent providers across different categories is a conviction.

The legal grounding is where I lose sleep. GDPR's data minimization principle (Art. 5(1)(c)) says process only what's necessary -- a ZK proof is minimal disclosure by definition, so the logic feels solid there. VARA's January 2026 anonymity ban defines anonymity-enhanced crypto as assets lacking "mitigating technologies" for traceability. Xochi ZKP is designed to be exactly that mechanism -- traceability without exposing transaction data.

But nobody has tried this argument in front of a regulator. The law's own language supports us. The cryptographic logic is sound. And I still can't tell you whether a compliance officer in Dubai will look at a ZK proof and say "yes, this counts." It's an untested legal theory. We believe the reasoning is right. We also know that being right and being accepted aren't the same thing.

The proofs work retroactively. If OFAC sanctions an address three months after a trade, the Xochi ZKP proof from the original transaction still exists -- proving the composite signal was clear at the time. Proof that screening was clean at time of trade, on-chain and auditable, when enforcement comes asking.

Our compliance cofounders are ex-DOJ Financial Intelligence and FBI AML. They've filed SARs and built the frameworks we're now trying to improve with better cryptography. That matters more than any whitepaper argument.

---

<img src="/images/blog/Piranesi02.webp" alt="The Pier with Chains (Plate XVI) by Giovanni Battista Piranesi (1761) - Vast prison architecture where every figure is exposed and observable" loading="lazy" class="post-image-float-right" />

## The field

Most projects that claim privacy are pools -- you shield your wallet, swap on a public DEX, shield the output. The wallet is hidden, but the trade is still visible. MEV bots care about what you're swapping, not who you are.

| Project             | Privacy                          | Compliance         | Mempool | Execution | Settlement |
| ------------------- | -------------------------------- | ------------------ | ------- | --------- | ---------- |
| **Xochi**           | Stealth smart accounts, Aztec ZK | Graduated + ZKP    | Private | Private   | Private    |
| Renegade (Arbitrum) | MPC + ZKPs, dark pool matching   | None (exploring)   | Private | Private   | Private    |
| Railgun             | zkSNARKs, shielded pool          | View keys          | --      | --        | Private    |
| Penumbra            | ZK, shielded chain (Cosmos)      | None               | Private | Private   | Private    |
| Hinkal              | zkSNARKs, shared shield          | KYC-gated pools    | --      | Partial   | Private    |
| Labyrinth           | zkSNARKs, shielded pool          | De-anon on request | --      | Partial   | Private    |
| 0xbow               | zkSNARKs, deposit source proof   | Set membership      | --      | --        | Private    |
| CoW Swap            | MEV protection only              | None               | Private | --        | --         |
| UniswapX            | MEV protection only              | None               | Private | --        | --         |

0xbow (Privacy Pools) has been live on mainnet since March 2025 and validated the core thesis: ZK proofs can handle compliance without revealing data. But set membership -- "my deposit isn't in the sanctioned set" -- is one dimension of compliance. Regulators need more: risk scores, structuring patterns, KYC validity, sanctions screening across jurisdictions. 0xbow covers one of Xochi ZKP's six proof types. We cover the rest.

Renegade is the closest architecturally -- real dark pool matching on Arbitrum. No compliance path, which locks out institutional capital. Penumbra has strong privacy but lives on Cosmos. Railgun hides your wallet; trades still execute on public DEXs. Hinkal and Labyrinth bet on reactive de-anonymization, meaning "we'll reveal your data if asked."

We'd rather prove compliance cryptographically than store raw transaction data that can be exfiltrated or subpoenaed in bulk. The ZK proof itself exists on-chain. The screening record exists. What doesn't exist is a centralized database of counterparty details waiting to be breached.

CoW Swap and UniswapX do good MEV protection. That's order protection. The trade itself is still exposed.

The field is getting wider. Chainlink shipped Confidential Compute with dark pool infrastructure tooling -- CRE for private smart contracts, CCIP for cross-chain settlement, ACE for automated compliance. COTI launched garbled circuits as an Ethereum L2, a different cryptographic primitive for the same problem. Hinkal runs shielded DeFi positions across 200+ chains with an institutional KYC layer. NEAR launched "Confidential Intents" in March 2026 -- same intent-based privacy concept.

These are complementary approaches. Privacy is infrastructure, not ideology, and the design space is big enough that composition beats competition. What separates Xochi: we hide the trade execution itself, the ZK compliance covers six proof types instead of one, and we have cofounders who've been on the other side of enforcement.

---

## The glass cube

<img src="/images/blog/holy-family-with-a-curtain-1646.webp" alt="The Holy Family with a Curtain by Rembrandt (1646) - A trompe-l'oeil curtain half-drawn, revealing a domestic scene. Privacy as partial opacity." loading="lazy" class="post-image-float-left" />

Privacy is a spectrum. We think of it as a glass cube -- six levels, crystal clear to solid.

Two axes. Your trust score (from attestations) determines the base fee and which privacy levels you can access. Your chosen privacy level determines how much data is retained. They're independent: a high-trust user can choose Standard if they don't need deeper privacy, and a new user gets Standard by default.

Everyone starts at Standard: wallet and amounts hidden, open to anyone. Private by default. Below Standard, Open and Public tiers trade with full visibility at reduced fees -- Open actually pays you -0.02% plus analytics. Loss leaders, but real products.

Above Standard, attestations unlock the deeper tiers. A Worldcoin proof and a Coinbase attestation gets you to Shielded in minutes -- stealth smart accounts, gasless claiming, lower fees, MEV rebates. Stack attestations across categories (humanity, identity, reputation, compliance) and the cube gets more opaque. Private and Sovereign require Aztec L2 for execution-level ZK proofs. Sovereign is zero data retention, 0.15% fee, 25% MEV rebate.

Diminishing returns prevent gaming. First attestation in a category earns full points, the second a quarter, the third barely registers. Depth across categories matters more than stacking one.

What works today: intent privacy, solver execution, stealth smart account settlement (ERC-5564/6538 + ERC-4337 account abstraction, gasless claiming via paymaster). Order, counterparty, and receiving address are hidden even at Standard tier. Aztec adds execution-level ZK proofs for the deeper tiers.

---

## How Riddler fills large orders

A dark pool that can't fill large orders isn't a dark pool. Here's how Riddler handles size.

Riddler checks its own inventory first -- available balance minus safety buffers (10% on small trades, scaling down to 2% above $100K, with a $1K minimum reserve). If inventory can't cover the full order, it routes through external sources in priority order: DeFi aggregators, native bridges, CCTP, Hop, Everclear, LiFi, Across, and CEX withdrawal as a last resort. If all sources combined can't fill the order within a 30-second quote window, it's rejected outright. No partial fills, no queuing. You get a complete fill or you get nothing.

The routing logic is roughly 500 lines of Elixir spanning eight adapters. It's the most battle-tested piece of the codebase.

Your intent never hits the mempool -- that privacy is absolute. But when Riddler sources from DEX pools or bridges to fill a large order, those legs are visible on-chain. A sophisticated observer can correlate the timing. Three things mitigate this: Everclear netting cancels opposing flows with no on-chain trace for the netted portion (80%+ savings when bidirectional flow exists), CEX withdrawals leave no on-chain liquidity footprint, and flash loans (planned) will make fills atomic in a single transaction with no separate sourcing leg. For trades above $1M, some leakage through venue-side sourcing is unavoidable today without deeper protocol liquidity.

Settlement currently goes to a single stealth smart account per trade. Multi-account splitting -- derive N stealth keys from the same meta-address, each receiving a fraction -- is on the Q4 roadmap for trades above $100K. More accounts means more privacy but higher gas.

TWAP and iceberg orders aren't live yet either. Riddler's bridge router splits across routes internally when a single route lacks capacity, but there's no time-slicing. DCA, TWAP, and iceberg are Q3 2026. The architecture supports it: submit N smaller intents over a window. The anti-structuring circuit in the compliance oracle handles up to 16 transactions per proof, so TWAP slices above the structuring floor don't trigger false positives.

---

## Why now

<img src="/images/blog/Piranesi9c.webp" alt="The Drawbridge (Plate VII) by Giovanni Battista Piranesi (1761) - Figures exposed on walkways in a vast imaginary prison, everything visible" loading="lazy" class="post-image-statement" />

<p class="post-caption"><em>Le Carceri d'Invenzione, Plate VII: The Drawbridge</em> (1761) - Giovanni Battista Piranesi</p>

$289 million in sandwich attacks alone on Ethereum in 2025 -- 51% of the $562M total MEV volume ([EigenPhi via Cointelegraph Research](https://cointelegraph.com/research/exclusive-data-from-eigenphi-reveals-that-sandwich-attacks-on-ethereum-have-waned)). Between 60,000 and 90,000 sandwich attacks per month, and that's with 80% of transactions already using private RPCs to dodge the public mempool. ESMA's July 2025 risk analysis measured 526,000 ETH (>$1.1B) in realized MEV from the Merge through mid-2024, with ~90% of validators running MEV-Boost. Flashbots relay data puts cumulative extraction past $1.8B by mid-2025.

Ethereum knows this. FOCIL (EIP-7805) is confirmed for the Hegota hard fork, late 2026. EIP-8105 (Universal Enshrined Encrypted Mempool) has been submitted for inclusion alongside it. Researchers are calling ePBS + FOCIL + encrypted mempools the "[Holy Trinity of Censorship Resistance](https://etherworld.co/hegota-should-complete-the-holy-trinity-of-censorship-resistance/)." Vitalik's been writing about "sanctuary technologies" since late 2025. The direction is right. The timeline means users bleed for another year.

The regulatory picture shifted too. The Tornado Cash sanctions were lifted. Zcash rallied over 1,000% with its shielded pool supply tripling. Railgun processed $1.6B in shielded transactions. Paxos partnered with Aleo to launch a compliant private stablecoin. Grayscale's [2026 Digital Asset Outlook](https://research.grayscale.com/reports/2026-digital-asset-outlook-dawn-of-the-institutional-era) calls privacy "prerequisite for real-world liquidity." The market decided privacy is infrastructure, not ideology.

MiCA gave USDC and EURC legal clarity in the EU, with a hard deadline -- stablecoin issuers have until July 2026 to comply or face mandatory delisting. Tether's USDT is already gone from EU exchanges. VARA's anonymity ban scopes itself around assets lacking traceability mechanisms -- Xochi ZKP enters that conversation.

Demand exists. Off-exchange venues handle the majority of institutional equity volume in the US. The BIS counts $4 trillion/day in OTC FX swaps (2025 Triennial). Institutions figured out decades ago that broadcasting trades is a losing strategy.

A fund rotating $10M on a public DEX announces its position to the market. On Xochi, the trade is invisible until settlement.

Software agents are entering this picture too. Headless agents running unattended -- monitoring positions, rebalancing portfolios, executing trades on behalf of DAOs -- need private execution even more than humans do. An agent broadcasting its strategy to the mempool is a sitting target. Raxol, our OTP-native agent runtime, ships with Xochi payment rails built in. Agents can submit intents programmatically and settle through stealth smart accounts without human intervention. That's a market that barely exists yet, but when agents start managing real capital, they'll need the same privacy that institutions need.

Q4 roadmap starts with EURC and GYEN (GMO Trust's regulated yen stablecoin) -- stablecoin FX pairs with private execution on Ethereum. The MiCA deadline makes this urgent.

---

## What's running

Riddler fills intents on mainnet across every advertised route -- live B2B integration, real tokens, real settlement. ~2s typical, <6s P95. Infrastructure is production on five chains: solver, stealth accounts, trust scoring, gasless swaps, cross-chain routing. The system works. What it needs is capital to scale liquidity beyond B2B into a public product.

We're raising to do three things: capitalize Riddler's inventory so the solver can fill institutional-sized orders, complete the Q2 smart contract audit (mandatory before any serious volume), and deploy the Xochi ZKP Oracle on testnet. That's the critical path from working infrastructure to a product that institutions can actually use. Every dollar of solver inventory is a dollar of liquidity that earns spread on every trade it fills -- this isn't a runway raise, it's capitalizing a revenue-generating system.

| What                   | Status                                                     |
| ---------------------- | ---------------------------------------------------------- |
| Riddler Solver         | Live B2B, ~2s settlement, <6s P95                           |
| Chains                 | Ethereum, Optimism, Base, Arbitrum, Polygon                |
| Integrations           | Across, Li.Fi (ERC-7683), Relay.link, CCTP                 |
| Stealth Smart Accounts | Live (ERC-5564 + ERC-4337, gasless claiming via paymaster) |
| Trust Scoring          | Live, 5 trust tiers x 6 privacy levels, attestation-based  |
| Aztec Sequencer        | Operating                                                  |
| Gasless Swaps          | Live (PERMIT2/EIP-3009)                                    |
| x402 Micropayments     | Integrated (HTTP 402-based payment protocol)               |
| Limit Orders           | Live                                                       |

Q2: smart contract audit, Xochi ZKP Oracle testnet, Aztec L2 private tiers. Q3: Xochi ZKP proofs on mainnet. Q4: FX pairs -- EURC, GYEN.

The Q2 audit is mandatory. A dark pool needs audited contracts.

---

## Why this is hard to copy

You can fork a smart contract. You can't fork five years of node operations, solver integration across eight bridge adapters, and regulatory groundwork in four jurisdictions. The infrastructure layer -- bare-metal validators, sequencers, the 500-line bridge router -- took years to build and isn't in the contracts.

Trust scores are protocol-specific. Leave Xochi and you start at zero. Attestations you've stacked, the trade history that earned your tier, the MEV rebates -- all tied to the protocol. Switching costs compound over time.

The Xochi ZKP spec is CC0 on purpose. Anyone can implement it. But the oracle's adaptive provider weighting, the enforcement feedback loop, and the regulatory relationships behind them aren't in the circuits. The math is open. The operational layer around it isn't.

---

## Revenue model

Four sources, all live at Standard tier and above:

- **Trading fees**: 0.10-0.30% base depending on trust tier
- **Privacy premium**: +0.02-0.20% for stealth/shielded settlement levels
- **Intent surplus**: 15% of price improvement when Riddler fills below the quoted spread
- **Solver margin**: Riddler captures the spread between fill price and settlement

Every non-Open, non-Public swap is cash-positive. Intent surplus scales linearly with volume and is additive to fees. The protocol owns Riddler, so solver margin accrues to the protocol -- this is vertical integration by design. External solvers join later, after we've established flow and a defensible position.

Capitalization plan has three phases: VC raise capitalizes Riddler directly (immediate -- every dollar earns spread from day one), flash loan integration multiplies effective capacity for same-chain fills without custody risk (Q3), and LP vaults let external capital deposit into Riddler-managed pools with a share of solver margin (Q4). Each phase reduces the protocol's dependence on the previous one.

---

## Jurisdiction strategy

UAE first. VARA's sandbox program is the entry point -- the anonymity ban's own language carves out assets with "mitigating technologies for traceability," and Xochi ZKP is designed to be exactly that. We're making the argument with working code.

Singapore second (MAS). EU third -- MiCA gave stablecoins legal clarity, and our Q4 FX pairs (EURC, GYEN) align with that timeline. US last, because the regulatory landscape is the least defined and the risk/reward is worst for a first mover.

Our compliance lead has worked inside two of these regulatory systems. That's the difference between filing an application and understanding how the people reading it think.

---

## The team

Four of us building together since 2021:

- **Drew** (Protocol Director) -- R&D Engineer at General Dynamics, Protocol Specialist at Lido, Node Ops at Blockdaemon. MechE/ElecE with defense R&D patents.
- **Jer** (Blockchain Engineer) -- APAC Node Ops Lead at Blockdaemon, Analyst at Deloitte, Forex Trader at Silab Luchre Capital. The FX trading background is directly relevant to Q4's EURC/GYEN pairs.
- **Bloo** (Compliance) -- FBI-DOJ AML/Terrorist Financing, DOJ Financial Intelligence, U.S. Army Intelligence (Pentagon), Compliance & Legal at Blockdaemon. Filed SARs and built the frameworks we're now improving with better cryptography.
- **V** (DevSecOps) -- Immunefi whitehat, UI Lead at Lido, Founder at here.build.

Bug bounty is live on Immunefi: up to $500K for critical vulnerabilities. A dark pool that doesn't pay for security audits isn't serious about security.

---

## What could go wrong

Xochi ZKP is novel. Zero-knowledge compliance proofs are untested with regulators. If VARA says no, we fall back to delegated compliance -- licensed solvers handle jurisdiction-specific requirements. The privacy still works. The ZK compliance is a bet, and we're upfront about that.

Aztec's L2 timeline could slip. Our privacy tiers degrade gracefully: L1 stealth smart accounts work today for Trusted and above, and the lower tiers don't depend on Aztec at all. Solver bootstrap is a real risk too. Riddler's infrastructure is proven but undercapitalized. The raise fixes that. Network effects are a growth story.

Smart contract risk is low-probability but critical-impact. A dark pool holding solver capital in contracts that haven't been audited yet is a real exposure. That's why the Q2 audit is a hard gate, not a nice-to-have, and why the Immunefi bounty is live now -- before the audit, not after.

And someone will use Xochi for something they shouldn't. That's not a question of if. When it happens, the ZKP proof trail shows exactly which screening providers cleared the bad actor and where the composite signal had a blind spot. Provider weights get tuned. The oracle learns. That's more accountability than traditional compliance offers -- when a SAR gets filed after a wire transfer clears, nobody goes back and audits which compliance officer approved it and why. We do, automatically, because the math is on-chain.

---

No on-chain venue is both private and compliant. That's either a gap in the market or a sign that it can't be done. I think about both possibilities more than is probably healthy. We have the solver, the infrastructure, and a team that has spent time on both sides of the enforcement table. The bet is that regulators will accept cryptographic compliance. We think the math is on our side. We'll find out.

_Xochi is ETH's Friendly Dark Pool, built by the axolotls at [axol.io](https://axol.io). Trade at [xochi.fi](https://xochi.fi)._
