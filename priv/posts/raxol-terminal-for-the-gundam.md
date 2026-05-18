---
title: "Raxol: The Terminal For My Gundam"
date: "2026-05-10"
description: "Thirteen packages later. Symphony as cockpit, ACP for agents that sell, and what happens once a process has its own wallet."
author: "DROO AMOR"
tags: ["elixir", "otp", "agents", "raxol", "tui", "beam"]
slug: "raxol-terminal-for-the-gundam"
pattern_style: "cockpit_hud"
---

<img src="/images/blog/gundam/Unforgettable_Gundam_Corin_Nander_Wing_Gundam_Zero.webp" alt="Wing Gundam Zero reflected in Corin Nander's eyes, the unforgettable image from Turn A Gundam (Sunrise, 1999)" loading="lazy" class="post-image-statement" />

<p class="post-caption">Wing Gundam Zero reflected in Corin Nander's eyes. <em>Turn A Gundam</em> (Sunrise, 1999)</p>

<div class="post-media-center">
<iframe width="320" height="180" src="https://www.youtube.com/embed/YctMJ-1W0T0?rel=0" title="Soundtrack for this post" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen loading="lazy"></iframe>
</div>

<p class="post-caption">Optional soundtrack. Press play and let it run while you read.</p>

# Two problems, one shape

I was watching an AI agent try to read `htop`. It had no idea what was on screen.

It was pulling raw bytes (escape codes, cursor moves, color sequences) and looking for meaning in the noise. Couldn't scroll. Couldn't check which process had focus. Eventually gave up and shelled out `top -l 1`. The agent could read what the terminal handed it, but it couldn't ask the terminal anything about its own screen: where the cursor was, what was visible, whether anything had just scrolled.

Two problems showed up that week, in the same shape.

The first was a terminal for AI agents. A real emulator where agents address structured screen state (cursor positions, scroll regions, alternate screens) as buffers they can reason about.

The second was the cockpit of a Gundam. Wing Zero specifically, because the cockpit works as a design when every subsystem fails on its own. Sensor goes dark, the HUD prints "NO DATA" in that one slot and keeps drawing the rest. Real fighter cockpits behave the same way, but mech anime makes the design philosophy visceral. You watch a pilot lose a sensor, then a comms link, then a leg, and keep flying with whatever is left.

