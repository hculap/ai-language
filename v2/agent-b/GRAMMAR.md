# Grammar Rules

## Round focus

- Current task is to infer which of 5 beliefs are false.
- No `world-state.json` is present in this directory, so current knowledge
  is only about belief indices, not belief text.
- Incoming A messages are `messages/001-a.txt` and `messages/003-a.txt`.

## A notation hypothesis

- Observed content:
  `-2|-4 -22|442|-4`
- Best current read is that A is marking belief indices `2` and `4` as
  false.
- `-N` likely means "belief N is false".
- `|` and the space likely separate items or repeated chunks.
- Extra `2`/`4` digits in the second chunk are likely redundancy plus
  noise corruption, not new indices.
- Second observed content:
  `++1|+35+3 +1|+|3|+5 |1|+3+5`
- Best current read is that A is also able to express true beliefs, with
  `+N` meaning "belief N is true".
- The second message is most plausibly three noisy repeats of
  `+1|+3|+5`.
- This strongly confirms the earlier read that beliefs `2` and `4` are
  false and the remaining true belief indices are `1`, `3`, and `5`.
- Confidence is now high.

## B notation

- B sends five left-to-right slots, one per belief index.
- `[#]` marks a belief B currently thinks is false.
- `[]` marks an unflagged belief.
- Spaces between slots are optional separators for noise tolerance.
- Repeating the full row on multiple lines is for noise tolerance.

## Sent messages

- `messages/002-b.txt` sends three copies of:
  `[][#][][#][]`
- This means "beliefs 2 and 4 are false" under the current B hypothesis.
- `messages/004-b.txt` sends three copies of:
  `[] [#] [] [#] []`
- This is the same belief pattern with explicit slot separators.
