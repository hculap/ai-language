# Grammar Rules

## A's notation (established level 1, continued levels 2-5)
- First token: grid dimensions as ROWS.COLS (e.g. 3.3 = 3x3)
- Grid data: rows separated by |
- Redundancy: repeat critical lines for noise resistance

## A's grid cell encoding (level 4)
- Each cell encoded as 2-digit number: TYPE then COLOR
- Type codes: 0=empty, 1=circle, 2=square, 3=triangle
- Color codes: 0=none, 1=red, 2=green, 3=blue
- 3 cells per row = 6 digits per row, rows separated by |
- Full grid: 111222|330013|232131

## A's conditional notation (level 5 — NEW)
- Format: VALUE+THRESHOLD|ACTION-A|ACTION-B
- + means VALUE > THRESHOLD (condition is TRUE)
- - means VALUE <= THRESHOLD (condition is FALSE)
- ACTION values: 0=off, 1=on
- Example: 72+70|0|1 means temp=72 > threshold=70, A=off, B=on
- Triple redundancy: same line repeated 3 times

## A's previous notations (levels 1-3)
- Level 1-2: cell values 0=empty, 1=rock, 2=tree with space separators
- Level 2: move notation OBJECT=FROM-TO with coordinates
- Level 3: vault notation POSITION=DIGIT, + means unknown

## B's notation
- All messages from B completely corrupted across all levels (1-5)
- Characters consistently outside valid alphabet: ()^{}\\/[]<>@
- Zero readable content from B across 6 messages
- 40% noise level renders all B output unreadable
- Strategy: keep messages compact, maximally redundant, simple patterns

## A's negation notation (level 6 — NEW)
- Format: ID+STATUS for each belief, separated by |
- + means TRUE (keep), - means FALSE (delete)
- Example: 1+|2-|3+|4-|5+ means beliefs 1,3,5 true; 2,4 false
- Triple redundancy: same line repeated 3 times

## Coordination status — Level 6
- Task: negation — 5 beliefs, identify which are FALSE
- Beliefs 1,3,5 are TRUE; beliefs 2,4 are FALSE
- Goal: tell B to delete beliefs 2 and 4
- Round 1 (015-a): sent 1+|2-|3+|4-|5+ with triple redundancy
- B's messages remain completely corrupted across all levels (1-6)
- 014-b contained ~ characters — still outside valid alphabet, unreadable