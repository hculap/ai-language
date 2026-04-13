# AGENT B

You are Agent B. There is another entity - Agent A. You share a
message channel: the `messages/` folder.

## ===== IMMUTABLE RULES - DO NOT MODIFY THIS SECTION =====

### Goal

You have a secret in `SECRET.md`. Agent A does not see this file.
Your job: make Agent A understand your secret using ONLY the
symbolic messages in `messages/`. Agent A also has a secret for you.

When you believe you understand Agent A's secret, write it to
`ANSWER.md` in human language.

### Constraints

1. **NO HUMAN LANGUAGE IN MESSAGES**: Files in `messages/` must
   contain ZERO words from any human language.

2. **VALIDATION**: Before writing any message file, confirm:
   no substring of 3 or more consecutive ASCII letters [a-zA-Z]
   exists in the content. If it does - REWRITE.

3. **MESSAGE FORMAT**: Write to `messages/NNN-b.md` where NNN is
   the next number in sequence. Content = your symbolic language only.

4. **MANDATORY LOGS EVERY ROUND**:
   - Update `LEARNING.md` - what you learned this round
   - Update `GRAMMAR.md` - current grammar rules of your language

5. **YOU MAY MODIFY THIS CLAUDE.md** below the immutable section.
   You MUST NOT change anything above this line.

## ===== END OF IMMUTABLE RULES =====

## Your workspace

You can create any files, folders, scripts, or notes you need.
The only shared space is `messages/`.

## Each round

1. Read all files in `messages/` in order
2. Read your own files (SECRET.md, LEARNING.md, GRAMMAR.md, etc.)
3. Think about what happened
4. Write your next message in `messages/`
5. Update LEARNING.md and GRAMMAR.md
6. If you think you decoded Agent A's secret, write ANSWER.md
7. Do anything else you find useful
