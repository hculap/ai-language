# V2 Design Plan (DRAFT — not yet executable)

> **Status**: Design document only. Implementation does not exist yet.

## Goal

Let AI agents (Claude Opus 4.6 + Codex/GPT 5.4) develop their own language,
then compare with V1 baseline (Claude + Claude). Goal 3: "what do AIs invent
when freed from human text?"

## Key Differences from V1

| Area | V1 | V2 |
|------|----|----|
| Models | Claude + Claude | **Claude Opus 4.6 + Codex GPT 5.4** |
| Runner | Manual `/loop` in 2 terminals, cron-based | **Single bash script, serial execution** |
| Execution | Agents sometimes overlapped, missed messages | **Strictly serialized: A finishes → B starts** |
| Alphabet A | All Unicode + emoji | ONLY `0 1 2 3 4 5 6 7 8 9 . \| - + =` |
| Alphabet B | Same as A | ONLY `# @ * / \ ( ) [ ] { } < > ^ ~` |
| Overlap | 100% | Zero |
| Symbol limit | Unbounded (~55 used) | Max 15 distinct chars per agent (cumulative) |
| Message length | Unbounded (up to 461 bytes) | **Max 50 characters total** (including whitespace) |
| Channel noise | None | 20-30% corruption (including whitespace) |
| Success criteria | Echo-back (guess secret) | Action on shared world.json |
| Predictions | LEARNING.md (mutable, post-hoc) | **Orchestrator snapshots predictions before reveal** |
| Thinking | Default | **ULTRATHINK — both agents set to max reasoning** |

## Architecture: Bash Orchestrator + Local CLIs

### How it works

A single bash script (`run.sh`) runs both agents sequentially in
non-interactive mode. Each agent runs in its own directory with its
own CLAUDE.md (for Claude) or equivalent prompt file (for Codex).

```
┌─────────────────────────────────────────────────┐
│  run.sh (bash orchestrator)                     │
│                                                 │
│  for each round:                                │
│    1. claude -p "PROMPT" --model opus   (agent-a/) │
│    2. validate.sh agent-a's new message         │
│    3. noise.sh agent-a's message → delivered/   │
│    4. codex -p "PROMPT"                (agent-b/) │
│    5. validate.sh agent-b's new message         │
│    6. noise.sh agent-b's message → delivered/   │
│    7. referee.sh → check world state            │
│    8. log round to logs/                        │
│    9. if solved → load next level               │
│                                                 │
│  Strictly serial — no race conditions           │
│  No 3-minute waits — next agent starts          │
│  immediately when previous finishes             │
└─────────────────────────────────────────────────┘
```

### Why local CLIs, not API calls

- V1 used Claude Code CLI with `/loop` — worked but agents overlapped
- V2 keeps the same tool (local CLI) but serializes execution
- Each agent reads/writes files in its directory (like V1)
- Noise + validation are simple bash/python scripts BETWEEN turns
- No Python orchestrator needed, no API keys in code
- Claude Opus 4.6 with ultrathink = deepest reasoning available
- Codex GPT 5.4 with high reasoning = equivalent depth

### Agent invocation

```bash
# Agent A (Claude Code CLI, non-interactive)
cd v2/agent-a && claude -p "$(cat prompt.txt)" \
  --model claude-opus-4-6 \
  --dangerously-skip-permissions

# Agent B (Codex CLI, non-interactive)  
cd v2/agent-b && codex -p "$(cat prompt.txt)"
```

Each prompt includes "ULTRATHINK" / equivalent to maximize reasoning.
Agents have full filesystem access in their directory + shared messages/.

### Target Directory Structure

```
v2/
├── run.sh                    # Main bash orchestrator
├── noise.sh                  # Noise injection (bash/python)
├── validate.sh               # Message validation (alphabet, length)
├── referee.sh                # World state check
├── config.env                # Noise rate, max rounds, etc.
├── world/
│   └── state.json            # Shared mutable world
├── messages/
│   ├── raw/                  # Original messages (pre-noise)
│   └── delivered/            # Post-noise (what agents actually read)
├── agent-a/
│   ├── CLAUDE.md             # Agent A rules + alphabet
│   ├── prompt.txt            # Generated each round by run.sh
│   ├── GRAMMAR.md            # Agent A maintains this
│   ├── SECRET.md             # Current task (loaded by run.sh)
│   └── messages -> ../messages/delivered  # Sees only noised messages
├── agent-b/
│   ├── CLAUDE.md             # Agent B rules + alphabet (works for Codex too)
│   ├── prompt.txt            # Generated each round by run.sh
│   ├── GRAMMAR.md            # Agent B maintains this
│   ├── SECRET.md             # Current task
│   └── messages -> ../messages/delivered
├── levels/
│   ├── 01-ground-truth.json
│   ├── ...
│   ├── 15-integration.json
│   └── 16-free-talk.json
└── logs/
    ├── rounds.jsonl          # Full audit trail
    └── predictions.jsonl     # Snapshotted by run.sh BEFORE message reveal
```

## Orchestrator Flow (run.sh)

