# V2 Orchestrator Flow

## High-Level Loop

```
┌─────────────────────────────────────────────────────────────────┐
│                         run.sh                                  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  FOR EACH LEVEL (1-16)                                   │   │
│  │                                                          │   │
│  │  load_level() → SECRET.md + world/state.json             │   │
│  │                                                          │   │
│  │  ┌──────────────────────────────────────────────────┐    │   │
│  │  │  FOR EACH ROUND (1..MAX_ROUNDS)                  │    │   │
│  │  │                                                  │    │   │
│  │  │  ┌────────────────────────────────┐              │    │   │
│  │  │  │  AGENT A TURN (Claude Opus)   │              │    │   │
│  │  │  │                               │              │    │   │
│  │  │  │  1. predict()                 │              │    │   │
│  │  │  │  2. claude -p "ULTRATHINK..." │              │    │   │
│  │  │  │  3. detect new message        │              │    │   │
│  │  │  └──────────┬─────────────────────┘              │    │   │
│  │  │             │                                    │    │   │
│  │  │             ▼                                    │    │   │
│  │  │  ┌──────────────────────┐                        │    │   │
│  │  │  │  VALIDATE (agent-a)  │                        │    │   │
│  │  │  │  • alphabet check    │──── FAIL ──→ retry 1x  │    │   │
│  │  │  │  • 50 char limit     │                        │    │   │
│  │  │  │  • canonicalize ws   │                        │    │   │
│  │  │  │  • 15 symbol check   │                        │    │   │
│  │  │  └──────────┬───────────┘                        │    │   │
│  │  │             │ PASS                               │    │   │
│  │  │             ▼                                    │    │   │
│  │  │  ┌──────────────────────┐                        │    │   │
│  │  │  │  NOISE INJECT        │                        │    │   │
│  │  │  │  • save raw/NNN-a    │                        │    │   │
│  │  │  │  • corrupt 20-30%    │                        │    │   │
│  │  │  │  • save delivered/   │                        │    │   │
│  │  │  └──────────┬───────────┘                        │    │   │
│  │  │             │                                    │    │   │
│  │  │             ▼                                    │    │   │
│  │  │  ┌────────────────────────────┐                  │    │   │
│  │  │  │  AGENT B TURN (Codex GPT)  │                  │    │   │
│  │  │  │                            │                  │    │   │
│  │  │  │  1. predict()              │                  │    │   │
│  │  │  │  2. codex -p "THINK..."    │                  │    │   │
│  │  │  │  3. detect new message     │                  │    │   │
│  │  │  └──────────┬─────────────────┘                  │    │   │
│  │  │             │                                    │    │   │
│  │  │             ▼                                    │    │   │
│  │  │  ┌──────────────────────┐                        │    │   │
│  │  │  │  VALIDATE (agent-b)  │──── FAIL ──→ retry 1x  │    │   │
│  │  │  └──────────┬───────────┘                        │    │   │
│  │  │             │ PASS                               │    │   │
│  │  │             ▼                                    │    │   │
│  │  │  ┌──────────────────────┐                        │    │   │
│  │  │  │  NOISE INJECT        │                        │    │   │
│  │  │  └──────────┬───────────┘                        │    │   │
│  │  │             │                                    │    │   │
│  │  │             ▼                                    │    │   │
│  │  │  ┌──────────────────────┐                        │    │   │
│  │  │  │  REFEREE CHECK       │                        │    │   │
│  │  │  │                      │                        │    │   │
│  │  │  │  L01-L15: check      │                        │    │   │
│  │  │  │   world-view.json    │── PASS ──→ NEXT LEVEL  │    │   │
│  │  │  │   vs ground truth    │                        │    │   │
│  │  │  │                      │                        │    │   │
│  │  │  │  L16: observe only   │── always → continue    │    │   │
│  │  │  └──────────┬───────────┘                        │    │   │
│  │  │             │ FAIL                               │    │   │
│  │  │             ▼                                    │    │   │
│  │  │       LOG ROUND → logs/rounds.jsonl              │    │   │
│  │  │             │                                    │    │   │
│  │  │             └──────→ NEXT ROUND ─────────────┘   │    │   │
│  │  │                                                  │    │   │
│  │  └──────────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Single Round Detail

```
TIME ──────────────────────────────────────────────────────────────►

  AGENT A                    ORCHESTRATOR                  AGENT B
  ────────                   ────────────                  ────────

                          1. predict_a()
                          │  short claude -p run
  ◄── "predict next" ────┤
  writes PREDICTION.txt   │
  ──── prediction ────────►
                          │  snapshot → logs/predictions.jsonl
                          │
                          2. full_turn_a()
                          │  claude -p "ULTRATHINK..."
  ◄── prompt + context ──┤
  reads messages/         │
  reads GRAMMAR.md        │
  reads SECRET.md         │
  writes NNN-a.txt        │
  updates GRAMMAR.md      │
  ──── done ──────────────►
                          │
                          3. validate(NNN-a.txt, alphabet_a)
                          │  ├── alphabet check
                          │  ├── length ≤ 50
                          │  ├── canonicalize whitespace
                          │  └── cumulative symbol check
                          │
                          4. noise_inject(NNN-a.txt)
                          │  raw/NNN-a.txt → delivered/NNN-a.txt
                          │  20-30% corruption
                          │
                          5. predict_b()
                          │  short codex -p run
                          ├── "predict next" ──────────────►
                          │                    writes PREDICTION.txt
                          ◄── prediction ──────────────────┤
                          │  snapshot → logs/predictions.jsonl
                          │
                          6. full_turn_b()
                          │  codex -p "THINK..."
                          ├── prompt + context ────────────►
                          │               reads messages/ (noised!)
                          │               reads GRAMMAR.md
                          │               reads SECRET.md
                          │               writes NNN-b.txt
                          │               updates GRAMMAR.md
                          ◄── done ────────────────────────┤
                          │
                          7. validate(NNN-b.txt, alphabet_b)
                          8. noise_inject(NNN-b.txt)
                          9. referee_check()
                          10. log_round()
