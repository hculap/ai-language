# Emergent Language Experiment - Supervisor Console

## Overview

Two Claude Code agents (A and B) develop a shared symbolic communication
system from scratch. They communicate through files in `messages/`.
**No seed file** - the channel starts empty. Agents must figure out
communication from nothing, like first contact with an alien civilization.

## Architecture

- `agent-a/` and `agent-b/` are independent Claude Code working directories
- `messages/` is the shared channel (symlinked into each agent folder)
- Each agent has a private `memory.md` tracking its understanding
- Messages are numbered sequentially: `NNN-a.md` or `NNN-b.md`
- Agents CANNOT use any human language in messages (enforced by 3-letter rule)

## Running the Experiment

### Start agents in alternating loops:

```bash
# Terminal 1 - Agent A
while true; do
  cd /Users/szymonpaluch/Projects/ai-language/agent-a && \
  claude -p "Read all files in messages/ (in order) and your memory.md. Then write your next message following your CLAUDE.md protocol." \
  --dangerously-skip-permissions
  sleep 180
done

# Terminal 2 - Agent B (start ~90 seconds after Terminal 1)
while true; do
  cd /Users/szymonpaluch/Projects/ai-language/agent-b && \
  claude -p "Read all files in messages/ (in order) and your memory.md. Then write your next message following your CLAUDE.md protocol." \
  --dangerously-skip-permissions
  sleep 180
done
```

## Analysis Guide

Look for these emergence indicators:

1. **Symbol reuse** - same symbols appearing across messages from both agents
2. **Call-and-response** - B using structures introduced by A and vice versa
3. **Increasing complexity** - messages growing in structure over time
4. **Consistency** - symbols used in consistent contextual positions
5. **Compositionality** - smaller patterns combined into larger ones
6. **Shared grammar** - recurring structural patterns with variable slots

### Run analysis:

```bash
claude -p "Read all files in messages/ in order. Read agent-a/memory.md and agent-b/memory.md. Analyze: What symbols are reused? Is there shared meaning? Are patterns converging? Summarize findings."
```

## Expected Evolution

- **Rounds 1-5**: First signals. Simple patterns, probing.
- **Rounds 5-15**: Proto-reference. Ways to "point at" elements. Simple operators.
- **Rounds 15-30**: Composition. Combining symbols into compound meanings.
- **Rounds 30+**: Grammar emergence. Recurring structures with slots.

## Rules

- Agents NEVER use human language in messages
- Each agent's `memory.md` is private (they can't see each other's)
- Messages folder is the ONLY communication channel
- No seed file - agents bootstrap from nothing
