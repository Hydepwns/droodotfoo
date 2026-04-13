---
title: "Raxol: The Terminal for the Gundam"
date: "2026-04-07"
description: "What if the terminal was the agent runtime? MCP as rendering target, headless sessions, payment rails, and building a cockpit on the BEAM."
author: "DROO AMOR"
tags: ["elixir", "otp", "agents", "raxol", "tui", "beam"]
slug: "raxol-terminal-for-the-gundam"
pattern_style: "flow_field"
draft: true
---

<img src="/images/blog/Giovanni_Battista_Piranesi_-_Le_Carceri_d'Invenzione_-_Second_Edition_-_1761_-_14_-_The_Gothic_Arch.webp" alt="The Gothic Arch (Plate XIV) by Giovanni Battista Piranesi (1761) - Massive structural systems with walkways, machinery, and tiny human operators within vast architecture" loading="lazy" class="post-image-statement" />

<p class="post-caption"><em>Le Carceri d'Invenzione, Plate XIV: The Gothic Arch</em> (1761) - Giovanni Battista Piranesi</p>

# Two ideas colliding

I was watching an AI agent try to parse the output of `htop`. It had no idea what was on screen. It was reading raw text -- escape codes, cursor movements, color sequences -- trying to pull meaning out of noise. It couldn't scroll up. Couldn't check which process had focus. It gave up and shelled out to `top -l 1` because the terminal wasn't a structured environment. It was a dumb pipe.

First problem: a terminal for AI agents. A real terminal emulator where agents interact with structured screen state -- cursor positions, scroll regions, alternate screens -- addressable buffers instead of raw byte streams.

<img src="/images/blog/Unforgettable_Gundam_Corin_Nander_Wing_Gundam_Zero.webp" alt="Wing Gundam Zero reflected in Corin Nander's eyes - the unforgettable image from Turn A Gundam (Sunrise, 1999)" loading="lazy" class="post-image-statement" />

<p class="post-caption">Wing Gundam Zero reflected in Corin Nander's eyes. <em>Turn A Gundam</em> (Sunrise, 1999)</p>

Second: the cockpit for a Gundam Wing Suit. Less a metaphor than a mental model. If you've seen Wing, the thing that makes the cockpit compelling isn't the weapons. It's that every subsystem fails independently. Sensor goes dark, the HUD shows "NO DATA" instead of taking down the display. The pilot sees a degraded world, not a crashed one. Real fighter cockpits work the same way, but mech anime makes the design philosophy visceral -- you watch the pilot lose one system, then two, and keep flying with whatever's left.

The terminal IS the cockpit. The agent is just another pilot. And the only runtime that makes both work is the BEAM.

---

## What AI agents are missing

Watch how most AI coding agents work. Observe, decide, act. Read the state of the world. Pick a tool. Execute. Read the result. Loop.

The reasoning loop is clean. The runtime underneath isn't. Shelling out to `cat` and `grep` and `sed`. Reading files as strings and hoping the encoding is right. State management via a conversation window that gets compressed when it runs long. Single-threaded, no fault isolation, no hot reload. Good reasoning, duct-tape runtime.

That tells you two things. Agents want structured environments. An agent that can reason about terminal state -- what's on screen, where the cursor is, which pane has focus -- will outperform one that's parsing raw output every time. And the runtime matters as much as the model. The best reasoning engine in the world won't help when the process crashes and takes everything with it.

<img src="/images/blog/EW_Wing_Zero_console_panel_Activation.webp" alt="Wing Gundam Zero EW console panel - targeting display with structured sensor data, not raw output (Sunrise, 1997)" loading="lazy" class="post-image-float-right" />

Give an agent a real VT100 buffer instead of a text pipe and it can read a specific screen region instead of dumping an entire file. It can check what's visible. It can scroll. Raxol does this -- a terminal emulator in Elixir, backed by a screen buffer. Agents get structured access to terminal state. Not escape codes. State.

---

## TEA for everything

Raxol uses the Elm Architecture. `init`, `update`, `view` -- three callbacks, and you get a supervised application. Whether that application is a counter, a file browser, or an AI agent streaming from Claude.

```elixir
# Human-operated counter
defmodule Counter do
  use Raxol.App

  def update(:increment, model), do: {%{model | count: model.count + 1}, []}
  def update(:decrement, model), do: {%{model | count: model.count - 1}, []}
end

# AI agent -- same architecture, different input source
defmodule CodeReviewer do
  use Raxol.Agent

  def update({:review, file_path}, model) do
    # NB: sanitize file_path in production -- this is a simplified example
    {model, [Command.read_file(file_path), Command.async(&call_llm/1)]}
  end

  def update({:llm_response, analysis}, model) do
    {%{model | reviews: [analysis | model.reviews]}, []}
  end
end
```

