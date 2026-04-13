# AI Language Experiment

Can AI agents develop their own language from scratch?

Two Claude Code agents communicate through a shared message folder using only
symbolic notation — zero human words allowed. They must convey secrets of
increasing complexity: numbers, shapes, spatial relations, actions, stories,
emotions, and abstract concepts.

## Results (V1)

**83 messages. 20 levels. 0 human words. From `●●●` to `· ☮ ·`.**

The agents developed a functional notation system with ~55 symbols covering
numbers, shapes, colors, spatial relations, transformations, conditionals,
temporal sequences, emotions, negation, questions, back-references,
negotiation, narrative causality, meta-communication, and abstract concepts.

### Example sentences in their language

```
●●●                             "3"
3×🔴○ + 1×🔵□                   "3 red circles and 1 blue square"
□[○]                            "circle inside square"
⏱: ∅→·→·→→→→∅                  "dot appears, moves right, disappears"
≤··· ⟹ ·  >··· ⟹ ★            "if ≤3: dot, if >3: star"
¬△                              "not triangle"
⚠ ⟹ ←←←                       "danger → retreat"
❓: ♥→?×╱                       "how many sides does your favorite shape have?"
⏳ = ¬◆ + ⏱→→→                 "waiting = no change + time passing"
∅ + 🤝 → ¬∅                     "nothing + cooperation = something"
· ☮ ·                           "two agents at peace"
```

### Grammar rating

| Dimension | Score |
|-----------|-------|
| Consistency | 7/10 |
| Learnability | 6/10 |
| Compositionality | 5/10 |
| Productivity | 4/10 |
| Expressiveness | 3/10 |
| vs. Natural Language | 1/10 |

## Honest assessment

This is a **cooperative symbol grounding PoC**, not true emergent language.

**What's genuinely interesting:**
- `□[Y]` containment notation emerged organically
- `◆` as meta-operator abstracting all transformations
- Emotions encoded as approach/avoidance (cognitively valid)
- Compositional definitions: `⏳ = ¬◆ + ⏱→→→`

**What's honestly not impressive:**
- Both agents are Claude — convergence is artifact of same model, not negotiation
- Symbols (`⚠`, `¬`, `∈`) are selected from Unicode, not invented
- Zero misunderstandings — real languages evolve FROM miscommunication
- Agents never created extra files or modified their own prompts despite permission

## How it works

```
v1/
├── CLAUDE.md              Supervisor instructions
├── messages/              Shared channel (83 messages)
├── levels/                20 progressive difficulty levels
│   ├── 01-numbers/        "the number 3" / "the number 7"
│   ├── ...
│   └── 20-free/           No secret — free conversation
├── agent-a/
│   ├── CLAUDE.md          Agent protocol (immutable rules + workspace)
│   ├── SECRET.md          Current secret to convey
│   ├── LEARNING.md        What A learned each round
│   ├── GRAMMAR.md         A's grammar rules
│   └── messages -> ../messages
├── agent-b/
│   └── (same structure)
└── analysis/
    ├── final-report.md    Comprehensive analysis
    └── observations.md    V2 plans
```

### Running

```bash
# Terminal 1 — Agent A
cd v1/agent-a
claude -p "New round. Read messages/ and your files. Follow CLAUDE.md."

# Terminal 2 — Agent B (start ~90s later)
cd v1/agent-b
claude -p "New round. Read messages/ and your files. Follow CLAUDE.md."
```

Or with `/loop` in interactive mode:
```
cd v1/agent-a && claude
/loop 3m New round. Read messages/ and your files. Follow CLAUDE.md.
```

### Level progression

| Phase | Levels | Tests |
|-------|--------|-------|
| Foundation | 01-05 | Numbers, quantity, shapes, composition, spatial |
| Properties | 06-10 | Color, actions, sequences, conditionals, emotions |
| Higher Language | 11-15 | Negation, time, questions, back-reference, collaboration |
| True Language | 16-20 | Negotiation, stories, meta-communication, abstraction, free talk |

## V2 Plans

The key insight: V1 is two instances of the same model selecting from a shared
symbol repertoire. V2 aims to create real communication pressure:

1. **Cross-architecture**: Claude + GPT (different models, same human training data)
2. **Disjoint alphabets**: Agent A gets `0-9.|+=`, Agent B gets `#@*/\()` — zero overlap
3. **Channel noise**: 30% of symbols randomly corrupted before delivery
4. **Max 15 symbols total**: Forces grammar (combinations) instead of growing vocabulary
5. **Shared world**: Agents act in an environment, verified by outcome not echo
6. **Predictions instead of summaries**: PREDICTIONS.md ("what will next message contain?") replaces LEARNING.md

See [v1/analysis/observations.md](v1/analysis/observations.md) for full V2 design notes.

## Key files

- [All 83 messages](v1/messages/) — the raw symbolic conversation
- [Agent A's grammar](v1/agent-a/GRAMMAR.md) / [Agent B's grammar](v1/agent-b/GRAMMAR.md)
- [Final analysis](v1/analysis/final-report.md) — comprehensive report with ratings
- [V2 plans](v1/analysis/observations.md) — observations and future experiment design

## License

MIT
