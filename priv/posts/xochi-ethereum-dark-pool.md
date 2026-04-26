---
title: "Xochi: Why We're Building ETH's Friendly Dark Pool"
date: "2026-04-25"
description: "Private execution on Ethereum. No MEV. No footprint. Built by the axolotls at axol.io."
author: "DROO AMOR"
tags: ["ethereum", "privacy", "defi", "xochi", "zk", "web3", "hedge"]
slug: "xochi-ethereum-dark-pool"
pattern_style: "glass_cube"
---

<img src="/images/blog/Les_Poissons_rouges,_par_Henri_Matisse.webp" alt="Les Poissons rouges (The Goldfish) by Henri Matisse (1912) - Goldfish in a glass bowl, completely visible, completely exposed" loading="lazy" class="post-image-statement" />

<p class="post-caption"><em>Les Poissons rouges</em> (1912) - Henri Matisse. Pushkin Museum, Moscow.</p>

> Private DEX on Ethereum. Zero-knowledge compliance proofs. Solver live on five chains, ~2s settlement, P95 ~<6s. Cofounded by ex-DOJ/FBI financial intelligence. Raising to capitalize a working system.
>
> [whitepaper](https://xochi.fi/whitepaper) | [appendix](https://xochi.fi/appendix) | [EIP draft](https://github.com/xochi-fi/erc-xochi-zkp)

## The fish bowl problem

Cortazar wrote about a man who stared at axolotls through aquarium glass until he realized he'd become one. The glass never moved. His understanding of which side he was on did.

Every transaction you've made on Ethereum is behind glass like that. Visible, permanent, indexed. You might not have noticed which side you're on yet.

Say you're running a DAO treasury. You need to convert $2M USDC to EURC for European contributors. The second you sign that transaction, every MEV bot on Ethereum sees it. They front-run you, sandwich you, and by the time your swap settles you've lost tens of thousands to actors who contribute nothing.

Gitcoin lost $10K+ on a 1,000 ETH treasury swap to a sandwich bot. Rarible lost $8K on a similar trade. These aren't edge cases. In March 2026, someone [swapped $50.4M USDT for AAVE on CoW/Sushi and received $36,000 worth of tokens](https://www.theblock.co/post/393621/aave-and-cow-swap-publish-dueling-post-mortems-after-50-million-defi-swap-disaster). Titan Builder extracted ~$34M via sandwich. Aave and CoW published dueling post-mortems. A market maker told us,

> "I can't quote competitive spreads on-chain. My inventory is public. Every counterparty knows my exposure before I do."

Some manage protocol treasuries and can't rotate without the whole market front-running the move. Some are born somewhere hard and can't move money without a government deciding they shouldn't. Different stakes. Same glass.

Your spawn point (where you're born, what passport you hold, what financial system you inherit) shouldn't determine whether you get privacy. But it does.

Xochi is what happens when you spend five years running bare-metal blockchain infrastructure (validators, solvers, an Aztec sequencer) and point all of it at one problem: private execution on Ethereum.

---

## What could go wrong

<div class="post-image-float-left">
<img src="/images/blog/the-wrestle-of-jacob-1855.webp" alt="Jacob Wrestling with the Angel by Gustave Dore (1855) - A man and an angel locked in a night-long struggle by a riverbank, the man marked by the encounter, neither letting go" loading="lazy" />
<p class="post-caption"><em>Jacob Wrestling with the Angel</em> (1855) - Gustave Dore.</p>
</div>

I want to get this out of the way early, because most projects bury their risks at the bottom and hope you don't scroll that far.

Xochi ZKP is novel. Zero-knowledge compliance proofs are untested with regulators. If VARA says no, we fall back to delegated compliance where licensed solvers handle jurisdiction-specific requirements. The privacy still works.
The ZK compliance is a bet, and we're upfront about that.

Aztec Alpha Network is live (v4.x) and pxe-bridge is deployed against it. The network is explicitly experimental: a critical proving-system bug was disclosed in March, state isn't migrated between alpha releases, and v5 with security fixes targets July 2026. Stability and fee economics at scale are unproven. Our privacy tiers degrade gracefully. L1 stealth smart accounts work today for Trusted and above, and the lower tiers don't depend on Aztec at all. Solver bootstrap is a separate risk. Riddler's infrastructure is proven but undercapitalized. The raise fixes that. Network effects are a growth story.

Smart contract risk is low-probability but critical-impact. A dark pool holding solver capital in contracts that haven't been audited yet is a real exposure. That's why the Q2 audit is a hard gate, not a nice-to-have, and why the Immunefi bounty is live now, before the audit, not after.

And someone will use Xochi for something they shouldn't. That will happen. When it does, the proof trail is on-chain. Which providers cleared the bad actor, where the signal broke down, what the composite score was and a clear pattern of how it was spoofed.
Traditional compliance simply cannot provide that. When a SAR gets filed after a wire transfer clears, nobody audits which compliance officer approved it and why, then tightens the holes in their protocol. We do, programmatically.

Now. What we actually built.

---

## What Xochi does

<div class="post-image-float-right">
<img src="/images/blog/Wright_of_Derby_The_Orrery.webp" alt="A Philosopher Lecturing on the Orrery by Joseph Wright of Derby (c. 1766) - A group gathered around a mechanical model of the solar system, faces lit by an unseen central lamp at its core" loading="lazy" />
<p class="post-caption"><em>A Philosopher Lecturing on the Orrery</em> (c. 1766) - Joseph Wright of Derby. Derby Museum and Art Gallery.</p>
</div>

1. You sign an intent describing the trade you want.
2. Solvers compete to fill it. Intents stay off-chain.
3. Settlement lands on stealth smart accounts or Aztec L2. Nobody saw it happen.

Stealth smart accounts are worth explaining, because they're the thing that makes "private on Ethereum" mean something real.
Normally, when someone sends you crypto, it goes to your public address, visible forever, linked to every other transaction you've ever made. A stealth account is a one-time address derived from your public key that only you can unlock.
Think of a stealth account as the side of the glass nobody can see through. The funds sit on a one-time address derived from your public key; only you hold the math that opens it. You can claim without paying gas (a paymaster covers it), so even the claiming transaction doesn't link back to you.
The enabling standards are [ERC-5564](https://eips.ethereum.org/EIPS/eip-5564) for the address derivation and [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) for the smart wallet part.

```bash
Intent Submitted -> Riddler Routes -> Xochi ZKP -> Shielded Settlement
(private intent)    (solver network)  (compliance)    (L1 stealth | L2 Aztec via pxe-bridge)
```

Xochi hides the trade itself. This is called Private Execution-- for amounts and counterparties. Liquidity comes from solvers who hold inventory and fill peer-to-peer. Riddler maintains its own book; overflow goes through private RFQ channels with market makers who never see the original intent. The trade never touches a public pool.

Sandwich bots extract 0.1-5%+ per trade on average ([EigenPhi via Cointelegraph Research, Dec 2025](https://cointelegraph.com/research/exclusive-data-from-eigenphi-reveals-that-sandwich-attacks-on-ethereum-have-waned)). On a $100K swap, that's $100 to $5,000 gone before LP fees ever touch the trade.

On Xochi, MEV extraction is zero. The trade was never visible to extract from. You pay solver spread instead, 0.10-0.30% depending on trust tier, and that's the whole bill.
If any MEV does surface, and we don't see how since the trade was never on the visible side of the glass, it gets split back to users and the protocol.

---

## You don't connect a wallet

<div class="post-image-float-left">
<img src="/images/blog/Le_Tricheur_a_las_de_carreau_Georges_de_La_Tour.webp" alt="Le Tricheur a l'as de carreau by Georges de La Tour (c. 1635) - Three players around a candlelit table; the cheat on the left palms a hidden ace, the courtesan in the center cuts her eyes sideways to signal, the wealthy young dupe on the right studies his cards alone" loading="lazy" />
<p class="post-caption"><em>Le Tricheur a l'as de carreau</em> (c. 1635) - Georges de La Tour. Musee du Louvre, Paris.</p>
</div>

Every other dark pool starts with "connect your wallet." Think deeply about what that really means for a privacy product.
Before you've done anything, before you've expressed any intent, you've handed over a public key linked to your entire on-chain history. Many wallets specialize in selling your data as payment for orderflow to MEV operators (Otherwise [known as PFOF](https://www.investopedia.com/terms/p/paymentoforderflow.asp); invented by none other than [Bernie Madoff](https://en.wikipedia.org/wiki/Bernie_Madoff#Career))

> What _real_ privacy product could grow from the seed a privacy sin?

This necessitated for us to allow for a safer and more seamless alternative we can provide for normies to still walk the privacy path as they learn.

### Introducing XID

XID works differently. You touch a fingerprint sensor. The browser creates a passkey on your hardware and never lets it leave the device. The server stores one artifact: the credential's public key, encrypted at rest. No username, no email, no wallet address. Your session ID is a hash of the credential ID, a pseudonym that can't be reversed to a person or a device.

Wallets come later, if at all. Some users are here for a single swap and shouldn't need an account for that. Connect any EVM wallet, skip XID entirely, trade at Standard tier. For everyone else, the wallet link exists only in the browser session. The server doesn't record it. If the credential store leaked tomorrow, an attacker would find encrypted blobs keyed by hashes. Nothing to correlate with on-chain activity.

This is what makes the trust score work. Without pseudonymous identity, attestations have to anchor to wallet addresses, which are public and trivially deanonymized through chain analysis. Our XID allows earning deeper privacy without requiring sacrifice it at the front door.

Identity verification is optional. Its benefits are not.

---

## Compliance without confession

<div class="post-image-float-right">
<img src="/images/blog/Johannes_Vermeer_Woman_Holding_a_Balance.webp" alt="Woman Holding a Balance by Johannes Vermeer (c. 1664) - A woman weighs empty scales in soft light, the Last Judgment painted on the wall behind her" loading="lazy" />
<p class="post-caption"><em>Woman Holding a Balance</em> (c. 1664) - Johannes Vermeer. National Gallery of Art, Washington.</p>
</div>

Privacy in crypto has always forced a bad choice. Full transparency (Uniswap, CoW Protocol) keeps you compliant but exposes everything. Full privacy (Tornado Cash) gets sanctioned. Pick a side.

Before getting into how Xochi ZKP works, it's worth defining what compliance is actually trying to do.
The task is simple: prevent sanctioned actors from using the financial system, catch structuring patterns that indicate money laundering, and verify that participants have been screened. That's it. The laws don't require that a regulator see your trade. They require that someone verified the trade wasn't dirty. Every SAR filing, every KYC check, every sanctions screen is answering the same question: "was this clean?" The answer is binary. The data underneath it doesn't need to be.

Xochi ZKP (zero-knowledge compliance proofs) answers that question cryptographically. A proof that a trade is AML/sanctions-compliant without revealing the trade itself. The regulator verifies the proof. They never see the data.

| Regulatory Requirement | What the ZK Proof Says     | What Stays Hidden   |
| ---------------------- | -------------------------- | ------------------- |
| Large value report     | "Amount exceeds threshold" | Exact amount        |
| Source of funds        | "Valid attestation exists" | Fund details        |
| Counterparty screening | "Not on sanctions list"    | Identity            |
| Anti-structuring       | "Pattern NOT detected"     | Transaction history |

Six proof types, formalized as an [open Ethereum standard](https://github.com/xochi-fi/erc-xochi-zkp) with Solidity interfaces and Noir circuits. The reference implementation is CC0 public domain. Pre-audit, but the math is there to inspect.

From the user's side: you pick identity providers a la carte. A Worldcoin proof, a Coinbase attestation, a ZKPassport credential. You're choosing from a menu. The oracle observes across all of them. One provider saying "clean" is a data point. Three independent providers across different categories (humanity, identity, compliance screening) is a conviction.

On the back end, the oracle learns. When a bad actor gets through, the proof trail shows which screening providers cleared them and where the composite signal had a blind spot. Those providers get downweighted. Providers that catch what others miss get upweighted. The weights converge on the set that actually catches bad actors in practice, tuned by real enforcement data. The user just sees cheaper fees as their trust score improves.

The legal grounding is where I lose sleep. GDPR's data minimization principle (Art. 5(1)(c)) says process only what's necessary, and a ZK proof is minimal disclosure by definition. The logic feels solid there. VARA's January 2026 anonymity ban defines anonymity-enhanced crypto as assets lacking "mitigating technologies" for traceability. Xochi ZKP is designed to be exactly that: traceability without exposing transaction data.

But nobody has tried this argument in front of a regulator. I can't tell you whether a compliance officer in Dubai will look at a ZK proof and say "yes, this counts." The law's own language supports us. Whether that's enough is a different question.

The proofs work retroactively. If OFAC sanctions an address three months after a trade, the proof from the original transaction still exists, showing the signal was clear at time of execution.

---

## The glass cube

<div class="post-image-float-left">
<img src="/images/blog/holy-family-with-a-curtain-1646.webp" alt="The Holy Family with a Curtain by Rembrandt (1646) - A trompe-l'oeil curtain half-drawn over a domestic scene, privacy as partial opacity" loading="lazy" />
<p class="post-caption"><em>The Holy Family with a Curtain</em> (1646) - Rembrandt van Rijn. Gemaeldegalerie Alte Meister, Kassel.</p>
</div>

Privacy is a spectrum. We think of it as a glass cube. Six levels, crystal clear to solid.

At the bottom, everything is visible. Open tier: the protocol pays you -0.02% and collects analytics on the trade. You're selling your order flow. Public tier: free, full visibility, Xochi's routing without privacy. These exist because some users want execution quality without caring who sees.

Standard is the default. Wallet and amounts hidden, open to anyone, no attestations required. This is where most users start and where the privacy-by-default promise lives. If you never do anything else, your trades are still invisible to MEV bots and chain analysts.

Above Standard is where the cube gets interesting. A Worldcoin proof and a Coinbase attestation gets you to the Stealth tier in minutes. One-time receiving addresses that act as smart contract wallets, gasless claiming, lower fees, MEV rebates. You didn't fill out a form. You proved you're human and that a regulated exchange has seen your face. The protocol treats that as signal and gives you more opacity in return.

Stack attestations across categories (humanity, identity, reputation, compliance) and the cube gets more opaque. Private and Sovereign settle through [pxe-bridge](https://github.com/xochi-fi/pxe-bridge), an open-source JSON-RPC sidecar that embeds Aztec's Private eXecution Environment. The PXE is the local runtime where the private half of an Aztec transaction actually runs. On your machine, in your pond. The proof leaves; the inputs never do. pxe-bridge wraps that in JSON-RPC so Riddler can create shielded notes without speaking Aztec natively.

Sovereign is zero data retention, 0.15% fee, 25% MEV rebate. Nothing is stored. The proof that you were compliant exists on-chain. The trade itself doesn't exist anywhere.

Diminishing returns prevent gaming. First attestation in a category earns full points, the second a quarter, the third barely registers. Depth across categories matters more than stacking one. The incentive is to prove different things about yourself, not the same thing three times.

The thing I keep coming back to: the glass cube inverts the normal relationship between trust and surveillance. In traditional finance, more trust means more access, which means more surveillance. KYC/KYB/POH gets heavier as you move up. On Xochi, more trust means more privacy. You earn opacity. The system rewards you for proving you're legitimate by giving you more room to be private. I don't know if that framing survives contact with regulators. But the glass should get thicker the more you've shown you belong on the inside of it.

---

<div class="post-image-float-right">
<img src="/images/blog/Piranesi02.webp" alt="The Pier with Chains (Plate XVI) by Giovanni Battista Piranesi (1761) - Vast prison architecture where every figure is exposed and observable" loading="lazy" />
<p class="post-caption"><em>Le Carceri d'Invenzione, Plate XVI: The Pier with Chains</em> (1761) - Giovanni Battista Piranesi.</p>
</div>

## The field

Most projects that claim privacy are pools. You shield your wallet, swap on a public DEX, shield the output. The wallet is hidden, but the trade is still visible. MEV bots care about what you're swapping, not who you are.

| Project              | Privacy                          | Compliance         | Mempool | Execution | Settlement |
| -------------------- | -------------------------------- | ------------------ | ------- | --------- | ---------- |
| **Xochi**            | Stealth smart accounts, Aztec ZK | Graduated + ZKP    | Private | Private   | Private    |
| Renegade (Arb, Base) | MPC + ZKPs, dark pool matching   | Opt-in ID matching | Private | Private   | Private    |
| Railgun              | zkSNARKs, shielded pool          | View keys          | --      | --        | Private    |
| Penumbra             | ZK, shielded chain (Cosmos)      | None               | Private | Private   | Private    |
| 0xbow                | zkSNARKs, deposit source proof   | Set membership     | --      | --        | Private    |
| CoW Swap             | MEV protection only              | None               | Private | --        | --         |

Renegade is the closest architecturally: real dark pool matching, now live on Arbitrum and Base. They've added opt-in counterparty identity filtering (traders can choose to only match with verified counterparties), but that's counterparty filtering, not a compliance framework. They don't generate ZK proofs, don't screen across jurisdictions, don't produce retroactive proof-of-innocence. 0xbow validated the core thesis that ZK proofs can handle compliance without revealing data. Set membership is one piece of that. There are five others.

The field is getting wider. [Chainlink Confidential Compute](https://blog.chain.link/chainlink-confidential-compute/) shipped in early access. [COTI launched Nightfall ZK Rollup](https://cotinetwork.medium.com/confidential-defi-has-arrived-why-on-chain-dark-pools-and-private-lending-need-coti-fc242975f5e7) in March 2026. NEAR launched "Confidential Intents." Cointelegraph is calling 2026 "[the year of pragmatic privacy](https://magazine.cointelegraph.com/2026-pragmatic-privacy-crypto-canton-zcash-ethereum-foundation/)."

I want more projects in this space. Every protocol that ships real privacy on Ethereum makes the regulatory argument easier for everyone else, and the regulatory argument is the bottleneck. The crypto on the chain is fine. What's missing is the institutional infrastructure that lets serious capital use the crypto without lighting itself on fire, and that infrastructure has to be built in public, by enough projects that no single one of us is the lone test case.

---

## Why now

<img src="/images/blog/Piranesi9c.webp" alt="The Drawbridge (Plate VII) by Giovanni Battista Piranesi (1761) - Figures exposed on walkways in a vast imaginary prison, everything visible" loading="lazy" class="post-image-statement" />

<p class="post-caption"><em>Le Carceri d'Invenzione, Plate VII: The Drawbridge</em> (1761) - Giovanni Battista Piranesi</p>

$289 million in sandwich attacks alone on Ethereum in 2025, 51% of the $562M total MEV volume ([EigenPhi via Cointelegraph Research](https://cointelegraph.com/research/exclusive-data-from-eigenphi-reveals-that-sandwich-attacks-on-ethereum-have-waned)). Between 60,000 and 90,000 sandwich attacks per month, and that's with 80% of transactions already using private RPCs to dodge the public mempool.

Ethereum knows this. FOCIL (EIP-7805) is confirmed for the Hegota hard fork, late 2026. LUCID (encrypted mempools) is actively seeking inclusion alongside it. Vitalik paired FOCIL with EIP-8141 (account abstraction) so transactions from privacy protocols can go through the public mempool and be received directly by FOCIL includers without wrappers or intermediaries. He's been writing about "sanctuary technologies" and building a "cypherpunk principled non-ugly Ethereum" since late 2025. The direction is right. But the upgrade that ships protocol-level MEV protection is H2 2026 at the earliest, and in the meantime sixty thousand sandwich attacks happen every month.

The regulatory picture shifted too. The Tornado Cash sanctions were [lifted](https://decrypt.co/293796/torn-jumps-380-privacy-coins-railgun-zcash-surge-after-tornado-cash-ruling) after the Fifth Circuit ruled immutable smart contracts don't qualify as "property" under IEEPA. Zcash rallied 750%+ and overtook Monero as the top privacy coin by market cap. The Winklevoss twins launched a Zcash treasury company. Railgun saw [$1.4B in net inflows](https://cryptoslate.com/ethereum-bots-are-burning-over-50-of-gas-fees-so-eth-now-needs-privacy-just-to-scale/) in 2025. The Ethereum Foundation formed a dedicated privacy team. Coinbase is lobbying for privacy-friendly regulation. Grayscale's [2026 Digital Asset Outlook](https://research.grayscale.com/reports/2026-digital-asset-outlook-dawn-of-the-institutional-era) calls privacy "prerequisite for real-world liquidity." Two years ago, privacy in crypto was a liability. The window opened fast.

What's strange is that crypto rebuilt an entire financial system from scratch and somehow forgot to include the part where large trades happen privately. Every other asset class has dark pools, block trading desks, OTC venues. The BIS counts $4 trillion/day in OTC FX swaps. Institutions figured out decades ago that broadcasting trades is a losing strategy. Crypto has a public mempool and a prayer.

Software agents are entering this picture too. [Coinbase launched "Agentic Wallets"](https://www.coinbase.com/developer-platform/discover/launches/agentic-wallets), wallet infrastructure specifically for AI agents. On-chain data from Base and Solana already shows exponential growth in agent-generated volume. The conversation is mostly about guardrails and spending caps. Almost nobody is talking about MEV.

Think about what an unattended trading agent looks like to a sandwich bot. Predictable strategy. Runs 24/7. Broadcasts every move to the mempool. Never sleeps, never adjusts, never gets bored. It's a target that announces itself. The first generation of these agents will get extracted from the moment they manage real capital, and their operators will have no idea why P&L looks the way it does until someone shows them the EigenPhi dashboard.

Raxol, our OTP-native agent runtime, ships with Xochi payment rails built in. The Mandate framework lets a human delegate trading authority to an agent without ever linking the agent's wallet to the human's identity. The human signs a scoped EIP-712 envelope (max amount, expiry, call count), the agent presents it on every request, the server verifies per-call and stores nothing persistent. Agents transact under the human's trust tier and inherit their privacy access. The agent acts autonomously. The privacy stays with the principal.

---

## The team

<div class="post-image-float-right">
<img src="/images/blog/don-quixote-and-sancho-setting-out-1863.webp" alt="Don Quixote and Sancho Setting Out by Gustave Dore (1863) - The knight in armor on a thin horse and his squire on a donkey, riding off together into a dawn landscape on a mission of uncertain outcome" loading="lazy" />
<p class="post-caption"><em>Don Quixote and Sancho Setting Out</em> (1863) - Gustave Dore.</p>
</div>

Five of us now. Jer and I overlapped at Blockdaemon running nodes across regions. Bloo was on the other side of the table, filing SARs at DOJ, investigating AML cases at FBI. The ZK compliance proofs went through a lot of iteration before they reached a shape she'd sign off on.

- **Drew** (Protocol Director). R&D Engineer at General Dynamics, Protocol Specialist at Lido, Node Ops at Blockdaemon. MechE/ElecE with defense R&D patents.
- **Jer** (Blockchain Engineer). APAC Node Ops Lead at Blockdaemon, Analyst at Deloitte, Forex Trader at Silab Luchre Capital.
- **Jan** (Infrastructure). Lido CSM, Aztec genesis sequencer operator, Systems Engineer and Generalized Mining Lead at Anyblock Analytics, Protocol Specialist at Blockdaemon and Lido.
- **Bloo** (Compliance). FBI-DOJ AML/Terrorist Financing, DOJ Financial Intelligence, U.S. Army Intelligence (Pentagon), Compliance & Legal at Blockdaemon.
- **V** (DevSecOps). [Immunefi whitehat](https://immunefi.com/profile/Merkle_Bonsai/), UI Lead at Lido, Founder at here.build.

Bloo has been the reviewer on the other side of these applications. When we draft for VARA, that shows.

Riddler fills intents on mainnet across every advertised route. Live B2B integration, real tokens, real settlement. ~2s typical, <6s P95. Infrastructure is production on five chains. The system works. What it needs is capital to scale liquidity beyond B2B into a public product. For the full technical breakdown, fee structure, and roadmap, see the [whitepaper](https://xochi.fi/whitepaper).

Xochi is the commercial product. The open infrastructure underneath it (Mana, the ZK-Compliance Oracle spec, the stealth address primitives, Raxol, the whitehat research) is axol.io. We're funding the public goods side through [Giveth](https://qf.giveth.io/project/axolio-xochifi). ETH donated gets staked via DVT on hardware we already operate. The principal stays staked. Yield funds operations permanently. We're not asking for funding to start. We're asking for funding to not stop.

---

No on-chain venue is both private and compliant. That's either a gap in the market or a sign that it can't be done. I think about both possibilities more than is probably healthy. We have the solver, the infrastructure, and a team that has spent time on both sides of the enforcement table. The bet is that regulators will accept cryptographic compliance. We think the math is on our side. We'll find out.

<div class="post-cta banner-beam">
<p class="post-cta-tag">Ethereum Security QF Round, closes May 14</p>
<p class="post-cta-headline">$100 you give &rarr; ~$50K matched</p>
<p class="post-cta-sub">Quadratic funding turns small donations into large grants. Back the public goods underneath Xochi.</p>
<a class="post-cta-button" href="https://qf.giveth.io/project/axolio-xochifi" target="_blank" rel="noopener noreferrer">Donate on Giveth &rarr;</a>
</div>

_Xochi is ETH's Friendly Dark Pool, built by the axolotls at [axol.io](https://axol.io). Trade at [xochi.fi](https://xochi.fi). Back the build on [Giveth](https://qf.giveth.io/project/axolio-xochifi)._
