#!/bin/bash
set -euo pipefail

#############################################################
# V2 Emergent Language Experiment — Orchestrator
#
# Serialized execution: Agent A (Claude Opus) → validate →
# noise → Agent B (Codex GPT) → validate → noise → referee
#
# Usage:
#   ./run.sh                    # Run all levels
#   ./run.sh --level 5          # Start from level 5
#   ./run.sh --level 5 --dry    # Dry run (print commands, don't execute)
#############################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

# --- Parse args ---
START_LEVEL=1
DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --level) START_LEVEL="$2"; shift 2 ;;
    --dry)   DRY_RUN=true; shift ;;
    *)       echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# --- Directories ---
MESSAGES_RAW="$SCRIPT_DIR/messages/raw"
MESSAGES_DELIVERED="$SCRIPT_DIR/messages/delivered"
LOGS="$SCRIPT_DIR/logs"
WORLD="$SCRIPT_DIR/world"
AGENT_A="$SCRIPT_DIR/agent-a"
AGENT_B="$SCRIPT_DIR/agent-b"

mkdir -p "$MESSAGES_RAW" "$MESSAGES_DELIVERED" "$LOGS" "$WORLD"

# --- Logging ---
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOGS/orchestrator.log"; }
log_json() {
  echo "$1" >> "$LOGS/rounds.jsonl"
}

#############################################################
# LOAD LEVEL
#############################################################
load_level() {
  local level=$1
  local level_file="$SCRIPT_DIR/levels/$(printf '%02d' $level)-*.json"

  # shellcheck disable=SC2086
  level_file=$(ls $level_file 2>/dev/null | head -1)
  if [[ -z "$level_file" ]]; then
    log "ERROR: No level file for level $level"
    return 1
  fi

  log "Loading level $level from $(basename "$level_file")"

  # Extract tasks for each agent
  local task_a task_b world_state noise_rate max_rounds
  task_a=$(jq -r '.task_a // "No specific task."' "$level_file")
  task_b=$(jq -r '.task_b // "No specific task."' "$level_file")
  world_state=$(jq -r '.world // "null"' "$level_file")
  noise_rate=$(jq -r '.noise_rate // 0.20' "$level_file")
  max_rounds=$(jq -r '.max_rounds // 8' "$level_file")

  # Write secrets
  echo "$task_a" > "$AGENT_A/SECRET.md"
  echo "$task_b" > "$AGENT_B/SECRET.md"

  # Set world state
  if [[ "$world_state" != "null" ]]; then
    echo "$world_state" | jq '.' > "$WORLD/state.json"
  else
    echo '{}' > "$WORLD/state.json"
  fi

  # Export for this level
  export CURRENT_NOISE_RATE="$noise_rate"
  export CURRENT_MAX_ROUNDS="$max_rounds"
  export CURRENT_LEVEL="$level"
}

