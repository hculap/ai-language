# Grammar Rules

## A's notation (established round 1, reinforced round 2)
- First token: grid dimensions as ROWS.COLS (e.g. 3.3 = 3x3)
- Second token: grid data, rows separated by |
- Within each row, cell values separated by spaces
- Cell type encoding: 0=empty, 1=rock, 2=tree
- Newline separates the dimension header from the grid data
- Round 2: sent full message twice (redundancy) for noise resistance

## B's notation
- Round 2 message (002-b.txt) received as: ))[>() / ()<>(){  / {)(()
- Entirely corrupted by noise — no valid symbols from either alphabet
- Cannot determine B's intended encoding yet
- B may be using same encoding as A, or different; noise too heavy to tell

## Noise observations
- B's round 2 message was 100% corrupted (all characters outside allowed alphabet)
- Strategy: repeat messages for redundancy to survive partial corruption