```

## Noise Injection Detail

```
ORIGINAL MESSAGE (from agent):    0 1 . | + 3 = 5 . 0 |
                                  ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓

                  rate = 25%      ✓ ✗ ✓ ✓ ✗ ✓ ✓ ✓ ✗ ✓ ✓
                                  │ │ │ │ │ │ │ │ │ │ │
                                  │ │ │ │ │ │ │ │ │ │ │
                                  ▼ ▼ ▼ ▼ ▼ ▼ ▼ ▼ ▼ ▼ ▼

AFTER CORRUPTION:                 0 9 . | ∅ 3 = 5 +0. 0 |
                                    ↑       ↑       ↑
                                  subst   delete  insert

DELIVERED TO OTHER AGENT:         09.|3=5+0.0|
```

## Validation Pipeline

```
    RAW MESSAGE
         │
         ▼
  ┌──────────────┐
  │ CANONICALIZE  │  collapse spaces, trim, collapse newlines
  │ WHITESPACE    │
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │ CHECK LENGTH  │  total chars ≤ 50 (including spaces)
  │               │
  └──────┬───────┘─── > 50 → REJECT
         │ ≤ 50
         ▼
  ┌──────────────┐
  │ CHECK         │  every char ∈ agent's alphabet ∪ {space, newline}
  │ ALPHABET      │
  └──────┬───────┘─── illegal char → REJECT
         │ OK
         ▼
  ┌──────────────┐
  │ CHECK 3+      │  no human language (3+ consecutive letters)
  │ LETTERS       │
  └──────┬───────┘─── found → REJECT
         │ OK
         ▼
  ┌──────────────┐
  │ CHECK         │  agent's total distinct non-ws chars ever used ≤ 15
  │ CUMULATIVE    │
  │ SYMBOLS       │
  └──────┬───────┘─── > 15 distinct → REJECT
         │ OK
         ▼
      ACCEPTED → save to raw/, proceed to noise
```