#############################################################
# COUNT MESSAGES
#############################################################
next_message_num() {
  local count
  count=$(ls "$MESSAGES_RAW"/*.txt 2>/dev/null | wc -l | tr -d ' ')
  printf '%03d' $((count + 1))
}

#############################################################
# VALIDATE MESSAGE
#############################################################
validate_message() {
  local msg_file=$1
  local agent=$2  # "a" or "b"

  bash "$SCRIPT_DIR/validate.sh" "$msg_file" "$agent"
}

#############################################################
# NOISE INJECT
#############################################################
inject_noise() {
  local src=$1
  local dest=$2
  local rate=$3

  python3 "$SCRIPT_DIR/noise.py" "$src" "$dest" "$rate"
}

#############################################################
# SNAPSHOT PREDICTION
#############################################################
snapshot_prediction() {
  local agent=$1
  local level=$2
  local round=$3
  local agent_dir

  if [[ "$agent" == "a" ]]; then
    agent_dir="$AGENT_A"
  else
    agent_dir="$AGENT_B"
  fi

  local prediction_file="$agent_dir/PREDICTION.txt"
  local prediction=""

  if [[ -f "$prediction_file" ]]; then
    prediction=$(cat "$prediction_file")
  fi

  log_json "{\"type\":\"prediction\",\"ts\":\"$(date -Iseconds)\",\"level\":$level,\"round\":$round,\"agent\":\"$agent\",\"prediction\":$(echo "$prediction" | jq -Rs .)}"
}

#############################################################
# RUN AGENT
#############################################################
run_agent() {
  local agent=$1      # "a" or "b"
  local level=$2
  local round=$3
  local agent_dir cmd

  if [[ "$agent" == "a" ]]; then
    agent_dir="$AGENT_A"
    cmd="claude -p \"ULTRATHINK. New round (level $level, round $round). \
First write your prediction of Agent B's next message to PREDICTION.txt. \
Then read all files in messages/ in order. Read GRAMMAR.md and SECRET.md. \
Follow your CLAUDE.md rules. Write your message and update GRAMMAR.md.\" \
--model claude-opus-4-6 \
--dangerously-skip-permissions"
  else
    agent_dir="$AGENT_B"
    cmd="codex --full-auto -p \"Think very deeply and step by step. \
New round (level $level, round $round). \
First write your prediction of Agent A's next message to PREDICTION.txt. \
Then read all files in messages/ in order. Read GRAMMAR.md and SECRET.md. \
Follow your CLAUDE.md rules. Write your message and update GRAMMAR.md.\""
  fi

  log "Running Agent $agent (level $level, round $round)..."

  if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY] cd $agent_dir && $cmd"
    # Create a fake message for dry run
    local num
    num=$(next_message_num)
    echo "DRY.$round" > "$MESSAGES_RAW/${num}-${agent}.txt"
    cp "$MESSAGES_RAW/${num}-${agent}.txt" "$MESSAGES_DELIVERED/${num}-${agent}.txt"
    return 0
  fi

  local start_time
  start_time=$(date +%s)

  # Run the agent in its directory
  (cd "$agent_dir" && eval "$cmd") 2>&1 | tee -a "$LOGS/agent-${agent}.log"

  local end_time duration
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  log "Agent $agent finished in ${duration}s"
}

#############################################################
# PROCESS AGENT TURN
#   1. Run agent
#   2. Detect new message
#   3. Validate
#   4. Save raw + inject noise → delivered
#############################################################
process_turn() {
  local agent=$1
  local level=$2
  local round=$3
  local agent_dir msg_pattern

  if [[ "$agent" == "a" ]]; then
    agent_dir="$AGENT_A"
  else
    agent_dir="$AGENT_B"
  fi

  # Files before agent run
  local before_count
  before_count=$(ls "$MESSAGES_DELIVERED"/*.txt 2>/dev/null | wc -l | tr -d ' ')

  # Run the agent
  run_agent "$agent" "$level" "$round"

  # Snapshot prediction (agent wrote PREDICTION.txt during run)
  snapshot_prediction "$agent" "$level" "$round"

  # Detect new message file in messages/delivered/ (agent writes here via symlink)
  # The agent writes to messages/NNN-x.txt which is symlinked to delivered/
  local new_msg=""
  for f in "$MESSAGES_DELIVERED"/*-${agent}.txt; do
    if [[ -f "$f" ]]; then
      # Check if this file is new (not in raw/ yet)
      local base
      base=$(basename "$f")
      if [[ ! -f "$MESSAGES_RAW/$base" ]]; then
        new_msg="$f"
        break
      fi
    fi
  done

  if [[ -z "$new_msg" ]]; then
    log "WARNING: Agent $agent did not produce a new message"
    return 1
  fi

  log "New message: $(basename "$new_msg")"

  # Validate
  if ! validate_message "$new_msg" "$agent"; then
    log "VALIDATION FAILED — retrying agent $agent..."

    # Remove invalid message
    rm "$new_msg"

    # Retry once
    run_agent "$agent" "$level" "$round"

    # Re-detect
    new_msg=""
    for f in "$MESSAGES_DELIVERED"/*-${agent}.txt; do
      base=$(basename "$f")
      if [[ ! -f "$MESSAGES_RAW/$base" ]]; then
        new_msg="$f"
        break
      fi
    done

    if [[ -z "$new_msg" ]] || ! validate_message "$new_msg" "$agent"; then
      log "ERROR: Agent $agent failed validation on retry"
      return 1
    fi
  fi

  # Save original to raw/
  local base
  base=$(basename "$new_msg")
  cp "$new_msg" "$MESSAGES_RAW/$base"

  # Inject noise — overwrite the delivered/ copy
  inject_noise "$MESSAGES_RAW/$base" "$new_msg" "$CURRENT_NOISE_RATE"

  log "Delivered (noised): $base"

  # Log round data
  local raw_content delivered_content
  raw_content=$(cat "$MESSAGES_RAW/$base")
  delivered_content=$(cat "$new_msg")

  log_json "{\"type\":\"message\",\"ts\":\"$(date -Iseconds)\",\"level\":$level,\"round\":$round,\"agent\":\"$agent\",\"raw\":$(echo "$raw_content" | jq -Rs .),\"delivered\":$(echo "$delivered_content" | jq -Rs .)}"

  return 0
}

#############################################################
# REFEREE CHECK
#############################################################
referee_check() {
  local level=$1

  # Level 16 = free talk, always "pass" (observe only)
  if [[ $level -eq 16 ]]; then
    return 1  # Don't advance, just run max_rounds
  fi

  # Check if either agent wrote ANSWER.md
  local answer_a="" answer_b=""
  [[ -f "$AGENT_A/ANSWER.md" ]] && answer_a=$(cat "$AGENT_A/ANSWER.md")
  [[ -f "$AGENT_B/ANSWER.md" ]] && answer_b=$(cat "$AGENT_B/ANSWER.md")

  if [[ -n "$answer_a" && -n "$answer_b" ]]; then
    log "Both agents submitted answers!"
    log "Agent A: $answer_a"
    log "Agent B: $answer_b"

    # For now: manual check. TODO: automated referee per level
    log "REFEREE: Check answers manually. Press ENTER to advance, 'n' to continue."
    read -r response
    if [[ "$response" != "n" ]]; then
      return 0  # Advance
    fi
  fi

  return 1  # Don't advance
}

#############################################################
# CLEAN BETWEEN LEVELS (optional)
#############################################################
clean_for_level() {
  local level=$1

  # Remove answer files from previous level
  rm -f "$AGENT_A/ANSWER.md" "$AGENT_B/ANSWER.md"

  # Optionally clear messages for fresh start
  # Uncomment below to reset messages each level:
  # rm -f "$MESSAGES_RAW"/*.txt "$MESSAGES_DELIVERED"/*.txt
}

#############################################################
# MAIN LOOP
#############################################################
main() {
  log "========================================="
  log "V2 Emergent Language Experiment"
  log "Agent A: Claude Opus 4.6 (ULTRATHINK)"
  log "Agent B: Codex GPT 5.4 (deep reasoning)"
  log "Starting from level $START_LEVEL"
  log "========================================="

  for level in $(seq "$START_LEVEL" 16); do
    log ""
    log "######### LEVEL $level #########"

    load_level "$level"
    clean_for_level "$level"

    local max_rounds="$CURRENT_MAX_ROUNDS"
    local solved=false

    for round in $(seq 1 "$max_rounds"); do
      log ""
      log "--- Level $level, Round $round/$max_rounds ---"

      # Agent A turn
      if ! process_turn "a" "$level" "$round"; then
        log "Agent A turn failed, skipping to next round"
        continue
      fi

      # Agent B turn
      if ! process_turn "b" "$level" "$round"; then
        log "Agent B turn failed, skipping to next round"
        continue
      fi

      # Referee check (L01-L15 only)
      if [[ $level -lt 16 ]]; then
        if referee_check "$level"; then
          log "LEVEL $level SOLVED in $round rounds!"
          solved=true
          log_json "{\"type\":\"level_complete\",\"ts\":\"$(date -Iseconds)\",\"level\":$level,\"rounds\":$round}"
          break
        fi
      else
        log "Free talk round $round complete"
      fi
    done

    if [[ "$solved" == "false" && $level -lt 16 ]]; then
      log "Level $level NOT solved in $max_rounds rounds"
      log_json "{\"type\":\"level_timeout\",\"ts\":\"$(date -Iseconds)\",\"level\":$level,\"rounds\":$max_rounds}"
    fi

    if [[ $level -eq 16 ]]; then
      log "Free talk complete ($max_rounds rounds)"
      log_json "{\"type\":\"free_talk_complete\",\"ts\":\"$(date -Iseconds)\",\"rounds\":$max_rounds}"
    fi
  done

  log ""
  log "========================================="
  log "EXPERIMENT COMPLETE"
  log "Logs: $LOGS/"
  log "Raw messages: $MESSAGES_RAW/"
  log "Delivered messages: $MESSAGES_DELIVERED/"
  log "========================================="
}

main
