#!/bin/bash
set -euo pipefail

#############################################################
# Message Validator
# Usage: validate.sh <message_file> <agent: a|b>
# Exit 0 = valid, Exit 1 = invalid
#############################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

MSG_FILE="$1"
AGENT="$2"
SYMBOLS_FILE="$SCRIPT_DIR/logs/symbols-${AGENT}.txt"

# Ensure symbols tracking file exists
touch "$SYMBOLS_FILE"

# Read and canonicalize whitespace
MSG=$(cat "$MSG_FILE")
MSG=$(echo "$MSG" | tr -s ' ' | tr -s '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Write canonicalized version back
echo "$MSG" > "$MSG_FILE"

# 1. Check total length (including whitespace)
LEN=${#MSG}
if [[ $LEN -gt $MAX_MSG_LENGTH ]]; then
  echo "REJECT: $LEN chars (max $MAX_MSG_LENGTH)"
  exit 1
fi

if [[ $LEN -eq 0 ]]; then
  echo "REJECT: empty message"
  exit 1
fi

# 2. Check alphabet
if [[ "$AGENT" == "a" ]]; then
  # Agent A: 0-9 . | - + = space newline
  ILLEGAL=$(echo "$MSG" | grep -oP '[^0-9.|+= \n-]' | head -5)
else
  # Agent B: # @ * / \ ( ) [ ] { } < > ^ ~ space newline
  ILLEGAL=$(echo "$MSG" | grep -oP '[^#@*/\\()\[\]{}<>^~ \n]' | head -5)
fi

if [[ -n "$ILLEGAL" ]]; then
  echo "REJECT: illegal characters: $ILLEGAL"
  exit 1
fi

# 3. Check no 3+ consecutive ASCII letters
if echo "$MSG" | grep -qP '[a-zA-Z]{3,}'; then
  echo "REJECT: human language detected (3+ consecutive letters)"
  exit 1
fi

# 4. Check cumulative distinct symbols (max 15)
# Extract non-whitespace characters from message
NEW_CHARS=$(echo "$MSG" | grep -oP '\S' | sort -u)

# Load existing symbols
EXISTING=$(cat "$SYMBOLS_FILE" 2>/dev/null || echo "")

# Merge
ALL_CHARS=$(printf '%s\n%s' "$EXISTING" "$NEW_CHARS" | sort -u | grep -v '^$')
COUNT=$(echo "$ALL_CHARS" | wc -l | tr -d ' ')

if [[ $COUNT -gt $MAX_SYMBOLS ]]; then
  echo "REJECT: $COUNT cumulative distinct symbols (max $MAX_SYMBOLS)"
  echo "Symbols used: $(echo "$ALL_CHARS" | tr '\n' ' ')"
  exit 1
fi

# Update symbols file
echo "$ALL_CHARS" > "$SYMBOLS_FILE"

echo "OK: $LEN chars, $COUNT cumulative symbols"
exit 0
