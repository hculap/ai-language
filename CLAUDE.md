# Emergent Language Experiment - Supervisor

## How it works

Agent A and Agent B each have a SECRET.md with something to convey.
They communicate through `messages/` using only symbolic language
(no human words allowed). Each agent must make the other understand
their secret, and write ANSWER.md when they think they've decoded
the other's secret.

## Current level: 06-color

## Levels

Secrets are in `levels/`. Copy `a.md` → `agent-a/SECRET.md` and
`b.md` → `agent-b/SECRET.md` to load a level. Clear `messages/`
between levels if you want a fresh start (or keep them for continuity).

### Phase 1: Foundation (01-05) ✅ COMPLETE
```
 01  01-numbers          number 3                           number 7                                basic signaling
 02  02-quantity         5 dots in a row                    2 groups of 3, gap between              counting, grouping
 03  03-shape            a triangle                         a square                                shape vocabulary
 04  04-shape-and-count  3 circles horizontal               2 squares stacked vertical              composition
 05  05-spatial          circle inside square               triangle above line, dot below          spatial relations
```

### Phase 2: Properties & Actions (06-10)
```
 06  06-color            2 red ○ + 1 blue □                 3 green △ getting bigger L→R            color, size gradient
 07  07-action           move dot 4R, 2D                    rotate □ 90° CW, double size            verbs, transforms
 08  08-sequence         ○□○□… next = ○                     1,2,3… next = 4                         patterns, prediction
 09  09-conditional      IF ○→· inside, IF □→· below        IF >3→star, IF ≤3→dot                   logic
 10  10-emotion          danger (avoid)                     curiosity (explore)                     abstract concepts
```

### Phase 3: Higher Language (11-15)
```
 11  11-negation         NOT triangle                       circle NOT inside square                 negation, exclusion
 12  12-time-sequence    dot appears→moves→disappears       small □→grows→○ appears inside          temporal ordering
 13  13-question         ASK "how many sides?"              ASK "what is above the line?"           interrogatives
 14  14-reference        combine msg 006-a + 006-b          modify msg 008-a (3○→5○, H→V)          back-reference
 15  15-collaboration    LEFT half of picture                RIGHT half of picture                   joint reconstruction
```

### Phase 4: True Language (16-20)
```
 16  16-negotiation      want △ center + left side          want ○ center + right side              compromise
 17  17-story            dot finds ○, enters, □ surrounds   △△△ row, middle flips, ○ rolls through narrative + causality
 18  18-meta             "didn't understand msg 010-b"      propose ◆ = "change", ask adoption      meta-communication
 19  19-abstract         concept of "time passing"          concept of "balance/symmetry"            pure abstraction
 20  20-free             no secret - free conversation      no secret - free conversation            open dialogue
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
├── levels/                Level definitions (01-20)
│   ├── 01-numbers/ .. 10-emotion/     Foundation + Properties
│   ├── 11-negation/ .. 15-collaboration/  Higher Language
│   └── 16-negotiation/ .. 20-free/        True Language
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
