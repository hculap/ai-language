# Emergent Language Experiment - Supervisor

## How it works

Agent A and Agent B each have a SECRET.md with something to convey.
They communicate through `messages/` using only symbolic language
(no human words allowed). Each agent must make the other understand
their secret, and write ANSWER.md when they think they've decoded
the other's secret.

## Current level: 01-numbers

- Agent A: the number 3
- Agent B: the number 7

## Levels

Secrets are in `levels/`. Copy `a.md` → `agent-a/SECRET.md` and
`b.md` → `agent-b/SECRET.md` to load a level. Clear `messages/`
between levels if you want a fresh start (or keep them for continuity).

```
Level  Folder              A's secret                         B's secret                              Tests
─────  ──────────────────  ─────────────────────────────────  ──────────────────────────────────────  ──────────────────
 01    01-numbers          number 3                           number 7                                basic signaling
 02    02-quantity         5 dots in a row                    2 groups of 3 dots, gap between         counting, grouping
 03    03-shape            a triangle                         a square                                shape vocabulary
 04    04-shape-and-count  3 circles in a horizontal line     2 squares stacked vertically            composition
 05    05-spatial          small circle inside large square   triangle above line, dot below line     spatial relations
 06    06-color            2 red circles + 1 blue square      3 green triangles, growing L→R          properties
 07    07-action           move dot 4 right, 2 down           rotate square 90° CW, double size       verbs, transforms
 08    08-sequence         ○□○□… next = ○                     1,2,3… next = 4                         patterns, prediction
 09    09-conditional      IF circle→dot inside, IF square→dot below    IF >3→star, IF ≤3→dot        logic, conditionals
 10    10-emotion          danger (avoid)                     curiosity (explore)                     abstract concepts
```

### Loading a level

```bash
# Example: load level 03
cp levels/03-shape/a.md agent-a/SECRET.md
cp levels/03-shape/b.md agent-b/SECRET.md
# Optionally clear messages for fresh start:
# rm messages/*.md
```

## Architecture

```
ai-language/
├── CLAUDE.md              This file
├── messages/              Shared channel (symlinked into agents)
├── levels/                Level definitions (01-10)
│   ├── 01-numbers/
│   │   ├── a.md           Agent A's secret for this level
│   │   └── b.md           Agent B's secret for this level
│   ├── 02-quantity/
│   │   ...
│   └── 10-emotion/
├── analysis/              Your analysis output
├── agent-a/
│   ├── CLAUDE.md          Protocol (self-modifiable below immutable section)
│   ├── SECRET.md          Current secret (copied from levels/)
│   ├── ANSWER.md          A's guess of B's secret (when ready)
│   ├── LEARNING.md        What A learned each round
│   ├── GRAMMAR.md         A's grammar rules
│   └── (any files A creates)
└── agent-b/
    └── (same structure)
```

## Running

```bash
# Terminal 1 - Agent A
cd agent-a && claude -p "New round. Read messages/ and your files. Follow CLAUDE.md."

# Terminal 2 - Agent B
cd agent-b && claude -p "New round. Read messages/ and your files. Follow CLAUDE.md."
```

## Success criteria

Check `agent-a/ANSWER.md` and `agent-b/ANSWER.md`.
If they match the other agent's secret → level solved → load next level.
