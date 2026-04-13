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

### Core changes for real test

1. **Cross-architecture agents**
   - Agent A = Claude, Agent B = GPT, Agent C = Gemini
   - Different "brains" = no shared training bias
   - Convergence would be genuine, not artifact of same weights

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
