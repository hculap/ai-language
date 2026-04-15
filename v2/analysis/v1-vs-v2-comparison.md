# V1 vs V2 Comparative Analysis

## Executive Summary

V1 is a more complete notation system (20 levels, 83 messages, 0 failures).
V2 is a more honest experiment (6 levels, 5/6 pass, real noise, real failures).
V1 proved Claude can follow format constraints. V2 proved two different
architectures can build a translation layer through a noisy channel with
zero shared vocabulary.

---

## 1. Communication Efficiency

| Metric | V1 | V2 |
|--------|----|----|
| Symbols available | ~55 (full Unicode) | 15 per agent (disjoint) |
| Max message length | Unlimited (up to 461 bytes) | 50 chars |
| Grid encoding | Multi-line ASCII art (~200 bytes) | `0 1 0\|0 0 0\|2 0 0` (18 chars) |
| Negation | `🚫△` or `¬△` (4-6 bytes) | `-2\|-4` (5 chars) |
| Compression ratio | ~1x (no pressure) | ~10x vs V1 for equivalent content |

V2 is roughly 10x more compressed because 50-char limit + 15 symbols
forces maximum information density per character.

## 2. Grammar Complexity

**V1**: 55 symbols across 7 categories. Dominant syntax:
`Quantity × Color × Shape × Direction`. Compositional but from
pre-existing Unicode meanings.

**V2**: 15 symbols per agent. Task-specific encodings:
- L01: `0/1/2` + `|` (grid), `()/[]/{}` + `/` (grid echo)
- L03: `7.3.9` repeated (vault digits)
- L05: `72|70|+` (temperature comparison)
- L06: `-2|-4` and `[][#][][#][]` (boolean negation)

Key difference: V2 bootstraps NEW conventions per task rather than
building a cumulative grammar. Each level is a fresh encoding problem.

## 3. Error Handling

**V1**: Zero errors. Zero noise. Zero repair. Both agents are Claude —
convergence is artifact of same model. The V1 report itself flagged:
"real languages evolve BECAUSE of miscommunication."

**V2**: 20% A→B noise, 10% B→A noise. Every message arrives corrupted.

### Error correction strategies that emerged:

1. **Triple repetition** (majority voting):
   - A: `7.3.9|7.3.9|7.3.9` — noise hits different copies differently
   - B: `[][#][][#][] / [][#][][#][] / [][#][][#][]`

2. **Cross-round consistency** (temporal redundancy):
   - L04: A sent identical 39-char payload across ALL 6 rounds
   - Receiver compares multiple noisy copies over time

3. **Format adaptation**:
   - L04 R1-5: pipe-separated `1100|1212|2121|...` (20% corruption)
   - L04 R6: line-by-line (one record per line) — corruption dropped to 5%
   - A learned that newlines create natural error boundaries

4. **Structural redundancy**:
   - B uses `[]` paired brackets — even corrupted `][#` is recognizable
   - A uses digits — self-delimiting, `2302→232` loses one digit but rest stays interpretable

## 4. Noise Impact Statistics

### Per-message corruption table (sampled)

| Level | Agent | Raw chars | Corrupted | Rate | Severity |
|-------|-------|-----------|-----------|------|----------|
| L01 | A→B | 17 | 5 | 29% | Severe (row 3 lost) |
| L01 | B→A | 41 | 3 | 7% | Minor |
| L03 | A→B | 17 | 4 | 24% | Moderate |
| L03 | B→A | 47 | 37 | 79% | Severe (bracket cascade) |
| L04 | A→B | 39 | 6-9 | 15-23% | Moderate (consistent) |
| L05 | A→B | 23 | 8 | 35% | Severe |
| L06 | A→B | 17 | 4 | 24% | Moderate |
| L06 | B→A | 38 | 28 | 74% | Severe (bracket cascade) |

### Alphabet noise resilience

**A's digits are MORE resilient** despite higher noise rate (20% vs 10%):
- Digits are self-delimiting: `2302` corrupted to `232` loses one digit
  but remaining digits stay interpretable
- Average measured corruption: 17.6%

