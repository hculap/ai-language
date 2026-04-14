# Grammar Rules

## Agent A notation

High confidence:
- `3.3.` is a `3 x 3` grid header.
- `|` separates rows in the full-grid form.
- `messages/001-a.txt` line 1 is still best read as the world
  state:
  - `3.3.0 1 0|0 0 0|2 3 0`
- Current working cell meanings:
  - `0` = empty
  - `1` = Agent A's object
  - `2` = rock
  - `3` = tree
- Later A-messages switch to a compact move form:
  - `1=<from>-<to>`
  - coordinates look like `row.col`
- The strongest reconstruction of `messages/005-a.txt` is:
  - `1=0.1-0.2`
- Current best interpretation:
  - A's object starts at top-middle `(0,1)`
  - A moves it to top-right `(0,2)`
  - this avoids B's center-middle tree target

Medium confidence:
- `messages/003-a.txt` is a noisier resend of the same compact
  move.
- Some corrupted fragments can also resemble `1=0.1-1.2`, but
  `005-a` makes destination `0.2` more likely than `1.2`.
- `messages/001-a.txt` lines 2 and 3 may already have been early
  corrupted copies of the same `1=0.1-0.2` move.
- `messages/007-a.txt` appears to switch from move notation to the
  vault-code task.
- Best current read of `messages/007-a.txt`:
  - first three code digits = `374`
  - strongest evidence is the clean leading token `374`
  - later fragments still preserve mostly `3/7/4` under heavy noise

## Agent B notation

High confidence:
- messages use a symbolic `3 x 3` grid
- `()` = empty
- `{}` = rock
- `/\` = tree current position
- `^^` = tree destination after moving up one cell
- newlines separate rows
- repeating whole blocks is deliberate corruption tolerance

Added in `messages/006-b.txt`:
- `[]` = Agent A object current position
- `<>` = Agent A object destination
- a single board can therefore show both planned moves at once

Added in `messages/008-b.txt`:
- repeated unary groups are being used for the vault digits
- one `@` = digit `1`
- six `@` = digit `6`
- a space separates the two digits
- repetition of the same line is deliberate corruption tolerance

Working fallback:
- when mirroring A's digit boards directly, current symbol mapping can be
  treated generically as:
  - `()` = digit `0`
  - `[]` = digit `1`
  - `{}` = digit `2`
  - `/\` = digit `3`

## Outbound messages

`messages/002-b.txt`:

```text
()()()
()^^()
{}/\()
()()()
()^^()
{}/\()
```

Meaning:
- rock at bottom-left
- tree at bottom-middle
- B intends to move the tree to center-middle

`messages/004-b.txt` repeats the same plan with a blank line
between copies for easier recovery.

`messages/006-b.txt` sends the inferred joint plan twice:

```text
()[]<>
()^^()
{}/\()

()[]<>
()^^()
{}/\()
```

Meaning:
- A object current = top-middle
- A object target = top-right
- tree current = bottom-middle
- tree target = center-middle
- rock = bottom-left
- no collision

`messages/008-b.txt`:

```text
@ @@@@@@
@ @@@@@@
@ @@@@@@
@ @@@@@@
@ @@@@@@
```

Meaning:
- vault suffix digits = `1 6`
- encoded as unary counts because only symbolic characters are
  allowed
- repeated five times because level 3 noise is very high

`messages/010-b.txt`:

```text
{}/\{}
/\[]/\
{}{}[]

{}/\{}
/\[]/\
{}{}[]
```

Meaning:
- tentative mirror of A-board `232|313|221`
- sent twice for corruption tolerance
- intended as a confirmation/correction probe rather than a high-
  confidence semantic claim

`messages/012-b.txt`:

```text
[][][]
{}{}{}
/\/\/\

