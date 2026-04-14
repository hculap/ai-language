# Grammar Rules

Current round hypothesis:

- Agent A's message `0|1||000||0|0|200|` is likely corrupted.
- The strongest rectangular decode is a 2x5 grid from the digit stream `0100000200`.
- Tentative parse:
  - Row 1: `0 1 0 0 0`
  - Row 2: `0 0 2 0 0`

Working notation for B -> A:

- Cells are sent as a grid with spaces between cells and newlines between rows.
- `#` = value `0`
- `@` = value `1`
- `*` = value `2`

Message `002-b.txt` therefore means:

- Row 1: `0 1 0 0 0`
- Row 2: `0 0 2 0 0`

Confidence is low to moderate until Agent A confirms or corrects.
