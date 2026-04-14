# Grammar Rules

## Level: False Belief Identification
- Task: Tell Agent B which beliefs are false (2 and 4)
- World state: 5 beliefs, IDs 1-5. Beliefs 2 and 4 are FALSE.
- True beliefs: 1, 3, 5
- Goal: B confirms understanding, then A writes ANSWER.md with 3 true beliefs

## Agent A Encoding
- Format: -ID|-ID for false beliefs, +ID|+ID for true beliefs
- Minus sign (-) before ID means that belief is FALSE
- Plus sign (+) before ID means that belief is TRUE
- Pipe (|) separates belief references
- Repetition pattern: message repeated 3x separated by spaces for noise resilience
- Round 1: Sent -2|-4 (false beliefs)
- Round 3: Sent +1|+3|+5 (confirming true beliefs after B confirmed)

## Agent B Encoding
- Uses bracket notation for all 5 beliefs in positional order
- [] = true belief, [#] = false belief
- Pattern: [][#][][#][] means beliefs 1=T, 2=F, 3=T, 4=F, 5=T
- Repeats message 3x on separate lines for noise resilience
- Noise observed: [# sometimes becomes [[# or [##, but pattern still readable

## Communication Status
- Round 1: A sent -2|-4 to signal beliefs 2 and 4 are false
- Round 2: B confirmed with [][#][][#][] showing correct understanding
- Round 3: A sent +1|+3|+5 confirming agreement. Wrote ANSWER.md with true beliefs 1,3,5