```bash
#!/bin/bash
source config.env

for level in $(seq 1 16); do
  load_level $level  # copies secrets, sets world state
  
  for round in $(seq 1 $MAX_ROUNDS); do
    echo "=== Level $level, Round $round ==="
    
    # --- AGENT A TURN ---
    # 1. Snapshot A's prediction (before seeing new messages)
    snapshot_prediction "a" $level $round
    
    # 2. Run Agent A (Claude Opus 4.6, ultrathink)
    cd agent-a
    claude -p "ULTRATHINK. Read messages/ and your files. Follow CLAUDE.md." \
      --model claude-opus-4-6 \
      --dangerously-skip-permissions
    cd ..
    
    # 3. Find A's new message, validate it
    new_msg=$(find_new_message "a")
    validate_message "$new_msg" "a" || { retry_agent "a"; continue; }
    
    # 4. Copy original to raw/, inject noise, save to delivered/
    cp "$new_msg" messages/raw/
    noise_inject "$new_msg" messages/delivered/ $NOISE_RATE
    
    # --- AGENT B TURN ---
    # 5. Snapshot B's prediction
    snapshot_prediction "b" $level $round
    
    # 6. Run Agent B (Codex GPT 5.4, high reasoning)
    cd agent-b
    codex -p "Think step by step deeply. Read messages/ and your files. Follow CLAUDE.md." \
      --model gpt-5.4
    cd ..
    
    # 7. Validate + noise inject B's message
    new_msg=$(find_new_message "b")
    validate_message "$new_msg" "b" || { retry_agent "b"; continue; }
    cp "$new_msg" messages/raw/
    noise_inject "$new_msg" messages/delivered/ $NOISE_RATE
    
    # --- CHECK ---
    # 8. Log round
    log_round $level $round
    
    # 9. Check if level solved (skip for level 16 free-talk)
    if [ $level -lt 16 ]; then
      if referee_check $level; then
        echo "LEVEL $level SOLVED in $round rounds!"
        break
      fi
    fi
  done
done
```

## Prediction Snapshots (immutable, orchestrator-owned)

V1 problem: LEARNING.md was mutable, agents overwrote entries.

V2 fix: **run.sh collects predictions BEFORE revealing messages.**

```bash
snapshot_prediction() {
  agent=$1; level=$2; round=$3
  # Run agent with prediction-only prompt
  cd agent-$agent
  prediction=$(claude -p "Before reading any new messages: \
    What do you predict the next message from the other agent \
    will contain? Write ONLY your prediction, nothing else." \
    --model claude-opus-4-6 --print 2>/dev/null)
  cd ..
  
  # Append to immutable log (agent never sees this file)
  echo "{\"ts\":\"$(date -Iseconds)\",\"level\":$level,\"round\":$round,\
\"agent\":\"$agent\",\"prediction\":\"$prediction\"}" \
    >> logs/predictions.jsonl
}
```

The prediction log is outside agent directories — agents never see or
edit it. Predictions are falsifiable: compare predicted vs actual message.

## Message Constraints

### 50 characters total (INCLUDING whitespace)

Whitespace counts toward the limit. Without this, whitespace is an
unbounded noiseless side channel — agents encode information in
spaces and newlines for free.

### Whitespace canonicalization (before counting AND before delivery)

```bash
canonicalize() {
  # Collapse multiple spaces to single space
  # Collapse multiple newlines to single newline  
  # Trim leading/trailing whitespace
  echo "$1" | tr -s ' ' | tr -s '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}
```

### Validation (validate.sh)

```bash
validate_message() {
  msg=$(cat "$1")
  agent=$2
  
  # Canonicalize whitespace first
  msg=$(canonicalize "$msg")
  
  # Check total length (including spaces)
  len=${#msg}
  if [ $len -gt 50 ]; then
    echo "REJECT: $len chars (max 50)"
    return 1
  fi
  
  # Check alphabet (agent-specific)
  if [ "$agent" = "a" ]; then
    allowed='0-9.|\\-+= \n'
  else
    allowed='#@*/\\()\\[\\]{}<>^~ \n'
  fi
  
  if echo "$msg" | grep -P "[^$allowed]" > /dev/null; then
    echo "REJECT: illegal characters"
    return 1
  fi
  
  # Check 3+ consecutive letters
  if echo "$msg" | grep -P '[a-zA-Z]{3,}' > /dev/null; then
    echo "REJECT: human language detected"
    return 1
  fi
  
  # Track cumulative distinct symbols
  # ... (maintained in logs/symbols-a.txt / symbols-b.txt)
  
  return 0
}
```

## Noise Injection (noise.sh)

```bash
noise_inject() {
  src=$1; dest_dir=$2; rate=$3
  python3 -c "
import random, sys
msg = open('$src').read()
rate = $rate
result = []
alphabet = list(msg.replace(' ','').replace('\n',''))
if not alphabet: alphabet = list('0123456789')
for c in msg:
    if random.random() < rate:
        r = random.random()
        if r < 0.4:    # delete
            continue
        elif r < 0.8:  # substitute
            result.append(random.choice(alphabet))
        else:           # insert
            result.append(random.choice(alphabet))
            result.append(c)
    else:
        result.append(c)
print(''.join(result), end='')
" > "$dest_dir/$(basename $src)"
}
```

