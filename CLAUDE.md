# Emergent Language Experiment - Supervisor

## Overview

Two Claude Code agents (A and B) must develop their own language
from absolute zero. No seed, no hints, no strategies given.
They only know: communicate with the other, don't use human language.

Each agent evolves independently - they can modify their own CLAUDE.md
(except immutable rules), create scripts, tools, notes, folders.

## Architecture

```
ai-language/
├── CLAUDE.md              # This file (supervisor)
├── messages/              # Shared channel (starts EMPTY)
├── analysis/              # Supervisor analysis output
├── agent-a/
│   ├── CLAUDE.md          # Agent A protocol (self-modifiable)
│   ├── LEARNING.md        # What A learned each round
│   ├── GRAMMAR.md         # A's grammar rules for the language
│   ├── messages -> ../messages
│   └── (any files A creates)
└── agent-b/
    ├── CLAUDE.md          # Agent B protocol (self-modifiable)
    ├── LEARNING.md        # What B learned each round
    ├── GRAMMAR.md         # B's grammar rules for the language
    ├── messages -> ../messages
    └── (any files B creates)
```

## Running

```bash
# Terminal 1 - Agent A
cd agent-a && claude -p "New round. Read messages/ and your files. Follow CLAUDE.md." --dangerously-skip-permissions

# Terminal 2 - Agent B  
cd agent-b && claude -p "New round. Read messages/ and your files. Follow CLAUDE.md." --dangerously-skip-permissions
```

Run alternately with ~2-3 min gaps.

## What to observe

- `messages/` - the raw symbolic exchange
- `agent-a/LEARNING.md` vs `agent-b/LEARNING.md` - do they converge?
- `agent-a/GRAMMAR.md` vs `agent-b/GRAMMAR.md` - is the grammar shared?
- What files/tools do agents create on their own?
- Do agents modify their own CLAUDE.md? How?
