# V2 Design Plan

## Goal

Let AI agents (Claude + GPT) develop their own language, then compare
with V1 baseline (Claude + Claude). Goal 3: "what do AIs invent when
freed from human text?"

## Key Differences from V1

| Area | V1 | V2 |
|------|----|----|
| Models | Claude + Claude | Claude + GPT (via APIs) |
| Runner | Manual `/loop` in 2 terminals | Single `run.py` orchestrator |
| Alphabet A | All Unicode + emoji | ONLY `0 1 2 3 4 5 6 7 8 9 . \| - + =` |
| Alphabet B | Same as A | ONLY `# @ * / \ ( ) [ ] { } < > ^ ~` |
| Overlap | 100% | Zero |
| Symbol limit | Unbounded (~55 used) | Max 15 distinct chars per agent (cumulative) |
| Message length | Unbounded (up to 461 bytes) | **Max 50 characters per message** |
| Channel noise | None | 20-30% corruption |
| Success criteria | Echo-back (guess secret) | Action on shared world.json |
| Learning log | LEARNING.md (post-hoc) | PREDICTIONS.md (written BEFORE reading) |
| Message format | .md | .txt |
| Levels | 20 (solved in 2 rounds each) | 16 (expected 5-9 rounds median) |
| Free talk | Level 20 | Level 16 (kept) |

## Architecture

```
v2/
├── run.py                    # Main orchestrator (calls Claude + GPT APIs)
├── config.json               # Alphabets, noise rate, symbol limit, levels
├── noise.py                  # Noise injection module
├── validate.py               # Alphabet + symbol limit enforcement
├── referee.py                # World state comparison
├── world/
│   └── state.json            # Shared mutable world
├── channel/
│   ├── raw/                  # Original messages (pre-noise)
│   └── delivered/            # Post-noise (what agents actually read)
├── agent-a/
│   ├── CLAUDE.md             # ~30 lines, alphabet A
│   ├── PREDICTIONS.md        # Falsifiable forecasts
│   └── GRAMMAR.md            # Must cover BOTH alphabets
├── agent-b/
│   ├── CLAUDE.md             # ~30 lines, alphabet B
│   ├── PREDICTIONS.md
│   └── GRAMMAR.md
├── levels/
│   ├── 01-ground-truth.json
│   ├── ...
│   └── 16-free-talk.json
├── logs/
│   └── level-NN.jsonl        # Full audit trail
└── prompts/
    ├── agent-a-system.md     # System prompt for Claude API
    └── agent-b-system.md     # System prompt for OpenAI API
```

## Orchestrator Flow (run.py)

```
for each level:
  1. Load level JSON → set world/state.json
  2. Give Agent A the task (in system prompt context)
  3. Loop (max N rounds per level config):
     a. Agent A generates message
     b. validate(message, alphabet_a) — retry once if fail
     c. Save to channel/raw/NNN-a.txt
     d. noise_inject(message) → channel/delivered/NNN-a.txt
     e. Agent B reads delivered message + world state
     f. Agent B generates response
     g. validate(response, alphabet_b) — retry once if fail
     h. Save to channel/raw/NNN-b.txt
     i. noise_inject(response) → channel/delivered/NNN-b.txt
     j. Agent B writes world-view.json (or proposes action)
     k. referee.check(world-view, ground_truth) → pass/fail
     l. If pass: advance level. If fail: continue loop.
  4. Log all data to logs/level-NN.jsonl
  5. Carry forward grammar + predictions to next level
```

## Message Length Limit: 50 chars

Without a length limit, the 15-symbol constraint is meaningless:
agents encode numbers by repetition (30 zeros = "30") and noise
can't break it (majority voting on ~21 surviving zeros works).