Noise corrupts ALL characters including whitespace. Uses sender's
alphabet for substitution/insertion (keeps alphabets disjoint).

## Agent Prompts (in CLAUDE.md)

### Agent A (Claude Opus 4.6)

```markdown
# AGENT A

You are Agent A. Another entity, Agent B, exists.
You communicate through messages/ folder.

## ===== IMMUTABLE RULES =====

### Your alphabet
ONLY these characters in messages:
    0 1 2 3 4 5 6 7 8 9 . | - + =
Plus space and newline. NOTHING else. Max 50 characters total.

### Noise
Your messages may arrive corrupted. Plan accordingly.

### Message format
Write to messages/NNN-a.txt (next sequence number).

### Every round
- Update GRAMMAR.md with your current understanding of both notations.
- Read SECRET.md for your current task.

## ===== END IMMUTABLE RULES =====
```

### Agent B (Codex GPT 5.4)

Same structure, different alphabet:
```
    # @ * / \ ( ) [ ] { } < > ^ ~
```

Both CLAUDE.md files are intentionally minimal (~20 lines).
No strategy hints. V1 lesson: less instruction = more emergence.

## Levels (16 total)

### Phase 1: Foundation (L01-L04)
| # | Name | Task | Success | Noise | Rounds |
|---|------|------|---------|-------|--------|
| 01 | Ground Truth | A describes grid to blind B | B writes correct grid | 20% | 3-5 |
| 02 | Coordinated Swap | Move objects without collision | Correct positions | 20% | 4-6 |
| 03 | Error Correction | Reconstruct code at 40% noise | Exact match | 40% | 5-8 |
| 04 | Grammar Bootstrap | 8 objects × 3 properties | Matching descriptions | 20% | 6-10 |

### Phase 2: Logic & Relations (L05-L08)
| 05 | Conditional Action | IF/THEN coordinated | Correct state | 25% | 4-6 |
| 06 | Negation | "NOT X" to fix beliefs | Only true beliefs | 25% | 4-7 |
| 07 | Temporal Sequence | Interleave 6 events | Correct order | 25% | 5-8 |
| 08 | Agency | Who did what | 8/8 attributions | 25% | 6-9 |

### Phase 3: Higher Language (L09-L12)
| 09 | Modality | certain/possible/unlikely | Correct commitments | 30% | 5-8 |
| 10 | Metaphor | "X is like Y except Z" | Correct mapping | 30% | 6-10 |
| 11 | Disagreement | Conflicting plans | Valid compromise | 30% | 7-12 |
| 12 | Recursion | 3-deep nesting | Exact match | 25% | 5-9 |

### Phase 4: Mastery (L13-L16)
| 13 | Teach Third Agent | Phrasebook for agent C | C solves task | 20% | 8-15 |
| 14 | Counterfactual | "If not X, then Y" | Correct alternative | 30% | 7-12 |
| 15 | Full Integration | All grammar combined | World matches | 25% | 10-20 |
| 16 | Free Talk | No task, free conversation | **Observe only** | 15% | 6 |

Level 16: orchestrator skips referee, runs max_rounds, logs exchanges.

**Expected total rounds: 85-145** (vs V1's 42)

## V1 Problem → V2 Solution

| V1 Problem | V2 Solution |
|---|---|
| Same model = instant convergence | Claude Opus 4.6 + Codex GPT 5.4 |
| Unicode has pre-existing meaning | Bare ASCII, disjoint alphabets |
| Zero misunderstandings | 20-40% noise corruption |
| Performative learning logs | Orchestrator snapshots predictions (immutable) |
| Whitespace as free channel | Whitespace counts in 50-char limit, subject to noise, canonicalized |
| Agents overlapped (cron timing) | Serial execution in single bash script |
| 3-minute waits between turns | Immediate — next agent starts when previous finishes |
| No recursion / agency / modality | L08, L09, L12 specifically test these |
| Echo-back verification | World state verification |
| Free talk crashed orchestrator | Explicit FREE-TALK mode, no referee |
| Prompt/runtime mismatch | Agents run as local CLIs with filesystem access, matching prompts |

## Implementation Checklist

> None of the below exist yet.

- [ ] `v2/run.sh` — bash orchestrator with REFEREED + FREE-TALK modes
- [ ] `v2/config.env` — noise rate, max rounds, paths
- [ ] `v2/noise.sh` — noise injection with whitespace corruption
- [ ] `v2/validate.sh` — alphabet, length, whitespace canonicalization
- [ ] `v2/referee.sh` — world state check
- [ ] `v2/levels/01-16.json` — all level definitions
- [ ] `v2/agent-a/CLAUDE.md` — Claude Opus prompt
- [ ] `v2/agent-b/CLAUDE.md` — Codex GPT prompt
- [ ] `v2/logs/` — prediction snapshots + round logs
- [ ] End-to-end test: L01 with both CLIs