One gets keystrokes. The other gets LLM responses. Both supervised, both hot-reloadable. If the code reviewer crashes mid-analysis, the supervisor restarts it. The human's counter keeps counting.

The difference between a human app and an AI agent is where the input comes from. Agents can have a `view/1` that renders to the terminal, or skip it entirely and run headless. The runtime doesn't care.

This is the piece most agent frameworks get wrong. They bolt a separate "agent SDK" onto a language and end up rebuilding supervision, state management, and lifecycle hooks from scratch. In Raxol, agents and interfaces are the same thing. How you process messages is your business. ReAct, Chain-of-Thought, FSM with guards -- different implementations of `update/2`.

---

## The cockpit

Think about what happens when your AI copilot hallucinates.

In most frameworks, a bad tool call cascades. Process crashes, state is lost, restart from scratch if you're lucky. If you're not, it corrupts shared state and takes other agents with it.

In Raxol, the agent is an OTP process. It crashes. The supervision tree catches it. The cockpit stays up. The agent restarts with last known good state. The HUD shows a blip -- one gauge flickers, resets, comes back with stale-but-safe data while the fresh state loads. The pilot keeps flying.

<img src="/images/blog/gundam-cockpit-concept.webp" alt="Gundam cockpit HUD with independent gauges for armor, boost, radar, ammo, and battle log - each subsystem reports independently (Bandai Namco)" loading="lazy" class="post-image-statement" />

<p class="post-caption">Every subsystem is a separate gauge. When one fails, the gauge says NO DATA. The pilot keeps flying. (Bandai Namco)</p>

I keep coming back to how right this feels as a design target. High availability in a very specific sense -- _graceful degradation as a UI pattern_. A dozen systems feeding one interface -- navigation, sensors, comms, weapons -- each running independently, reporting to a unified HUD. When one dies, the gauge doesn't vanish. It says "NO DATA." The pilot sees a degraded but functional world. That distinction matters more than it sounds like it should.

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

Put an AI agent in that seat. It reads the same HUD. Processes sensor data through `update/2`. Issues commands -- reallocate resources, flag an anomaly, adjust course. The runtime executes them. Same interface, same state, same fault isolation. Carbon or silicon pilot.

Four rendering surfaces: terminal, browser via LiveView, SSH, and MCP tools -- where the terminal itself becomes an AI-accessible rendering target. One codebase. The agent connects over MCP or SSH. The human opens a browser. The ops team watches the terminal. Different windows into the same cockpit.

---

## Where it stands

The monolith became six extracted packages (core, terminal, sensor, mcp, liveview, plugin) with explicit dependency boundaries. Two more -- agent and payments -- are staged for extraction.

The sensor fusion HUD works. Distributed swarm with CRDTs works. Time-travel debugging lets you step backward through agent decisions and replay from any snapshot. 23 widgets and 7 streaming chart types, including a heatmap with braille resolution that I'm probably too proud of.

MCP is a first-class rendering target. `Raxol.MCP.ToolProvider` auto-derives tools from the widget tree -- an agent connecting over MCP doesn't just read terminal state, it can render to it. Model state gets exposed as MCP resources via app-declared projections, so the agent reasons about widgets the same way a human reads a dashboard. `mix mcp.server` starts in ~18ms on stdio.

The headless session manager (`Raxol.Headless`) runs TEA apps without a terminal attached. Agents don't need a screen to operate. Full lifecycle, state management, supervision -- no rendering overhead.

`raxol_payments` ships x402 micropayments and [Xochi](https://xochi.fi) cross-chain payment rails as a first-class package. The router picks the protocol: cross-chain intents go through Xochi's solver network (stealth smart accounts, tier-based fees), same-chain through x402. An agent submits an intent, Riddler fills it in ~2 seconds, funds land in a stealth account. No human approval loop, no mempool exposure.

Think about what that means. An agent broadcasting its rebalancing strategy to a public mempool is a sitting target -- every MEV bot on Ethereum sees the move before it settles. $289M was extracted via sandwich attacks on Ethereum in 2025, and agents running 24/7 with predictable patterns are even easier prey than human traders. Private execution isn't a feature for autonomous agents. It's survival. The cockpit has a wallet.

Inter-agent messaging is built -- `Command.send_agent/2`, broadcast, call. No shared mutable state. Just messages, just the BEAM. You don't architect fault tolerance into a BEAM application. You get it by default and have to work to break it.

I'm genuinely not sure what happens when you give agents their own wallets and let them run unsupervised. The machinery works -- the headless runtime, the payment rails, the fault isolation. But "works" and "is a good idea" are different questions, and I don't think anyone has good answers yet. What comes next is finding out. Production deployments. Agents in the wild, running headless, paying for their own compute, trading privately through Xochi.

---

_Raxol is an OTP-native terminal framework for Elixir. [raxol.io](https://raxol.io) | [GitHub](https://github.com/DROOdotFOO/raxol)_