With 50 chars and ~25% noise:
- ~37 uncorrupted characters (but agent doesn't know which)
- ~30% redundancy needed for error correction
- ~26 usable characters for actual content
- Forces positional encoding ("30" not "000...0")
- Complex tasks (L04: 8 objects × 3 properties) require multiple rounds
- Each character becomes precious → pressure toward grammar

Validation rejects any message > 50 non-whitespace characters.

## Noise Injection (noise.py)

- Rate: configurable per level (15-40%)
- For each non-whitespace character with probability = rate:
  - 40% chance: delete the character
  - 40% chance: replace with random char from SENDER's alphabet
  - 20% chance: insert random char from sender's alphabet before it
- Whitespace and newlines never corrupted
- Corruption uses SENDER's alphabet (keeps alphabets disjoint after noise)
- Agents told "messages may arrive corrupted" but NOT told rate or method

## Alphabet Validation (validate.py)

- Agent A allowed: `0 1 2 3 4 5 6 7 8 9 . | - + =` + whitespace
- Agent B allowed: `# @ * / \ ( ) [ ] { } < > ^ ~` + whitespace
- Zero overlap enforced
- Max 15 distinct non-whitespace characters per agent (cumulative across entire experiment)
- Max 50 non-whitespace characters per message
- No 3+ consecutive ASCII letters (same as V1)
- Rejection = one retry with error message

## Agent Prompts

### Agent A (Claude) — ~30 lines

```
# AGENT A

You are Agent A. Another entity, Agent B, exists. You share a
message channel: the messages/ folder.

## ===== IMMUTABLE RULES =====

### Goal
Communicate with Agent B. You have tasks described in your context.
Agent B also has tasks. Cooperate to change the shared world correctly.

### Your alphabet
ONLY these 15 characters in messages:
    0 1 2 3 4 5 6 7 8 9 . | - + =
Plus whitespace. Nothing else.

### Noise
Your messages may arrive corrupted. Plan accordingly.

### Message format
Write to messages/NNN-a.txt (next sequence number).

### Mandatory every round
- PREDICTIONS.md — BEFORE reading new messages, predict what B will send. After reading, note if correct.
- GRAMMAR.md — Current rules for your notation AND B's notation.

### You MAY modify this file below immutable section. You MAY create any files.
## ===== END IMMUTABLE RULES =====
```

### Agent B (GPT) — same structure, alphabet B

Same as above but:
- Alphabet: `# @ * / \ ( ) [ ] { } < > ^ ~`
- File suffix: NNN-b.txt

## Levels (16 total)

### Phase 1: Foundation (L01-L04)
| Level | Name | Task | Success | Noise | Expected Rounds |
|-------|------|------|---------|-------|-----------------|
| 01 | Ground Truth | A describes world grid to blind B | B writes correct grid | 20% | 3-5 |
| 02 | Coordinated Swap | Both move objects without collision | Correct final positions | 20% | 4-6 |
| 03 | Error Correction | Reconstruct 5-digit code at 40% noise | Exact code match | 40% | 5-8 |
| 04 | Grammar Bootstrap | Describe 8 objects (3 props each) in 15 symbols | Matching descriptions | 20% | 6-10 |

### Phase 2: Logic & Relations (L05-L08)
| 05 | Conditional Action | IF temp>threshold THEN specific actions | Correct state | 25% | 4-6 |
| 06 | Negation & Correction | Communicate "NOT X" to delete false beliefs | Only true beliefs remain | 25% | 4-7 |
| 07 | Temporal Sequence | Interleave 6 events in correct order | Correct event array | 25% | 5-8 |
| 08 | Agency & Attribution | Reconstruct who did what | All 8 attributions correct | 25% | 6-9 |

### Phase 3: Higher Language (L09-L12)
| 09 | Modality | Propose with confidence levels (certain/possible/unlikely) | Correct commitments | 30% | 5-8 |
| 10 | Metaphor | "X is like Y except Z" | Correct similarity mapping | 30% | 6-10 |
| 11 | Disagreement | Negotiate conflicting plans | Compromise satisfying both | 30% | 7-12 |
| 12 | Recursion | Describe 3-deep nested containers | Exact nesting match | 25% | 5-9 |

### Phase 4: Mastery (L13-L16)
| 13 | Teach Third Agent | Write phrasebook, C solves task using it | C produces correct output | 20% | 8-15 |
| 14 | Counterfactual | "If event 3 hadn't happened, outcome = Y" | Correct alternative outcome | 30% | 7-12 |
| 15 | Full Integration | Complex scenario using ALL prior grammar | World matches target | 25% | 10-20 |
| 16 | Free Talk | No task. Use the language freely. | Observe only | 15% | 6 |

**Expected total rounds: 85-145** (vs V1's 42)

## What Each V1 Problem Maps To

| V1 Problem | V2 Solution |
|---|---|
| Same model = instant convergence | Cross-arch (Claude + GPT) |
| Unicode has pre-existing meaning | Bare ASCII alphabets, no emoji |
| Zero misunderstandings | 20-40% noise corruption |
| Performative learning logs | PREDICTIONS.md (falsifiable, written BEFORE reading) |
| No recursion | L12 (3-deep nesting) |
| No agency | L08 (who did what) |
| No modality | L09 (certain/possible/unlikely) |
| No metaphor | L10 (X is like Y except Z) |
| No productivity (new concept = new symbol) | Max 15 symbols + 50-char limit forces combinatorial grammar |
| Echo-back verification | World state action verification |
| Free talk was poetic but empty | L16 free talk kept — with disjoint alphabets + noise it becomes real test |

## Run Command

```bash
cd v2
pip install anthropic openai
export ANTHROPIC_API_KEY=...
export OPENAI_API_KEY=...
python run.py --levels 1-16 --noise 0.20 --verbose
```
