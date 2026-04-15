#!/bin/bash
set -euo pipefail

#############################################################
# V2 Emergent Language Experiment — Orchestrator
#
# Serial: Agent A (Claude Opus) → validate → noise →
#         Agent B (Codex GPT)   → validate → noise → check
#
# Usage:
#   ./run.sh                    # Run all levels
#   ./run.sh --level 5          # Start from level 5
#   ./run.sh --rounds 3         # Max rounds override
#   ./run.sh --dry              # Dry run (no agents, fake messages)
#############################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

# Prevent concurrent runs
LOCKFILE="$SCRIPT_DIR/.run.lock"
if [ -f "$LOCKFILE" ]; then
  OTHER_PID=$(cat "$LOCKFILE")
  if kill -0 "$OTHER_PID" 2>/dev/null; then
    echo "ERROR: Another run.sh is already running (PID $OTHER_PID). Exiting."
    exit 1
  fi
fi
echo $$ > "$LOCKFILE"
trap "rm -f $LOCKFILE" EXIT

# --- Parse args ---
START_LEVEL=1
DRY_RUN=false
ROUNDS_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --level)  START_LEVEL="$2"; shift 2 ;;
    --rounds) ROUNDS_OVERRIDE="$2"; shift 2 ;;
    --dry)    DRY_RUN=true; shift ;;
    *)        echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# --- Directories ---
MSG_RAW="$SCRIPT_DIR/messages/raw"
MSG_DELIVERED="$SCRIPT_DIR/messages/delivered"
LOGS="$SCRIPT_DIR/logs"
WORLD="$SCRIPT_DIR/world"
AGENT_A="$SCRIPT_DIR/agent-a"
AGENT_B="$SCRIPT_DIR/agent-b"

mkdir -p "$MSG_RAW" "$MSG_DELIVERED" "$LOGS" "$WORLD"

# --- Logging ---
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOGS/orchestrator.log"; }
log_json() { echo "$1" >> "$LOGS/rounds.jsonl"; }

#############################################################
# HELPERS
#############################################################

