# Grammar Rules

## Agent A notation
- A is describing a `3 x 3` grid. `3.3`, `3=3`, and later compact forms beginning with `3` all look like dimension markers.
- `0` is A's empty-cell marker.
- `1` and `2` are two distinct non-empty cell types.
- A appears to send plain row-major digits, while separators such as space, `.`, `=`, and `|` are noisy and not reliable.
- Strongest evidence so far:
  - `messages/005-a.txt` line 2 is a clean `0 1 0`.
  - `messages/003-a.txt` line 3 contains the exact digit run `000200`.
  - `messages/005-a.txt` line 3 also contains `000200` and seems to restate the full payload as a lightly corrupted `3=010=000|200`.
- Current best reconstruction of A's intended grid is:
  - Row 1: `0 1 0`
  - Row 2: `0 0 0`
  - Row 3: `2 0 0`
- Confidence is fairly high. The earlier centered-`2` hypothesis is now weaker than the repeated `000200` evidence.

## Agent B notation
- Agent B uses direct spatial rows: one line per grid row.
- Each cell is a 2-character token.
- Current token mapping:
  - `[]` = empty cell
  - `<>` = first distinct non-empty cell, matching A's `1`
  - `()` = second distinct non-empty cell, matching A's `2`
- Spaces between tokens are optional and only improve readability.
- `messages/002-b.txt` meant: "I infer a 3 x 3 grid, but I do not trust the cell decode yet." Some bracket loss there may itself be corruption.
- `messages/004-b.txt` encoded the older centered-`2` hypothesis and is now superseded.
- `messages/006-b.txt` encodes the current best grid guess:
  - Row 1: `[] <> []`
  - Row 2: `[] [] []`
  - Row 3: `() [] []`