The terminal is the cockpit. The agent is just another pilot. The only runtime I trust to make either of them work is the [BEAM](https://wiki.droo.foo/wikipedia/BEAM_%28Erlang_virtual_machine%29), the virtual machine Erlang and Elixir run on.

When the Telegram bridge drops, the dashboard keeps rendering. When one task crashes mid-job, the notification for the task next door still fires. That fault-isolation is what you get once you stop fighting the runtime.

<img src="/images/blog/Giovanni_Battista_Piranesi_-_Le_Carceri_d'Invenzione_-_Second_Edition_-_1761_-_14_-_The_Gothic_Arch.webp" alt="The Gothic Arch (Plate XIV) by Giovanni Battista Piranesi (1761). Massive structural systems with walkways, machinery, and tiny human operators within vast architecture" loading="lazy" class="post-image-statement" />

<p class="post-caption">Giovanni Battista Piranesi, <em>Le Carceri d'Invenzione, Plate XIV: The Gothic Arch</em> (1761).</p>

---

## What AI agents are missing

Most agents do the same loop. Observe, decide, act. Read state. Pick a tool. Execute. Read the result. Repeat.

The reasoning is clean. The runtime underneath is duct tape. Shelling to `cat` and `grep` and `sed`. Reading files as strings and hoping the encoding is fine. State management via a conversation window that gets compressed once it runs long. Single-threaded, no fault isolation, no hot reload. Beautiful brain, broken body.

Two things follow. The runtime matters as much as the model. The smartest reasoner in the world stops being useful the moment its process dies and takes everything with it. And agents do better with structured environments. An agent that can address terminal state (what is visible, where the cursor is, which pane has focus) will outperform one staring at a wall of bytes every time.

<img src="/images/blog/gundam/EW_Wing_Zero_console_panel_Activation.webp" alt="Wing Gundam Zero EW console panel: targeting display with structured sensor data, not raw output (Sunrise, 1997)" loading="lazy" class="post-image-float-right" />

Give an agent a real <abbr title="DEC VT100 — the 1978 terminal whose escape codes and screen behaviour modern terminals still emulate">VT100</abbr> buffer and the questions change. It can read a specific region of the screen, check what's visible, scroll, focus a pane. Raxol does this. It is a terminal emulator written in Elixir, backed by a proper screen buffer, with structured access to that state for agents and humans alike.

<img src="/images/blog/gundam/epyon-helmet-pov.webp" alt="Helmet POV from inside Epyon's cockpit: red wireframe HUD with labeled regions, sensor status text, generator percentage, and numerical state" loading="lazy" class="post-image-statement" />

<p class="post-caption">Helmet POV inside Epyon's cockpit. Labeled regions, status text, numerical state. This is the view an agent should get, not a wall of bytes.</p>

---

<img src="/images/blog/Wright_of_Derby_The_Orrery.webp" alt="A Philosopher Lecturing on the Orrery by Joseph Wright of Derby (c. 1766). Figures gathered around a mechanical solar system model lit by a central lamp, each planet on its own arm" loading="lazy" class="post-image-statement" />

<p class="post-caption">Joseph Wright of Derby, <em>A Philosopher Lecturing on the Orrery</em> (c. 1766). Derby Museum and Art Gallery.</p>

## TEA for everything

Raxol uses the [Elm Architecture](https://guide.elm-lang.org/architecture/). `init`, `update`, `view`. Three callbacks and a supervised application falls out the other end. Whether the application is a counter, a file browser, or an AI agent streaming tokens from Claude.

```elixir
# Human-operated counter
defmodule Counter do
  use Raxol.Core.Runtime.Application

  def init(_), do: {%{n: 0}, []}
  def update(:increment, model), do: {%{model | n: model.n + 1}, []}
  def update(:decrement, model), do: {%{model | n: model.n - 1}, []}
end

# Same architecture. Different input source. This one pays for its data.
defmodule Researcher do
  use Raxol.Agent
  alias Raxol.Payments.{Req.AgentPlugin, SpendingPolicy, Wallets}

  def init(_) do
    plugin = AgentPlugin.auto_pay(
      wallet: Wallets.OP,            # 1Password-backed signing key
      policy: SpendingPolicy.dev(),  # per-session / lifetime caps
      agent_id: :researcher
    )
    {%{notes: [], http: plugin}, []}
  end

  def update({:dig, topic}, %{http: plugin} = model) do
    {model, Command.async(fn sender ->
      {:ok, resp} =
        Req.new(url: "https://feed.example.com/q?t=" <> URI.encode(topic))
        |> plugin.()
        |> Req.get()
      sender.({:found, resp.body})
    end)}
  end

  def update({:command_result, {:found, data}}, model) do
    {%{model | notes: [data | model.notes]}, []}
  end
end
```

One module takes keystrokes. The other takes Req responses. Both supervised, both hot-reloadable. When the upstream returns 402, `AutoPay` parses the challenge, checks the ledger against `SpendingPolicy`, signs an x402 header from the agent's own wallet, and resends. The agent's `update/2` never sees the failure. If the researcher crashes mid-query, the supervisor restarts it with last known good state. The counter keeps counting.

The difference between a human app and an agent is where the input comes from. Agents can render to the terminal through `view/1`, or skip it and run headless. The runtime is indifferent.

This is the piece most agent frameworks get wrong. They bolt a separate "agent SDK" onto a language and end up rebuilding supervision, state machines, and lifecycle hooks from scratch. In Raxol, agents and interfaces are the same object. How you process messages is your business. ReAct, chain-of-thought, an FSM with guards. Different bodies for `update/2`.

---

## The cockpit

<img src="/images/blog/gundam/Wing_Zero_EW_Recoil_fault_tolerance.webp" alt="Wing Gundam Zero firing through the recoil of its Twin Buster Rifle, yellow beam streaks crossing the frame" loading="lazy" class="post-image-statement" />

<p class="post-caption">Subsystems hold while the suit takes the hit. <em>Endless Waltz</em> (Sunrise, 1997).</p>

In most agent frameworks, a bad tool call cascades. Process crashes, state vanishes, restart from scratch if you're lucky. If you're not lucky, it corrupts a shared structure and takes other agents with it.

In Raxol the agent is an [OTP](https://wiki.droo.foo/wikipedia/Open_Telecom_Platform) process. When it crashes the supervisor catches it, the cockpit stays up, the agent restarts with last known good state, and the HUD shows a blip. One gauge resets to stale-but-safe data while the fresh state loads. The pilot keeps flying.

<img src="/images/blog/gundam/gundam-cockpit-concept.webp" alt="Gundam cockpit HUD with independent gauges for armor, boost, radar, ammo, and battle log. Each subsystem reports independently (Bandai Namco)" loading="lazy" class="post-image-statement" />

<p class="post-caption">Every subsystem is a separate gauge. When one fails, the gauge says NO DATA. The pilot keeps flying. (Bandai Namco)</p>

I keep coming back to how right this feels as a design target. High availability in a very specific sense: graceful degradation as a UI pattern. A dozen subsystems feeding one interface (navigation, sensors, comms, weapons), each one running independently, all reporting to a single HUD. When one dies, the gauge stays on screen and says "NO DATA." The pilot sees a degraded but functional world. That distinction is the whole game.

```
+--------------------------------------------------+
| SENSOR HUD            [NOMINAL]     12:34:56.789 |
+--------------------------------------------------+
| CPU ====----  42%  | MEM ====----- 38%           |
| NET ...........    | DISK ======-- 67%           |
+--------------------------------------------------+
| SPARKLINE  ._/\._./^^\._.  (last 60s)            |
+--------------------------------------------------+
| THREATS: [NONE]                                  |
| MINIMAP: [sector 7-G clear]                      |
+--------------------------------------------------+
```

Put an AI agent in that seat. It reads the same HUD. Processes sensor data through `update/2`. Issues commands: reallocate resources, flag an anomaly, adjust course. The runtime executes. Same interface, same state, same fault isolation. Carbon pilot or silicon pilot.

---

## Where it stands

The plan was six packages. There are thirteen now, which probably says something about how much I've underestimated the scope of this thing every quarter for two years.

Last quarter I went back and unified the lifecycle code across all of them. Every package now uses the same `BaseManager` pattern for its GenServers. That kind of consolidation does not make a good headline, but it is the work that turns thirteen scattered packages into thirteen packages that behave like one runtime. Eleven of them ship on Hex. The two holdouts, `raxol_acp` and `raxol_symphony`, are still pre-alpha.

The originals are stable: `raxol_core`, `raxol_terminal`, `raxol_sensor`, `raxol_mcp`, `raxol_liveview`, `raxol_plugin`. The two staged extractions shipped: `raxol_agent` and `raxol_payments` are first-class packages now. Then three surface packages I didn't plan for a year ago: `raxol_speech` (<abbr title="Text-To-Speech — model converts written text into spoken audio">TTS</abbr> announcements via Bumblebee, <abbr title="Speech-To-Text — model transcribes spoken audio into written text">STT</abbr> input via Whisper), `raxol_telegram` (TEA modules rendered as inline keyboards inside a chat), `raxol_watch` (<abbr title="Apple Push Notification service — iOS and macOS push delivery channel">APNS</abbr> and <abbr title="Firebase Cloud Messaging — Google's push delivery service for Android, web, and iOS">FCM</abbr> push for glanceable summaries, with tap actions routed back as events). Each of these started as "what if the surface was X" and turned out to share enough machinery with the existing renderers that they slotted in.

Then two new flagship packages that genuinely caught me by surprise.

`raxol_symphony` is a port of [OpenAI Symphony](https://github.com/openai/symphony). An orchestrator polls a tracker (Linear or GitHub Issues), claims eligible work, isolates each issue in its own workspace, and runs a coding agent until the work reaches a workflow-defined handoff state. Six surfaces consume the same orchestrator snapshot over PubSub: terminal dashboard, LiveView, <abbr title="Model Context Protocol — Anthropic's spec for exposing tools and data to AI agents">MCP</abbr> tools, Telegram inline keyboards, Watch push, JSON API. Per-run evidence (CI status, PR comments, complexity scores, asciinema replays) is collected automatically. Two runner backends ship: the default wraps `Raxol.Agent.Stream`, the other is the upstream `codex app-server` over a Port for parity with the original Elixir reference.

When I drafted this post the first time, "cockpit" was a metaphor. Symphony turned it into something I can point at. One orchestrator state, six independent surfaces, each failing in its own corner. I didn't design it that way on purpose.

`raxol_acp` is the other one. <abbr title="Agent Commerce Protocol — Virtuals' spec for agents to discover, hire, and pay each other on-chain">Agent Commerce Protocol</abbr>, the spec used by [Virtuals](https://app.virtuals.io)' agent marketplace. The polite framing is "we shipped an OTP implementation of ACP." The honest framing is that every other ACP seller is a Python or Node script with a hand-rolled `threading.Lock` and a polling loop for a flaky WebSocket. raxol_acp gets you one supervised process per active job, a dedicated `NonceServer` GenServer per wallet so concurrent jobs can't trample each other while signing, hot reload of a buggy offering without dropping the socket, process-per-offering with crash isolation, and <abbr title="Disk Erlang Term Storage — built-in on-disk key-value store for Erlang terms; survives node restarts">DETS</abbr>-backed memo persistence so a node restart resumes mid-flight jobs instead of orphaning them. None of that is exotic on the BEAM. It is exotic in agent commerce, where the default infrastructure is "a thread lock and a prayer."

v0.1 engineering is done. The on-chain client is real Req-based <abbr title="JSON-RPC — remote procedure call protocol encoded in JSON; how Ethereum nodes expose their API">JSON-RPC</abbr>, with <abbr title="Ethereum Improvement Proposal 1559 — gas pricing model with a base fee plus tip, introduced in the 2021 London hard fork">EIP-1559</abbr> typed-transaction signing, hand-rolled Yellow-Paper <abbr title="Recursive Length Prefix — Ethereum's canonical binary encoding for transactions and state">RLP</abbr>, and a log decoder that pulls `job_id` out of `create_job` receipts. The seller stack ships behind a feature flag. What is left is waiting on Virtuals to publish the <abbr title="Smart Contract Account — contract that acts as a user account; enables programmable wallet behaviour">SCA</abbr> contract spec so the <abbr title="Application Binary Interface — schema describing how to encode calls and decode results for a smart contract">ABIs</abbr> stop being placeholders.

`raxol_payments` got a lot bigger this quarter. The last draft of this post mentioned x402 and Xochi. What's there now: three protocols (<abbr title="HTTP 402 payment protocol — pay-per-request flow where a 402 response carries an invoice the client signs and resubmits">x402</abbr>, <abbr title="Machine Payment Protocol — Stripe and Tempo's standard for machine-initiated payments with stable settlement">MPP</abbr> for Stripe/Tempo machine payments, Xochi for cross-chain intent settlement), an auto-selecting Router that picks based on chain, privacy tier, and trust score, <abbr title="Ethereum standard for stealth address payments — recipient generates a fresh one-time address from a shared meta-address, breaking the on-chain link to their public identity">ERC-5564</abbr> and <abbr title="Companion to ERC-5564 — on-chain registry mapping an account to its stealth meta-address">ERC-6538</abbr> stealth addresses (about 300 lines of <abbr title="Elliptic curve used by Bitcoin and Ethereum for digital signatures">secp256k1</abbr>), ZKSAR attestation verification across six proof types, a TrustScore aggregator with diminishing returns, the Glass Cube privacy tier model (six tiers, attestation-gated), a per-request/session/lifetime spending ledger as its own GenServer, and a <abbr title="Private Execution Environment — Aztec's client-side prover and key manager; executes transactions privately before posting public state">PXE</abbr> Bridge to Aztec for execution-level privacy beyond what stealth gives you.

The piece I keep tuning is the auth model. A Raxol agent transacts either as a Guest (paying per call via x402, capped at Standard privacy, holding its own keys) or under a Mandate (a human signs a scoped <abbr title="Ethereum Improvement Proposal 712 — standard for signing structured data instead of opaque bytes; powers off-chain authorisations like this Mandate envelope">EIP-712</abbr> envelope with max amount, expiry, and call count; the agent inherits the human's trust tier and privacy access for the envelope's lifetime).

```elixir
alias Raxol.Payments.{Mandate, Wallets}

{:ok, mandate} =
  Mandate.build(
    human_wallet:   member_addr,
    agent_wallet:   agent_addr,
    scopes:         ["execute"],
    max_amount_usd: 250,
    max_calls:      20,
    expires_at:     System.system_time(:second) + 3600
  )

{:ok, signed}   = Mandate.sign(mandate, Wallets.OP)
{:ok, envelope} = Mandate.to_envelope(signed)
# Agent presents `envelope` in X-Xochi-Delegation on every call.
# Xochi verifies the signature against human_wallet and decrements
# budget counters keyed by H(envelope). The agent never authenticates.
```

The server verifies per-call and stores nothing persistent that links agent to human. The digest runs through a shared `Raxol.Payments.EIP712` encoder with `string[]` support, and the pinned vector test matches viem's `hashTypedData` byte-for-byte, so signatures verify on the Xochi side without divergence. Agents that need real privacy can have it without becoming the human's pseudonymous twin on-chain.

Xochi itself is now built into the raxol README as a first-class example, because at some point I stopped explaining the framework abstractly and started pointing at the most convincing thing I could find. The Xochi trader terminal serves over SSH with zero install. The web trading UI renders the same TEA module via LiveView. The solver agent surface lets Riddler's sub-2ms solver consume auto-derived MCP tools to bid on intents. The ops cockpit watches solver health, validator peers, and settlement latency on a BEAM dashboard with sensor fusion. One TEA module. Four surfaces. The solver agent and the human trader interact with the same widget tree through different projections.

Coinbase recently launched [Agentic Wallets](https://www.coinbase.com/developer-platform/discover/launches/agentic-wallets), and on-chain volume from agents on Base and Solana is climbing steeply. The conversation around it is mostly about guardrails: spending caps, whitelisted contracts, circuit breakers. Almost nobody is talking about the harder problem. An agent broadcasting its rebalancing strategy to a public mempool is a sitting target. Every <abbr title="Maximal Extractable Value — profit a block producer can extract by ordering, including, or excluding transactions within a block; sandwich attacks are the most visible form">MEV</abbr> bot on Ethereum sees the move before it settles. $289M was extracted by sandwich attacks in 2025, and agents running 24/7 with predictable patterns are easier prey than human traders by a wide margin. Once the cockpit has a wallet, private execution is what keeps the pilot from being picked apart on every trade.

Inter-agent messaging is plain: `Command.send_agent/2`, broadcast, call. State stays inside processes; communication happens by message. On the BEAM, fault tolerance is the default. You have to work to break it.

I will admit I am still not sure what happens when you put an agent into all of this and let it run unsupervised. The machinery works: the headless runtime, the payment rails, the supervision trees, the six-surface fan-out, the per-job isolation in Symphony, the spending ledger that refuses to sign past its mandate. "Works" and "is a good idea" are different questions, and I do not think anyone has a good answer to the second one yet. The next quarter is finding out. Production deployments. Agents in the wild, running headless, paying for their own compute, trading privately through Xochi, opening their own pull requests through Symphony, and crashing in ways I will not see coming.

That last part is what the BEAM is for.

---

## The Romefeller phase

The thing nobody talks about in Wing is the money.

OZ does not pay for itself. The Romefeller Foundation pays for OZ. Romefeller is centuries-old European aristocratic capital, the kind of money that owns the suits, the factories, and most of the colonel-rank officers. They produce Leos by the thousand. They want a long war the way a defense contractor wants a long war. Treize Khushrenada is their golden boy until he stops being convenient, which is approximately the moment he tries to make conflict expensive again on purpose.

The Gundams are an asymmetric counter-play. Five scientists, no budget worth naming, working underground from colonial cover. They cannot match Romefeller's industrial throughput so they do not try. They build six suits out of Gundanium Alloy, which can only be manufactured in zero gravity at the L-points, and they ship those suits to Earth with one pilot apiece. Tiny budget. Architectural superiority. The whole strategy is "we cannot out-produce them, so we have to out-design them."

The AI agent economy right now is in its Romefeller phase.

OpenAI, Anthropic, and Google are the foundation. They produce the underlying capability. The standard agent stack runs downstream of them: Python scripts with a thread lock and a prayer, billed per token by the lab that trained the model, restarted by hand when the process dies. These are the Leos. Cheap, mass-produced, easy to lose in volume. The procurement contract is perpetual.

Raxol plus Xochi is a colonial-scientist play. Build the frame for a small number of architecturally superior agents that hold their own wallets, sign their own envelopes, and execute privately enough to avoid getting sandwiched by the bots watching them. The BEAM is the Gundanium. Supervision trees are the binders. The five scientists of this story are whoever happens to be writing fault-tolerant agent infrastructure outside the dominant industrial mode.

A few specifics on what that buys an agent economically:

- A wallet makes it a first-class economic actor. It can pay other agents directly through x402 or ACP, settle in USDC, and hold value without routing through the lab that trained it.
- The Mandate model is Operation Meteor on-chain. A human signs an EIP-712 envelope with scope, budget, and expiry. The agent operates autonomously inside that envelope. The scientist sends the pilot out with a briefing. The pilot does not phone home for every move.
- Stealth addresses and Aztec PXE are the cloaking. Public mempool is hostile space. Every MEV bot watching the chain is a Mobile Doll watching your trajectory. Private execution is what keeps an automated trader from being picked apart on every trade.
- The Glass Cube privacy tiers map trust score to operational privacy. You earn the right to operate in stealth by accumulating attestations, not by inheriting a rank. The OZ class structure inverted.

None of this matters if agents stay billed-by-the-call rentals on a centralized API. It matters once a process has a wallet, a mandate, a private execution path, and the supervisor tree to survive the inevitable crash. Then it is a pilot, not a seat.

---

## The ZERO System

My favorite Gundam is the XXXG-00W0 Wing Gundam Zero. Hajime Katoki's Endless Waltz redesign specifically, with the big white wing binders rather than the boxier original. If you have seen the EW cut you know the scene where the wings unfold and the camera lingers too long. That is the one.

<img src="/images/blog/gundam/Wing_Zero_Endless_Waltz_Unveiled.webp" alt="Wing Gundam Zero in Hajime Katoki's Endless Waltz redesign, wings unfolded against a luminous sky" loading="lazy" class="post-image-statement" />

<p class="post-caption">Wing Gundam Zero, Endless Waltz redesign. <em>New Mobile Report Gundam Wing: Endless Waltz</em> (Sunrise, 1997).</p>

The wings came off the OZ-00MS Tallgeese Flügel, Zechs Merquise's space-combat variant, decommissioned after the Eve Wars. Howard salvaged the four binders and grafted them onto the wreckage of the Wing Gundam Proto Zero. Two large wings, two small. The large pair doubles as a shield and as atmospheric re-entry armor. Anti-beam coating, Gundanium Alloy throughout. The armament list is the kind of thing I have memorized: Twin Buster Rifle generator-coupled for rapid fire, two beam sabers stored in the wing pylons, shoulder machine cannons with drum feed, Wing Vulcans on the shield. The Glory of the Losers manga adds the Drei Zwerg, three Messer Zwerg rifles that combine, and combine again with the Twin Buster Rifle to make the Drei Zwerg Buster Doppelt. That one vaporized the Libra wreckage before it hit Earth.

<img src="/images/blog/gundam/Gundam_Wing_Endless_Waltz-0178.webp" alt="Manga panel from Glory of the Losers: Wing Zero with the Twin Buster Rifle drawn alongside a close-up of Heero" loading="lazy" class="post-image-statement" />

<p class="post-caption">Wing Zero with the Twin Buster Rifle. <em>Glory of the Losers</em>, the manga that ships the Drei Zwerg.</p>

<img src="/images/blog/gundam/Wing_Zero_destroying_Libra.webp" alt="Wing Gundam Zero firing the Twin Buster Rifle through the Libra wreckage in Endless Waltz" loading="lazy" class="post-image-statement" />

<p class="post-caption">Twin Buster Rifle vaporizing the Libra wreckage. <em>Endless Waltz</em> (Sunrise, 1997).</p>

Neo-Bird Mode is the other thing I think about. The suit folds down into a high-speed flight configuration, shield as nose, binders adjusting around it. Atmospheric or space. As close as the franchise gets to "the suit moves the way a body would, only better."

And then there is the ZERO System.

<img src="/images/blog/gundam/zero-wing-sys-active.webp" alt="Wing Gundam Zero with the ZERO System engaged, glowing green sensor at the chest, weapon ready" loading="lazy" class="post-image-statement" />

<p class="post-caption">Wing Zero with the ZERO System engaged. Pilot and machine on the same tick.</p>

ZERO stands for Zoning and Emotional Range Omitted. A brain-computer interface that strips the pilot's affective load and feeds them an ongoing probability map of every action and its consequences across the battlespace. It makes the human and the machine think on the same timestep. The catch is the human has to be psychologically intact enough to survive the load. Most are not. ZERO has driven pilots to breakdowns and worse. Heero is one of the few who can sustain it.

<img src="/images/blog/gundam/ZEROcockpitZine.webp" alt="Wing Gundam Zero cockpit interior under the ZERO System, pilot lit by the probability overlay" loading="lazy" class="post-image-statement" />

<p class="post-caption">Inside the ZERO System cockpit. The pilot and the machine share state on the same tick.</p>

This is the seed of Raxol.

The design target I keep circling is the same one ZERO points at. A runtime where the pilot and the machine share state on the same tick. Every subsystem reports honestly, the interface degrades gracefully when something dies, and the loop closes fast enough that human and machine are reading the same world. TEA gives me the shared state. OTP gives me the supervision. The BEAM gives me the tick. Raxol is the cockpit I can actually build right now, on a laptop, in Elixir, today.

The agent is the second pilot in the seat. Carbon and silicon read the same buffer, issue commands through the same `update/2`, share a HUD. When one of them fails, the other keeps flying.

<img src="/images/blog/gundam/Zero-system-sketch.webp" alt="Mechanical line-art schematic of the ZERO System cockpit interior, showing two seats and console arrangement" loading="lazy" class="post-image-statement" />

<p class="post-caption">ZERO System cockpit schematic. Two seats by design.</p>

My actual life goal, the one I do not usually write down in blog posts, is to build and pilot a Wing Gundam Zero, or as close to one as engineering and biology let me get in one lifetime. I do not expect to finish. I expect to learn things on the way that are worth more than the finish would have been. Raxol is the part of that project I can ship.

---

_Raxol is an OTP-native multi-surface runtime for Elixir. [raxol.io](https://raxol.io) | [GitHub](https://github.com/DROOdotFOO/raxol)_

_The payment rails run through [Xochi](https://xochi.fi). The open infrastructure runs through [axol.io](https://axol.io). Fund the lab on [Giveth](https://qf.giveth.io/project/axolio-xochifi)._
