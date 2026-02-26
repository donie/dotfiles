#!/usr/bin/env bash
# Claude Code status line command
# Line 1: folder | model | typo corrections
# Line 2: [progress bar] used% | $cost | ⏱ duration

input=$(cat)

cwd=$(echo      "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo    "$input" | jq -r '.model.display_name // ""')
used=$(echo     "$input" | jq -r '.context_window.used_percentage // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // ""')
cost=$(echo     "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')

# ── Line 1: folder | model | typo corrections ────────────────────────────────

typo_part=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  # Extract last user message text from JSONL transcript (one JSON object per line)
  # Transcript format: {type: "user", message: {role: "user", content: "text" | [...]}}
  last_user_text=$(jq -Rr '
    fromjson? |
    select(.type == "user") |
    .message.content |
    if . then
      if (. | type) == "array" then
        [.[] | select(.type == "text") | .text] | join(" ")
      elif (. | type) == "string" then
        .
      else ""
      end
    else ""
    end
  ' "$transcript" 2>/dev/null | grep -v "^$" | tail -1)

  if [ -n "$last_user_text" ]; then
    tmp_txt=$(mktemp /tmp/statusline-text.XXXXXX)
    printf '%s' "$last_user_text" > "$tmp_txt"
    corrections=$(/Users/donie/.local/bin/uv run --quiet \
      /Users/donie/.claude/statusline-spellcheck.py "$tmp_txt" 2>/dev/null)
    rm -f "$tmp_txt"

    if [ -n "$corrections" ]; then
      formatted=$(printf '%s' "$corrections" | while IFS= read -r pair; do
        printf '  ✎ %s' "$pair"
      done)
      typo_part=" |$formatted"
    fi
  fi
fi

line1="$(basename "$cwd") | $model${typo_part}"

# ── Line 2: [████░░░░] used% | $cost | ⏱ duration ──────────────────────────

# Progress bar (20 chars wide)
if [ -n "$used" ]; then
  pct=$(printf '%.0f' "$used")
  filled=$(( pct * 20 / 100 ))
  [ "$filled" -gt 20 ] && filled=20
  empty=$(( 20 - filled ))
  bar=""
  for i in $(seq 1 "$filled"); do bar="${bar}█"; done
  for i in $(seq 1 "$empty");  do bar="${bar}░"; done
  bar_part="[${bar}] ${pct}%"
else
  bar_part="[░░░░░░░░░░░░░░░░░░░░] —%"
fi

# Cost
if [ -n "$cost" ]; then
  cost_part=$(printf '$%.2f' "$cost")
else
  cost_part="$—"
fi

# Duration: convert ms → "Xm Ys" or "Xs"
if [ -n "$duration_ms" ]; then
  total_s=$(( ${duration_ms%.*} / 1000 ))
  mins=$(( total_s / 60 ))
  secs=$(( total_s % 60 ))
  if [ "$mins" -gt 0 ]; then
    dur_part="⏱ ${mins}m ${secs}s"
  else
    dur_part="⏱ ${secs}s"
  fi
else
  dur_part="⏱ —"
fi

line2="${bar_part} | ${cost_part} | ${dur_part}"

# ── Output ────────────────────────────────────────────────────────────────────

printf "%s\n%s" "$line1" "$line2"
