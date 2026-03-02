#!/usr/bin/env bash
# Claude Code status line command
# Line 1: folder | model | [progress bar] used% | $cost | typo corrections
# Line 2: current: <bar> % | weekly: <bar> % | extra: <bar> $used/$limit
# Line 3: resets <time> | resets <datetime> | resets <date>

set -f  # disable globbing

input=$(cat)

cwd=$(echo        "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo      "$input" | jq -r '.model.display_name // ""')
used=$(echo       "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo   "$input" | jq -r '.context_window.context_window_size // 0')
transcript=$(echo "$input" | jq -r '.transcript_path // ""')
cost=$(echo       "$input" | jq -r '.cost.total_cost_usd // empty')

# ── ANSI colors ───────────────────────────────────────────────────────────────

blue='\033[38;2;0;153;255m'
orange='\033[38;2;255;176;85m'
green='\033[38;2;0;160;0m'
cyan='\033[38;2;46;149;153m'
red='\033[38;2;255;85;85m'
yellow='\033[38;2;230;200;0m'
white='\033[38;2;220;220;220m'
dim='\033[2m'
reset='\033[0m'

# ── Line 1: folder | model | [bar] used% | $cost | typo corrections ─────────

# Format context window size (e.g. 128K, 1M)
if [ "$ctx_size" -ge 1000000 ] 2>/dev/null; then
  ctx_label=$(awk "BEGIN {v=$ctx_size/1000000; if(v==int(v)) printf \"%dM\",v; else printf \"%.1fM\",v}")
elif [ "$ctx_size" -ge 1000 ] 2>/dev/null; then
  ctx_label=$(awk "BEGIN {v=$ctx_size/1000; if(v==int(v)) printf \"%dK\",v; else printf \"%.0fK\",v}")
else
  ctx_label=""
fi

# Progress bar (20 chars wide)
if [ -n "$used" ]; then
  pct=$(printf '%.0f' "$used")
  filled=$(( pct * 20 / 100 ))
  [ "$filled" -gt 20 ] && filled=20
  empty=$(( 20 - filled ))
  bar=""
  for i in $(seq 1 "$filled"); do bar="${bar}█"; done
  for i in $(seq 1 "$empty");  do bar="${bar}░"; done
  if [ -n "$ctx_label" ]; then
    bar_part="[${bar}] ${pct}%/${ctx_label}"
  else
    bar_part="[${bar}] ${pct}%"
  fi
else
  bar_part="[░░░░░░░░░░░░░░░░░░░░] —%"
fi

# Cost
if [ -n "$cost" ]; then
  cost_part=$(printf '$%.2f' "$cost")
else
  cost_part="$—"
fi

# Typo corrections
typo_part=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
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

line1="$(basename "$cwd") | $model | ${bar_part} | ${cost_part}${typo_part}"

# ── Lines 2 & 3: API usage limits with colored progress bars ─────────────────

# Build a colored dot-style progress bar
# Usage: build_bar <pct> <width>
build_bar() {
  local pct=$1
  local width=$2
  [ "$pct" -lt 0 ] 2>/dev/null && pct=0
  [ "$pct" -gt 100 ] 2>/dev/null && pct=100

  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))

  local bar_color
  if [ "$pct" -ge 90 ]; then bar_color="$red"
  elif [ "$pct" -ge 70 ]; then bar_color="$yellow"
  elif [ "$pct" -ge 50 ]; then bar_color="$orange"
  else bar_color="$green"
  fi

  local filled_str="" empty_str=""
  for ((i=0; i<filled; i++)); do filled_str+="●"; done
  for ((i=0; i<empty; i++)); do empty_str+="○"; done

  printf "${bar_color}${filled_str}${dim}${empty_str}${reset}"
}

# Resolve OAuth token (macOS keychain → credentials file → env var)
get_oauth_token() {
  local token=""
  if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "$CLAUDE_CODE_OAUTH_TOKEN"
    return 0
  fi
  if command -v security >/dev/null 2>&1; then
    local blob
    blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    if [ -n "$blob" ]; then
      token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
      if [ -n "$token" ] && [ "$token" != "null" ]; then
        echo "$token"
        return 0
      fi
    fi
  fi
  local creds_file="${HOME}/.claude/.credentials.json"
  if [ -f "$creds_file" ]; then
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
    if [ -n "$token" ] && [ "$token" != "null" ]; then
      echo "$token"
      return 0
    fi
  fi
  echo ""
}

# ISO 8601 → epoch (cross-platform: GNU date -d or BSD date -j)
iso_to_epoch() {
  local iso_str="$1"
  local epoch
  epoch=$(date -d "${iso_str}" +%s 2>/dev/null)
  if [ -n "$epoch" ]; then
    echo "$epoch"
    return 0
  fi
  local stripped="${iso_str%%.*}"
  stripped="${stripped%%Z}"
  stripped="${stripped%%+*}"
  stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"
  if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
    epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
  else
    epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
  fi
  [ -n "$epoch" ] && echo "$epoch"
}

format_reset_time() {
  local iso_str="$1"
  local style="$2"
  [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return
  local epoch
  epoch=$(iso_to_epoch "$iso_str")
  [ -z "$epoch" ] && return
  case "$style" in
    time)
      date -j -r "$epoch" +"%l:%M%p" 2>/dev/null | sed 's/^ //' | tr '[:upper:]' '[:lower:]' || \
      date -d "@$epoch" +"%l:%M%P" 2>/dev/null | sed 's/^ //'
      ;;
    datetime)
      date -j -r "$epoch" +"%b %-d, %l:%M%p" 2>/dev/null | sed 's/  / /g; s/^ //' | tr '[:upper:]' '[:lower:]' || \
      date -d "@$epoch" +"%b %-d, %l:%M%P" 2>/dev/null | sed 's/  / /g; s/^ //'
      ;;
    *)
      date -j -r "$epoch" +"%b %-d" 2>/dev/null | tr '[:upper:]' '[:lower:]' || \
      date -d "@$epoch" +"%b %-d" 2>/dev/null
      ;;
  esac
}