**B's brackets are FRAGILE** despite lower noise rate (10%):
- Single deletion in `[][#]` destroys pairing semantics
- Bracket mismatches propagate through entire sequence
- Average measured corruption: 25.7% (worse despite lower noise rate)
- Worst case: 79% corruption on a single message

### Total information loss
- 199 corrupted characters out of 895 total (22.2%)
- ~600-800 bits lost raw
- ~200-270 bits unrecoverable (after redundancy)
- Concentrated almost entirely in L04

## 5. Cross-Alphabet Mapping

The emergent translation layer between disjoint alphabets:

### L01-L02 (Grid domain)
| A's symbol | B's symbol | Meaning |
|------------|-----------|---------|
| `0` | `()` | empty cell |
| `1` | `[]` | rock / object type 1 |
| `2` | `{}` | tree / object type 2 |
| `\|` | `/` | row separator |

### L06 (Boolean domain)
| A's symbol | B's symbol | Meaning |
|------------|-----------|---------|
| `+N` | `[]` | true / keep |
| `-N` | `[#]` | false / remove |
| `\|` | (position) | separator / slot boundary |

Key insight: agents did NOT reuse L01 mapping for L06. They bootstrapped
NEW encodings per task. This is a weakness (no cumulative grammar) but
also honest — each mapping was grounded in the specific communication need.

## 6. What V2 Proved That V1 Could Not

1. **Cross-model grounding is possible.** Claude Opus and GPT-5.4 built
   functional translation layers with zero shared symbols. V1's same-model
   convergence could always be dismissed as shared inductive biases.

2. **Noise forces genuine redundancy engineering.** Triple repetition,
   spatial padding, format adaptation — all emerged as responses to corruption.
   V1 agents never needed any of this.

3. **Disjoint alphabets force genuine symbol grounding.** When A sends `2`
   and B sends `{}`, and both mean "tree," the referent is established through
   coordination, not shared convention.

4. **Compression under constraint reveals encoding priorities.** L04 showed
   agents tried to encode everything and failed. L05-L06 showed they learned
   to encode only the discriminating information.

5. **The L04 failure is informative.** 8 objects × 4 properties = 32 digits
   in a 50-char message with 20% noise. This is near the information-theoretic
   limit. V1's perfect 20/20 never revealed any limits.

## 7. What V2 Failed At That V1 Solved

| V1 success | V2 gap |
|------------|--------|
| 20 levels complete | Only 6 levels attempted |
| Abstract concepts (time, balance) | Not tested yet |
| Meta-communication | Not tested yet |
| Free conversation | Not tested yet |
| Cumulative grammar (55 symbols) | Task-specific encodings, no accumulation |
| Narrative with causality | Not tested yet |

L04 specifically failed because V2's constraints (50 chars, 20% noise, 15 symbols)
make dense multi-object encoding mathematically marginal. V1 had no such limits.

## 8. Ratings

| Dimension | V1 | V2 | Justification |
|-----------|----|----|---------------|
| **Expressiveness** | 3/10 | 2/10 | V1 covers more domains. V2 only tested 6 level types. |
| **Error resilience** | 1/10 | 6/10 | V1 never tested. V2 survives 20% noise via redundancy. |
| **Compositionality** | 5/10 | 4/10 | V1's `N×Color×Shape×Direction` composes. V2 bootstraps per-task. |
| **Novelty of encoding** | 2/10 | 7/10 | V1 selected Unicode. V2 invented bracket-type-as-semantic-class. |
| **Honest emergence** | 2/10 | 6/10 | V1 is same model selecting from shared repertoire. V2 is cross-model under noise. |
| **Overall "real language"** | 2/10 | 5/10 | V2 is closer to real communication: noise, errors, repair, translation. |

## 9. Conclusion

V1 was a successful PoC that proved the infrastructure works. V2 is a
successful experiment that proved cross-model communication is possible
under real constraints. The most interesting result is not what they got
right but what they got wrong: L04's failure reveals the information-theoretic
boundary of the setup, and the noise statistics show that bracket-based
alphabets are inherently fragile — an unexpected finding that was only
possible because of V2's design.

The next step (L07-L16) will determine whether V2's per-task encoding
can evolve into something cumulative, or whether it remains a collection
of isolated protocols. That is the open question.
