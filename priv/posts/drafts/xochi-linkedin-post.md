# Xochi LinkedIn Post

# Post from: Drew Bhatt / Droo Amor

# Link back to: droo.foo/posts/xochi-ethereum-dark-pool

---

A protocol treasury got sandwiched on a governance-approved swap last quarter. Five figures extracted from a seven-figure trade. They had to explain the slippage to token holders in a public forum post. This happens every day on Ethereum -- $289M extracted via sandwich attacks alone in 2025, with 60,000-90,000 attacks per month.

I've spent the last five years running the kind of infrastructure that makes this possible -- validators, solvers, sequencers. The thing that never stopped bothering me: every transaction on a public blockchain is visible to everyone, forever. For small trades that's fine. For large ones it's a tax you pay for the privilege of being watched.

TradFi solved this decades ago. Off-exchange venues handle the majority of US equity volume. OTC FX runs $4 trillion a day. Crypto has no equivalent.

So we built one.

Xochi is a dark pool on Ethereum. You sign an intent describing the trade you want. Solvers compete to fill it. Nothing touches the public mempool. Settlement lands on stealth smart accounts that only the recipient can unlock, gasless claiming. Riddler, our solver, fills real intents in ~2s across five chains. We're raising to capitalize the solver and scale liquidity beyond our current B2B integrations into a public product.

The economics are straightforward. Without MEV protection, sandwich bots extract 0.1-5%+ per trade (EigenPhi via Cointelegraph Research, Dec 2025). In March 2025, one trader lost $215K on a single stablecoin swap on Uniswap V3. On Xochi, MEV extraction is zero -- the trade never touches a public pool. You pay solver spread: 0.15-0.30% depending on trust tier.

The hard part was compliance. Privacy in crypto has always meant choosing between transparency and sanctions risk. We built Xochi ZKP -- zero-knowledge compliance proofs -- to get out of that corner. A cryptographic proof that a transaction is AML-compliant without revealing the trade itself. The regulator verifies a proof. The underlying data stays private. Six proof types, formalized as an EIP draft with Noir circuits. CC0 licensed.

Xochi ZKP is novel. No regulatory precedent. I won't pretend that doesn't keep me up at night. If a jurisdiction says no, compliance delegates to licensed solvers who handle it traditionally. The privacy still works. The ZK compliance is the bet, and we've built the fallback.

Our team is four people, building together since 2021. Protocol engineering from Lido, Blockdaemon, and General Dynamics R&D. A cofounder who traded FX professionally before crypto (relevant when we add EURC/GYEN pairs in Q4). Compliance from DOJ Financial Intelligence, FBI AML, Pentagon intelligence. Not advisors -- cofounders who've filed SARs and built the frameworks we're trying to improve with better cryptography. DevSecOps from an Immunefi whitehat with a live bug bounty up to $500K.

Ethereum is moving in this direction. Vitalik has been writing about encrypted mempools, FOCIL, and "sanctuary technologies" -- but the upgrade that ships this is H2 2026 at the earliest. We built Xochi because the timeline is too long and the bleeding is real.

The full post breaks down how Xochi ZKP proves compliance without revealing trade data, why hiding the wallet isn't enough when the swap is still public, and what happens when someone bad uses the system:
droo.foo/posts/xochi-ethereum-dark-pool

---

# Notes:

# - Opens with a scene (DAO payroll scenario), not a credential

# - Personal voice kicks in paragraph 2 ("I've spent...")

# - Hook lands in first 3 lines (visible before "see more")

# - Cut macro paragraph (dollar reserves, MiCA, USDT) -- too much for LinkedIn

# - Kept team paragraph -- LinkedIn is where credentials land hardest

# - Honest solver caveat included

# - Xochi ZKP fallback plan mentioned

# - ~380 words (tighter than original -- macro analysis moved to blog post)