pad_column() {
  local text="$1"
  local visible_len=$2
  local col_width=$3
  local padding=$(( col_width - visible_len ))
  if [ "$padding" -gt 0 ]; then
    printf "%s%*s" "$text" "$padding" ""
  else
    printf "%s" "$text"
  fi
}

# Fetch usage data (cached for 60 s in /tmp/claude/statusline-usage-cache.json)
cache_file="/tmp/claude/statusline-usage-cache.json"
cache_max_age=60
mkdir -p /tmp/claude

needs_refresh=true
usage_data=""

if [ -f "$cache_file" ]; then
  cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)
  now=$(date +%s)
  cache_age=$(( now - cache_mtime ))
  if [ "$cache_age" -lt "$cache_max_age" ]; then
    needs_refresh=false
    usage_data=$(cat "$cache_file" 2>/dev/null)
  fi
fi

if $needs_refresh; then
  token=$(get_oauth_token)
  if [ -n "$token" ] && [ "$token" != "null" ]; then
    response=$(curl -s --max-time 5 \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $token" \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "User-Agent: claude-code/2.1.34" \
      "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
    if [ -n "$response" ] && echo "$response" | jq . >/dev/null 2>&1; then
      usage_data="$response"
      echo "$response" > "$cache_file"
    fi
  fi
  if [ -z "$usage_data" ] && [ -f "$cache_file" ]; then
    usage_data=$(cat "$cache_file" 2>/dev/null)
  fi
fi

line2=""
line3=""
sep=" ${dim}|${reset} "

if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then
  bar_width=10
  col1w=23
  col2w=22

  # -- 5-hour (current) window --
  five_hour_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
  five_hour_reset_iso=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty')
  five_hour_reset=$(format_reset_time "$five_hour_reset_iso" "time")
  five_hour_bar=$(build_bar "$five_hour_pct" "$bar_width")

  col1_bar_vis_len=$(( 9 + bar_width + 1 + ${#five_hour_pct} + 1 ))
  col1_bar="${white}current:${reset} ${five_hour_bar} ${cyan}${five_hour_pct}%${reset}"
  col1_bar=$(pad_column "$col1_bar" "$col1_bar_vis_len" "$col1w")

  col1_reset_plain="resets ${five_hour_reset}"
  col1_reset="${white}resets ${five_hour_reset}${reset}"
  col1_reset=$(pad_column "$col1_reset" "${#col1_reset_plain}" "$col1w")

  # -- 7-day (weekly) window --
  seven_day_pct=$(echo "$usage_data" | jq -r '.seven_day.utilization // 0' | awk '{printf "%.0f", $1}')
  seven_day_reset_iso=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty')
  seven_day_reset=$(format_reset_time "$seven_day_reset_iso" "datetime")
  seven_day_bar=$(build_bar "$seven_day_pct" "$bar_width")

  col2_bar_vis_len=$(( 8 + bar_width + 1 + ${#seven_day_pct} + 1 ))
  col2_bar="${white}weekly:${reset} ${seven_day_bar} ${cyan}${seven_day_pct}%${reset}"
  col2_bar=$(pad_column "$col2_bar" "$col2_bar_vis_len" "$col2w")

  col2_reset_plain="resets ${seven_day_reset}"
  col2_reset="${white}resets ${seven_day_reset}${reset}"
  col2_reset=$(pad_column "$col2_reset" "${#col2_reset_plain}" "$col2w")

  # -- Extra usage (optional) --
  col3_bar=""
  col3_reset=""
  extra_enabled=$(echo "$usage_data" | jq -r '.extra_usage.is_enabled // false')
  if [ "$extra_enabled" = "true" ]; then
    extra_pct=$(echo "$usage_data" | jq -r '.extra_usage.utilization // 0' | awk '{printf "%.0f", $1}')
    extra_used=$(echo "$usage_data" | jq -r '.extra_usage.used_credits // 0' | awk '{printf "%.2f", $1/100}')
    extra_limit=$(echo "$usage_data" | jq -r '.extra_usage.monthly_limit // 0' | awk '{printf "%.2f", $1/100}')
    extra_bar=$(build_bar "$extra_pct" "$bar_width")
    extra_reset=$(date -v+1m -v1d +"%b %-d" 2>/dev/null | tr '[:upper:]' '[:lower:]')
    col3_bar="${white}extra:${reset} ${extra_bar} ${cyan}\$${extra_used}/\$${extra_limit}${reset}"
    col3_reset="${white}resets ${extra_reset}${reset}"
  fi

  line2="${col1_bar}${sep}${col2_bar}"
  [ -n "$col3_bar" ] && line2+="${sep}${col3_bar}"

  line3="${col1_reset}${sep}${col2_reset}"
  [ -n "$col3_reset" ] && line3+="${sep}${col3_reset}"
fi

# ── Output ────────────────────────────────────────────────────────────────────

printf "%s" "$line1"
[ -n "$line2" ] && printf "\n%b" "$line2"
[ -n "$line3" ] && printf "\n%b" "$line3"