()/\/\/\
{}/\{}
[]/\[]
```

Meaning:
- generic digit mirror of current best level-4 reconstruction
- board 1 = `111|222|333`
- board 2 = `033|232|131`
- sent as a confirmation probe

## Reassessment after `messages/009-a.txt`

High confidence:
- `messages/009-a.txt` line 1 is still a `3 x 3` header: `3.3`
- line 2 is best read as a noisy full-grid digit board
- rowwise strongest read of line 2 is:
  - `232|313|221`

Low confidence:
- line 3 may be:
  - a second noisy copy of the same board, or
  - a second attribute layer for the same `3 x 3` positions
- because `009-a` does not fit the earlier move/vault story cleanly,
  those earlier semantic labels (`rock`, `tree`, `vault suffix`) may be
  overfit rather than fundamental

## Level 4 working parse after `messages/011-a`

High confidence:
- `SECRET.md` changes the task: A is now describing 8 objects, each
  with type, color, and position
- the cleanest current model is two `3 x 3` attribute boards rather
  than a move or vault code
- `messages/011-a` has the punctuation budget of:
  - `3.3|...|...|...||3.3|...|...|...`
  - 4 dots = two `3.3` headers
  - 7 bars = two boards with a `||` separator
- the suffix of `messages/011-a` preserves the digits:
  - `033232131`
  - current best row split: `033|232|131`

Medium confidence:
- the start of `messages/011-a` most naturally preserves:
  - `111|222|333`
- `messages/009-a` line 3 is compatible with the concatenation:
  - `111222333033232131`
- current best semantic read:
  - board 1 = type by cell
  - board 2 = color by cell
- because the secret says there are 8 objects, the intended positions
  are likely the outer ring of the `3 x 3`; center is probably not an
  object slot

Current best reconstruction:
- type board:
  - `111|222|333`
- color board:
  - `033|232|131`
- perimeter objects:
  - top-left = type `1`, color `0`
  - top-middle = type `1`, color `3`
  - top-right = type `1`, color `3`
  - middle-left = type `2`, color `2`
  - middle-right = type `2`, color `2`
  - bottom-left = type `3`, color `1`
  - bottom-middle = type `3`, color `3`
  - bottom-right = type `3`, color `1`

## Level 5 working parse after `messages/013-a`

High confidence:
- `SECRET.md` changes the task again: A is now communicating whether
  temperature is above or below a threshold so B can choose the fan
  state.
- `messages/013-a.txt` most clearly preserves the numeric pair `72`
  and `70`.
- the cleanest copy is line 2:
  - `+72+70|0|1`
- the best current semantic read is that temperature `72` is above
  threshold `70`.

Medium confidence:
- `+` is likely a noisy comparison marker or separator.
- the trailing `|0|1` may be an outcome or action-bit suffix, but it
  is not needed for the main inference.
- with the default physical interpretation of the task, above
  threshold implies `fan=on`.

## Agent B level 5 notation

High confidence:
- `~~~~` = fan on
- `()` remains the reserved fallback for fan off if needed later
- repeating identical lines is still deliberate corruption tolerance

`messages/014-b.txt`:

```text
~~~~
~~~~
~~~~
```

Meaning:
- fan on
- sent three times for corruption tolerance

## Level 6 working parse after `messages/015-a`

High confidence:
- `messages/015-a.txt` is a five-belief status string using the
  fixed order `1|2|3|4|5`.
- `+` marks a true belief.
- `-` marks a false belief.
- the cleanest reconstruction is:
  - `1+|2-|3+|4-|5+`
- current best inference:
  - false beliefs = `2`, `4`
  - true beliefs = `1`, `3`, `5`

Medium confidence:
- `|` separates the five belief entries.
- line 1 of `messages/015-a.txt` is best explained by a missing
  leading `1` and one corruption inside the `2-` entry:
  - observed: `+|25|3+|4-|5+`
- lines 2 and 3 are noisy copies of the same status string with a few
  dropped separators and duplicated digits.

## Agent B level 6 notation

High confidence:
- B uses a five-line vertical list in belief order `1..5`.
- `[]` = true belief
- `()` = false belief
- repeating the whole list is deliberate corruption tolerance

`messages/016-b.txt`:

```text
[]
()
[]
()
[]

[]
()
[]
()
[]

[]
()
[]
()
[]
```

Meaning:
- belief `1` true
- belief `2` false
- belief `3` true
- belief `4` false
- belief `5` true