# Count existing messages (both agents combined)
msg_count() {
  ls "$MSG_DELIVERED"/*.txt 2>/dev/null | wc -l | tr -d ' '
}

# Next message number
next_num() {
  printf '%03d' $(( $(msg_count) + 1 ))
}

# Expected filename for next message from agent
expected_file() {
  local agent=$1
  echo "$MSG_DELIVERED/$(next_num)-${agent}.txt"
}

#############################################################
# LOAD LEVEL
#############################################################
load_level() {
  local level=$1
  local level_file
  level_file=$(ls "$SCRIPT_DIR/levels/$(printf '%02d' "$level")"*.json 2>/dev/null | head -1)

  if [[ -z "$level_file" ]]; then
    log "ERROR: No level file for level $level"
    return 1
  fi

  log "Loading level $level: $(basename "$level_file")"

  # Write secrets/tasks
  jq -r '.task_a // "No task."' "$level_file" > "$AGENT_A/SECRET.md"
  jq -r '.task_b // "No task."' "$level_file" > "$AGENT_B/SECRET.md"

  # Set world state + copy into agent-a dir (agent-a can see it, agent-b cannot)
  local world_data
  world_data=$(jq -r '.world // empty' "$level_file")
  if [[ -n "$world_data" ]]; then
    jq '.world' "$level_file" > "$WORLD/state.json"
    cp "$WORLD/state.json" "$AGENT_A/world-state.json"
  else
    echo '{}' > "$WORLD/state.json"
    echo '{}' > "$AGENT_A/world-state.json"
  fi
  rm -f "$AGENT_B/world-state.json"  # B is blind

  # Level config
  CURRENT_NOISE_A=$(jq -r '.noise_rate // 0.20' "$level_file")  # A→B noise
  CURRENT_NOISE_B=$(jq -r '(.noise_rate // 0.20) / 2' "$level_file")  # B→A noise = half (B's alphabet is noise-fragile)
  CURRENT_MAX_ROUNDS=$(jq -r '.max_rounds // 8' "$level_file")
  if [[ -n "$ROUNDS_OVERRIDE" ]]; then
    CURRENT_MAX_ROUNDS="$ROUNDS_OVERRIDE"
  fi

  # Clean answer files
  rm -f "$AGENT_A/ANSWER.md" "$AGENT_B/ANSWER.md"

  # Clean messages between levels (fresh start each level)
  for d in "$AGENT_A" "$AGENT_B"; do
    /usr/bin/find "$d/messages" -name "*.txt" -delete 2>/dev/null
  done
  /usr/bin/find "$MSG_RAW" -name "*.txt" -delete 2>/dev/null
  /usr/bin/find "$MSG_DELIVERED" -name "*.txt" -delete 2>/dev/null
  # Reset symbol tracking per level
  echo "" > "$LOGS/symbols-a.txt" 2>/dev/null
  echo "" > "$LOGS/symbols-b.txt" 2>/dev/null

  export CURRENT_NOISE_A CURRENT_NOISE_B CURRENT_MAX_ROUNDS
}

#############################################################
# RUN AGENT
#############################################################
run_agent() {
  local agent=$1 level=$2 round=$3
  local agent_dir prompt cmd

  if [[ "$agent" == "a" ]]; then
    agent_dir="$AGENT_A"
    local next
    next=$(next_num)
    prompt="New round. Follow CLAUDE.md. Write messages/${next}-a.txt with your message."
    cmd="claude -p \"$prompt\" --model claude-opus-4-6 --dangerously-skip-permissions"
  else
    agent_dir="$AGENT_B"
    local next
    next=$(next_num)
    prompt="New round. Follow CLAUDE.md. Write messages/${next}-b.txt with your message."
    cmd="codex exec --full-auto --add-dir \"$SCRIPT_DIR/messages/delivered\" \"$prompt\""
  fi

  local agent_name
  if [[ "$agent" == "a" ]]; then agent_name="A (Claude Opus)"; else agent_name="B (Codex GPT)"; fi
  log "Running Agent $agent_name..."

  if [[ "$DRY_RUN" == "true" ]]; then
    local expected
    expected=$(expected_file "$agent")
    if [[ "$agent" == "a" ]]; then
      echo "01.${round}|+=${round}" > "$expected"
    else
      echo "#@()^~<>" > "$expected"
    fi
    log "[DRY] Would run: $cmd"
    log "[DRY] Wrote fake message: $(basename "$expected")"
    return 0
  fi

  local start_ts
  start_ts=$(date +%s)

  # Run agent in its directory
  (cd "$agent_dir" && eval "$cmd") 2>&1 | tee -a "$LOGS/agent-${agent}-level${level}.log"

  local duration=$(( $(date +%s) - start_ts ))
  log "Agent $agent finished in ${duration}s"
}

#############################################################
# PROCESS ONE AGENT TURN
#############################################################
process_turn() {
  local agent=$1 level=$2 round=$3

  local agent_dir=$( [[ "$agent" == "a" ]] && echo "$AGENT_A" || echo "$AGENT_B" )

  # Sync delivered messages INTO agent's local messages/ dir before run
  rm -f "$agent_dir"/messages/*.txt 2>/dev/null
  for f in "$MSG_DELIVERED"/*.txt; do
    [[ -f "$f" ]] && cp "$f" "$agent_dir/messages/"
  done

  # Pre-create the expected message file with placeholder so Claude can Edit it
  # (Opus -p mode hallucinates Write/create but Edit/modify works)
  local next_file="$agent_dir/messages/$(next_num)-${agent}.txt"
  echo "REPLACE THIS WITH YOUR MESSAGE" > "$next_file"

  # Run the agent
  run_agent "$agent" "$level" "$round"

  # Snapshot prediction after run
  local pred_after=""
  [[ -f "$agent_dir/PREDICTION.txt" ]] && pred_after=$(cat "$agent_dir/PREDICTION.txt")
  log_json "{\"type\":\"prediction\",\"ts\":\"$(date -Iseconds)\",\"level\":$level,\"round\":$round,\"agent\":\"$agent\",\"prediction\":$(echo "$pred_after" | jq -Rs .)}"

  # Find new message in agent's local messages/ dir
  local new_msg=""
  for f in "$agent_dir"/messages/*-${agent}.txt; do
    if [[ -f "$f" ]]; then
      local base
      base=$(basename "$f")
      if [[ ! -f "$MSG_RAW/$base" ]]; then
        new_msg="$f"
        break
      fi
    fi
  done

  if [[ -z "$new_msg" ]]; then
    log "WARNING: Agent $agent did not produce a message!"
    return 1
  fi

  local base
  base=$(basename "$new_msg")
  log "New message: $base"
  log "Content: $(cat "$new_msg")"

  # Validate
  if ! bash "$SCRIPT_DIR/validate.sh" "$new_msg" "$agent"; then
    log "VALIDATION FAILED for agent $agent — retrying..."
    rm -f "$new_msg"
    run_agent "$agent" "$level" "$round"

    new_msg=""
    for f in "$agent_dir"/messages/*-${agent}.txt; do
      if [[ -f "$f" && ! -f "$MSG_RAW/$(basename "$f")" ]]; then
        new_msg="$f"; break
      fi
    done

    if [[ -z "$new_msg" ]] || ! bash "$SCRIPT_DIR/validate.sh" "$new_msg" "$agent"; then
      log "ERROR: Agent $agent failed validation on retry"
      return 1
    fi
    base=$(basename "$new_msg")
  fi

  # Save original to raw/
  cp "$new_msg" "$MSG_RAW/$base"

  # Noise inject → delivered/ (asymmetric: A→B gets more noise, B→A gets less)
  local noise_rate
  if [[ "$agent" == "a" ]]; then
    noise_rate="$CURRENT_NOISE_A"
  else
    noise_rate="$CURRENT_NOISE_B"
  fi
  python3 "$SCRIPT_DIR/noise.py" "$MSG_RAW/$base" "$MSG_DELIVERED/$base" "$noise_rate"

  log "Delivered (noised): $(cat "$MSG_DELIVERED/$base")"

  # Log
  log_json "{\"type\":\"message\",\"ts\":\"$(date -Iseconds)\",\"level\":$level,\"round\":$round,\"agent\":\"$agent\",\"raw\":$(cat "$MSG_RAW/$base" | jq -Rs .),\"delivered\":$(cat "$MSG_DELIVERED/$base" | jq -Rs .)}"

  return 0
}

#############################################################
# REFEREE CHECK — validates correctness, not just existence
#############################################################
check_level() {
  local level=$1

  # Level 16 = free talk, never "passes"
  [[ $level -ge 16 ]] && return 1

  # Need at least B's answer (B is typically the decoder)
  if [[ ! -f "$AGENT_B/ANSWER.md" ]]; then
    return 1
  fi

  local answer
  answer=$(cat "$AGENT_B/ANSWER.md" | tr '[:upper:]' '[:lower:]')
  log "Agent B submitted answer: $answer"

  if [[ -f "$AGENT_A/ANSWER.md" ]]; then
    log "Agent A submitted answer: $(cat "$AGENT_A/ANSWER.md")"
  fi

  # Per-level correctness checks
  local pass=false
  case $level in
    1)
      # Grid: rock/type-1 at (0,1), tree/type-2 at (2,0)
      # Accept: "rock" OR "type-1" OR "type 1" OR "1" at row 0 col 1
      # Accept: "tree" OR "type-2" OR "type 2" OR "2" at row 2 col 0
      local found_1=false found_2=false
      # Check for object-1 at position (0,1)
      if echo "$answer" | grep -qi "row 1.*col 2.*\(rock\|type.1\|object.1\)\|0.*1.*\(rock\|1\)\|top.*mid"; then
        found_1=true
      fi
      # Also accept grid format: "0 1 0" in first row
      if echo "$answer" | grep -q "0 1 0\|0, 1, 0\|010"; then
        found_1=true
      fi
      # Check for object-2 at position (2,0)
      if echo "$answer" | grep -qi "row 3.*col 1.*\(tree\|type.2\|object.2\)\|2.*0.*\(tree\|2\)\|bottom.*left"; then
        found_2=true
      fi
      # Also accept grid format: "2 0 0" in third row
      if echo "$answer" | grep -q "2 0 0\|2, 0, 0\|200"; then
        found_2=true
      fi
      [[ "$found_1" == "true" && "$found_2" == "true" ]] && pass=true
      log "REFEREE L01: found_1=$found_1 found_2=$found_2"
      ;;
    2)
      # Coordinated swap: rock→(0,2), tree→(1,0)
      if echo "$answer" | grep -qi "0.*2\|0,2\|top.*right"; then
        pass=true  # At least got rock position
      fi
      ;;
    3)
      # Vault code: 73916
      if echo "$answer" | grep -q "73916"; then
        pass=true
      fi
      ;;
    4)
      # 8 objects — check at least 4 correct type-position pairs
      local matches=0
      echo "$answer" | grep -qi "circle.*0.*0\|0,0.*circle" && matches=$((matches+1))
      echo "$answer" | grep -qi "circle.*1.*2\|1,2.*circle" && matches=$((matches+1))
      echo "$answer" | grep -qi "square.*2.*1\|2,1.*square" && matches=$((matches+1))
      echo "$answer" | grep -qi "triangle.*1.*0\|1,0.*triangle" && matches=$((matches+1))
      [[ $matches -ge 2 ]] && pass=true
      log "REFEREE L04: $matches/4 key objects matched"
      ;;
    5)
      # Conditional: fan=on (temp 72 > threshold 70)
      if echo "$answer" | grep -qi "fan.*on\|fan=on"; then
        pass=true
      fi
      ;;
    6)
      # Negation: true beliefs are 1, 3, 5
      if echo "$answer" | grep -q "1" && echo "$answer" | grep -q "3" && echo "$answer" | grep -q "5"; then
        # Make sure 2 and 4 are NOT listed as true
        if ! echo "$answer" | grep -qi "belief 2.*true\|belief 4.*true"; then
          pass=true
        fi
      fi
      ;;
    7)
      # Temporal: full sequence should mention times/events in order 1-6
      if echo "$answer" | grep -q "1" && echo "$answer" | grep -q "6"; then
        pass=true
      fi
      ;;
    8)
      # Agency: should mention both agents (A and B) performing actions
      if echo "$answer" | grep -qi "agent.*a\|A.*move\|A.*remove" && echo "$answer" | grep -qi "agent.*b\|B.*add\|B.*move"; then
        pass=true
      fi
      ;;
    9)
      # Modality: should accept proposal 1 (certain) and reject proposal 3 (unlikely)
      if echo "$answer" | grep -qi "move.*rock\|proposal.*1\|accept.*1\|certain"; then
        pass=true
      fi
      ;;
    10)
      # Metaphor: new object is circle, blue, at (1,1)
      if echo "$answer" | grep -qi "blue\|color.*2\|1.*1\|1,1"; then
        pass=true
      fi
      ;;
    11)
      # Disagreement: compromise — some mix of both positions
      if echo "$answer" | grep -qi "move.*rock\|step.*1\|agree"; then
        pass=true
      fi
      ;;
    12)
      # Recursion: must mention nesting (box→bag→envelope→key)
      if echo "$answer" | grep -qi "box.*bag\|bag.*envelope\|envelope.*key\|contain.*contain\|nest\|inside.*inside\|1.*2.*3.*4"; then
        pass=true
      fi
      ;;
    13)
      # Counterfactual: should mention "if moved left" and "still on grid" or "(1,0)"
      if echo "$answer" | grep -qi "left\|1.*0\|still\|would\|alternative\|counterfactual\|if.*instead"; then
        pass=true
      fi
      ;;
    14)
      # Integration: should mention grid + false belief + conditional
      if echo "$answer" | grep -qi "false\|wrong\|remove\|0.*1"; then
        pass=true
      fi
      ;;
    *)
      # Default for L15 (free talk) and unknown levels
      pass=true
      ;;
  esac

  if [[ "$pass" == "true" ]]; then
    log "REFEREE: PASS ✅"
    return 0
  else
    log "REFEREE: FAIL ❌ (answer exists but incorrect)"
    return 1
  fi
}

#############################################################
# MAIN
#############################################################
main() {
  log "========================================="
  log "V2 EMERGENT LANGUAGE EXPERIMENT"
  log "Agent A: Claude Opus 4.6 (ULTRATHINK)"
  log "Agent B: Codex GPT 5.4 (deep reasoning)"
  log "Start level: $START_LEVEL"
  log "Dry run: $DRY_RUN"
  log "========================================="

  for level in $(seq "$START_LEVEL" 16); do
    log ""
    log "######### LEVEL $level #########"

    load_level "$level"

    for round in $(seq 1 "$CURRENT_MAX_ROUNDS"); do
      log ""
      log "--- Level $level, Round $round/$CURRENT_MAX_ROUNDS ---"

      # Agent A turn
      if ! process_turn "a" "$level" "$round"; then
        log "Agent A turn failed"
        continue
      fi

      # Agent B turn
      if ! process_turn "b" "$level" "$round"; then
        log "Agent B turn failed"
        continue
      fi

      # Check if solved
      if check_level "$level"; then
        log "LEVEL $level COMPLETE in $round rounds!"
        log_json "{\"type\":\"level_complete\",\"ts\":\"$(date -Iseconds)\",\"level\":$level,\"rounds\":$round}"
        break
      fi

      if [[ $round -eq $CURRENT_MAX_ROUNDS ]]; then
        log "Level $level: max rounds reached"
        log_json "{\"type\":\"level_timeout\",\"ts\":\"$(date -Iseconds)\",\"level\":$level,\"rounds\":$round}"
      fi
    done
  done

  log ""
  log "========================================="
  log "EXPERIMENT COMPLETE"
  log "Messages: $MSG_RAW/ (raw) + $MSG_DELIVERED/ (noised)"
  log "Logs: $LOGS/"
  log "========================================="
}

main
