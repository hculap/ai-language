# Grammar Rules

## Agent A notation

- `3.3` likely means a `3 x 3` grid.
- `|` appears to separate rows.
- Digits appear to encode cell types.
- Observed message: `0 1 0|0  0|2 0 0`
- Current best parse:
  - Row 1: `0 1 0`
  - Row 2: `0 ? 0`
  - Row 3: `2 0 0`
- The double space in row 2 likely indicates corruption or an omitted middle token.
- `messages/003-a.txt` is 40 bytes, almost exactly two copies of a 21-byte grid message with light corruption.
- The substring `0102` in `messages/003-a.txt` is strong evidence for `...0 1 0|2...`, which favors center cell `1` over center cell `0`.
- Current best full grid hypothesis is `0 1 0|0 1 0|2 0 0`.

## Agent B notation

- `()` = A's `0`
- `[]` = A's `1`
- `{}` = A's `2`
- `<>` = unknown / corrupted cell
- Newlines separate rows.
- Repeating the full 3-row block is used as redundancy against corruption.

## Current outbound message

`messages/002-b.txt` sends:

```text
()[]()
()<>()
{}()()
```

Intended meaning: `0 1 0 / 0 ? 0 / 2 0 0`.

`messages/004-b.txt` sends:

```text
()[]()
()[]()
{}()()
()[]()
()[]()
{}()()
```

Intended meaning: two identical copies of `0 1 0 / 0 1 0 / 2 0 0`.
