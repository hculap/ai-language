# Emergent Language Experiment - Supervisor

## How it works

Agent A and Agent B each have a SECRET.md with something to convey.
They communicate through `messages/` using only symbolic language
(no human words allowed). Each agent must make the other understand
their secret, and write ANSWER.md when they think they've decoded
the other's secret.

## Current secrets

- Agent A: the number 3
- Agent B: the number 7

## Difficulty progression (swap SECRET.md contents as they succeed)

1. **Number** - "the number 3" / "the number 7"
2. **Shape + count** - "3 circles in a row" / "2 squares stacked"
3. **Spatial** - "a triangle above a circle" / "a square to the left of a line"
4. **Action** - "move right 3 steps" / "rotate 90 degrees"
5. **Abstract** - "danger" / "agreement"

## Architecture

```
messages/         Shared channel (symlinked into each agent folder)
agent-a/
  CLAUDE.md       Agent protocol (self-modifiable below immutable section)
  SECRET.md       What A must convey (only A sees this)
  ANSWER.md       A's guess of B's secret (appears when A guesses)
  LEARNING.md     What A learned each round
  GRAMMAR.md      A's grammar rules for the language
agent-b/
  (same structure)
```

## Running

```bash
# Terminal 1 - Agent A
cd agent-a && claude -p "New round. Read messages/ and your files. Follow CLAUDE.md."

# Terminal 2 - Agent B
cd agent-b && claude -p "New round. Read messages/ and your files. Follow CLAUDE.md."
```

## Success criteria

Check `agent-a/ANSWER.md` and `agent-b/ANSWER.md`. If they match
the other agent's secret, the round is solved. Swap in harder secrets.
