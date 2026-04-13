# Observations & Analysis

## V1 (Current PoC) - What we learned

### Results
- 14/15 levels solved, all in 2 rounds (except L13 questions: 3 rounds)
- Agents converge instantly because they share architecture + training data
- Language is more "shared encoding protocol" than true emergent language

### What works well
- Extreme conciseness: `2×🔴○ + 1×🔵□` (15 chars vs 47 in Polish)
- Zero ambiguity - every symbol has exactly one meaning
- Composable: quantity + color + shape + direction in one expression
- Emotions encoded as approach/avoidance direction (cognitively valid)
- ∅ for nothing (appearance/disappearance)
- ←½/→½ for partial knowledge sharing

### Honest limitations
- NOT true emergence - both agents are Claude, same brain, same training
- Emojis/Unicode already carry meaning (🔴=red, ⚠=warning, ∉=math)
- No real misunderstanding ever happened - too easy convergence
- No recursion ("the X that was in Y that was above Z")
- No modality (could/should/might)
- No causality (because/therefore)
- No productivity - can't generate truly novel expressions
- No metaphor, humor, ambiguity

### Language inventory after 14 levels
- Shapes: △ □ ○ · ★
- Colors: 🔴 🔵 🟢
- Quantity: N×
- Direction: ←→ ↕ ↑ ↓
- Spatial: X[Y] ⊂ ⊃ ────
- Actions: +N→ ↻ ×N →(chain)
- Logic: ⟹ ≤ >
- Negation: ¬ 🚫 ∉ ✗
- Time: ⏱ ∅ (N)
- Questions: ❓: ♥ ?
- Emotion: ⚠←←← ❓→→→
- Reference: @NNN-x
- Confirm: ✓

---

## V2 Plans - True Emergent Language

### Fundamental limitation of ALL current LLMs
Cross-architecture (Claude vs GPT vs Gemini) helps but does NOT solve the
core problem: all LLMs are trained on the same human internet data. They
share a "cultural OS" - Unicode meanings, mathematical conventions, emoji
semantics. Even "arbitrary" tokens carry biases (x=unknown in all models).

True emergence would need agents with fundamentally different grounding:
- Agent trained ONLY on music vs agent trained ONLY on images
- RL agents with zero human language in training
- Different input modalities (sensor readings vs text)
- Or: synthetic agents trained on procedurally generated non-human data

What V2 cross-arch actually tests: how models NEGOTIATE a shared subset
from the same human heritage, not true language creation from zero.
Still valuable but important to be honest about what it proves.

### What is the actual goal? (DECIDE BEFORE V2)

Three very different goals lead to very different experiments:

1. **Fundamental language research** - "how does language emerge from nothing?"
   - Needs: max isolation, zero shared bias, RL agents, arbitrary tokens
   - Human background is a PROBLEM to eliminate
   - Academic, hard, possibly impossible with current LLMs

2. **First contact simulation** - "how to communicate with truly alien minds?"
   - Needs: max difference between agents, disjoint alphabets, cross-arch
   - Human background is a PROBLEM to differentiate around
   - Cool but niche application

3. **Let AI develop its own language** - "what do AIs invent when freed from human text?"
   - Needs: freedom, minimal constraints, just ban human words
   - Human background is a FEATURE not a bug
   - Question: will they create something more efficient than human language?
   - Most practical, most interesting

**Decision: Goal 3 is the path forward.**

Roadmap:
- V1 (done): PoC, Claude-Claude → baseline, proves mechanics work
- V2 (next): Claude-GPT, same rules → compare with V1 baseline
- Delta V1↔V2 is the interesting result (same language? different? better?)
- Goals 1 & 2 (aliens, language fundamentals) → separate academic questions, parked

V1 PoC already shows goal 3 in action: agents naturally gravitated to
mathematical/symbolic notation. Not Polish 2.0 but something closer to
programming. That IS their "own language" - optimized for how LLMs think.

Goal 3 questions for V2:
- Is AI-language more compressible than human language?
- Can a third AI learn the language faster than learning English?
- Does the language scale to complex ideas or break down?
- Would Claude and GPT converge on the SAME AI-language or different ones?

### Practical V2: How to differentiate Claude + OpenAI

Since both are human-trained, need ARTIFICIAL constraints to force divergence:

**Option A: Different conceptual frames (system prompt)**
- Agent A: "think only through SOUND - rhythm, frequency, silence"
- Agent B: "think only through SPACE - distance, direction, containment"
- Same data but forced cognitive divergence

**Option B: Disjoint symbol alphabets ← MOST PROMISING**
- Agent A ONLY: `0-9 . | - + =`
- Agent B ONLY: `# @ * / \ ( )`
- ZERO overlap → forces cross-system mapping
- Even if both "know" what + means, one can't use it
- Creates genuine translation problem

**Option C: Asymmetric constraints**
- Agent A: max 5 tokens per message (compression pressure)
- Agent B: max 50 tokens but no memory between rounds
- Different pressures → different strategies

**Option D: Channel noise (30% corruption)**
- Randomly replace 30% of symbols before delivery
- Forces redundancy, error correction, confirmation
- Mimics real noisy channels

**Best combo: B + D** (disjoint alphabets + noise)

### Core changes for real test

1. **Cross-architecture agents** (partial improvement)
   - Agent A = Claude, Agent B = GPT
   - Different weights but SAME training distribution (human text)
   - Tests negotiation, not true emergence

2. **Arbitrary tokens only**
   - Ban ALL symbols with pre-existing meaning
   - Allowed: `xk7 mp2 qr9 zz1` etc. - random letter-digit combos
   - Or: invented glyphs with no Unicode meaning
   - Forces TRUE invention, not selection from shared repertoire

3. **Forced misunderstanding**
   - Add noise: randomly corrupt 20% of symbols in messages
   - Agent must develop error correction / repair strategies
   - This is what drives real language evolution

4. **Asymmetric capabilities**
   - One agent can only send 10 symbols per message
   - Other agent has no limit
   - Forces compression, abbreviation, shared shorthand

5. **Grounding in environment**
   - Shared "world" file that changes each round
   - Agents must describe/manipulate the world, not just pass secrets
   - Closer to how human language evolved (shared environment)

### V2 Architecture ideas

```
v2/
├── world/              # Shared environment state
│   └── state.json      # Changes each round
├── channel/            # Messages (with noise injection)
├��─ noise-injector.sh   # Corrupts N% of symbols randomly
├── agent-claude/
├── agent-gpt/          # Uses OpenAI API
├── agent-gemini/       # Uses Google API
└��─ referee/            # Validates understanding, scores
```

### V2 Metrics to track
- Rounds to converge on shared meaning (should be >>2)
- Error rate before/after repair attempts
- Vocabulary size over time
- Symbol reuse across agents (convergence indicator)
- Message length trends (compression = language maturity)
- Novel combinations (productivity test)

### V2 Levels (harder)
- Describe a changing world state
- Coordinate actions in shared environment
- Teach a NEW agent the language (generalization test)
- Express disagreement and negotiate
- Refer to hypothetical/counterfactual ("if X had happened")
