#!/usr/bin/env bash
# Claude Code status line command
# Line 1: folder | model | [progress bar] used% | $cost | typo corrections
# Line 2: 5h: <bar> % ↺ time | weekly: <bar> % ↺ date | extra: <bar> $used/$limit ↺ date

set -f  # disable globbing

input=$(cat)

# File mtime as epoch seconds. GNU first, because Homebrew coreutils shadows
# BSD stat on macOS and the reverse order is unsafe: GNU `stat -f` means
# *statfs*, so `stat -f %m FILE` reads %m as a filename and dumps a block of
# filesystem info for FILE to STDOUT before exiting 1. The `||` fallback does
# run, but its epoch is appended to that dump, so `$(...)` captures ~240 bytes
# of garbage. Ordering matters for stdout pollution, not exit status.
# This order is still portable: BSD `stat -c` fails with a usage error on
# stderr only, leaving stdout clean for the `-f %m` fallback.
file_mtime() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null
}

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

  # Color-code the bar by usage percentage
  if [ "$pct" -ge 50 ]; then ctx_bar_color='\033[91m'   # light red
  elif [ "$pct" -ge 25 ]; then ctx_bar_color='\033[33m'  # yellow
  else ctx_bar_color='\033[32m'                           # green
  fi

  if [ -n "$ctx_label" ]; then
    bar_part="${ctx_bar_color}[${bar}] ${pct}%/${ctx_label}${reset}"
  else
    bar_part="${ctx_bar_color}[${bar}] ${pct}%${reset}"
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

# ── Update check ─────────────────────────────────────────────────────────────

version=$(echo "$input" | jq -r '.version // empty')
update_part=""

if [ -n "$version" ]; then
  update_cache="/tmp/claude/statusline-update-cache.json"
  update_max_age=3600  # 1 hour

  needs_update_refresh=true
  update_data=""

  if [ -f "$update_cache" ]; then
    ucache_mtime=$(file_mtime "$update_cache")
    now_u=$(date +%s)
    ucache_age=$(( now_u - ucache_mtime ))
    if [ "$ucache_age" -lt "$update_max_age" ]; then
      needs_update_refresh=false
      update_data=$(cat "$update_cache" 2>/dev/null)
    fi
  fi

  if $needs_update_refresh; then
    update_response=$(curl -s --max-time 5 \
      "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" 2>/dev/null)
    if [ -n "$update_response" ] && echo "$update_response" | jq -e '.version' >/dev/null 2>&1; then
      update_data="$update_response"
      echo "$update_response" > "$update_cache"
    elif [ -f "$update_cache" ]; then
      update_data=$(cat "$update_cache" 2>/dev/null)
    fi
  fi

  if [ -n "$update_data" ]; then
    latest_version=$(echo "$update_data" | jq -r '.version // empty')
    if [ -n "$latest_version" ] && [ "$latest_version" != "$version" ]; then
      update_part=" ${yellow}↑ ${latest_version}${reset}"
    fi
  fi
fi

line1="$(basename "$cwd") | $model | ${bar_part} | ${cost_part}${typo_part}${update_part}"

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

  local filled_str="" empty_str=""
  for ((i=0; i<filled; i++)); do filled_str+="●"; done
  for ((i=0; i<empty; i++)); do empty_str+="○"; done

  printf "${filled_str}${empty_str}"
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
  local fmt out
  case "$style" in
    time)     fmt="%l:%M%p" ;;
    datetime) fmt="%b %-d, %l:%M%p" ;;
    *)        fmt="%b %-d" ;;
  esac
  # Resolve BEFORE piping — a `cmd | sed || fallback` chain takes its exit
  # status from the LAST pipeline element, so the fallback can never fire.
  out=$(date -d "@$epoch" +"$fmt" 2>/dev/null)          # GNU
  [ -z "$out" ] && out=$(date -j -r "$epoch" +"$fmt" 2>/dev/null)  # BSD
  [ -z "$out" ] && return
  printf '%s' "$out" | sed 's/  */ /g; s/^ //' | tr '[:upper:]' '[:lower:]'
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

# Fetch usage data. The cache holds only LAST-KNOWN-GOOD payloads: an error
# body (e.g. HTTP 429 {"error":...}) is still valid JSON, so validating with
# `jq .` alone poisons the cache and freezes every bar at 0%.
cache_file="/tmp/claude/statusline-usage-cache.json"
backoff_file="/tmp/claude/statusline-usage-backoff"
cache_max_age=180    # refresh at most every 3 min
backoff_secs=300     # after a failed fetch, don't retry for 5 min
stale_after=1800     # flag the line as stale if good data is >30 min old
mkdir -p /tmp/claude

now=$(date +%s)
usage_data=""
cache_age=""

if [ -f "$cache_file" ]; then
  cache_mtime=$(file_mtime "$cache_file")
  cache_age=$(( now - cache_mtime ))
  usage_data=$(cat "$cache_file" 2>/dev/null)
fi

needs_refresh=true
[ -n "$cache_age" ] && [ "$cache_age" -lt "$cache_max_age" ] && needs_refresh=false

# Respect backoff after a recent failure
if $needs_refresh && [ -f "$backoff_file" ]; then
  bo_mtime=$(file_mtime "$backoff_file")
  if [ -n "$bo_mtime" ] && [ $(( now - bo_mtime )) -lt "$backoff_secs" ]; then
    needs_refresh=false
  fi
fi

if $needs_refresh; then
  token=$(get_oauth_token)
  if [ -n "$token" ] && [ "$token" != "null" ]; then
    ua_version="${version:-2.1.223}"
    response=$(curl -s --max-time 5 \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $token" \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "User-Agent: claude-code/${ua_version}" \
      "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
    # Accept only a payload that actually carries usage data
    if [ -n "$response" ] && echo "$response" | jq -e '.five_hour.utilization != null' >/dev/null 2>&1; then
      usage_data="$response"
      cache_age=0
      echo "$response" > "$cache_file"
      rm -f "$backoff_file"
    else
      touch "$backoff_file"   # keep serving the previous good cache
    fi
  else
    touch "$backoff_file"
  fi
fi

# Never render an error body as usage data
if [ -n "$usage_data" ] && ! echo "$usage_data" | jq -e '.five_hour.utilization != null' >/dev/null 2>&1; then
  usage_data=""
fi

line2=""
sep=" ${dim}|${reset} "

if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then
  bar_width=10

  # -- 5-hour (current) window --
  five_hour_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
  five_hour_reset_iso=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty')
  five_hour_reset=$(format_reset_time "$five_hour_reset_iso" "time")
  five_hour_bar=$(build_bar "$five_hour_pct" "$bar_width")

  # current: <bar> % ↺time
  col1_reset_suffix=""
  [ -n "$five_hour_reset" ] && col1_reset_suffix=" ${dim}↺ ${five_hour_reset}${reset}"
  col1="${white}5h:${reset} ${five_hour_bar} ${cyan}${five_hour_pct}%${reset}${col1_reset_suffix}"

  # -- 7-day (weekly) window --
  seven_day_pct=$(echo "$usage_data" | jq -r '.seven_day.utilization // 0' | awk '{printf "%.0f", $1}')
  seven_day_reset_iso=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty')
  seven_day_reset=$(format_reset_time "$seven_day_reset_iso" "datetime")
  seven_day_bar=$(build_bar "$seven_day_pct" "$bar_width")

  # weekly: <bar> % ↺date
  col2_reset_suffix=""
  [ -n "$seven_day_reset" ] && col2_reset_suffix=" ${dim}↺ ${seven_day_reset}${reset}"
  col2="${white}weekly:${reset} ${seven_day_bar} ${cyan}${seven_day_pct}%${reset}${col2_reset_suffix}"

  # -- Extra usage (optional) --
  col3=""
  extra_enabled=$(echo "$usage_data" | jq -r '.extra_usage.is_enabled // false')
  if [ "$extra_enabled" = "true" ]; then
    extra_pct=$(echo "$usage_data" | jq -r '.extra_usage.utilization // 0' | awk '{printf "%.0f", $1}')
    extra_used=$(echo "$usage_data" | jq -r '.extra_usage.used_credits // 0' | awk '{printf "%.2f", $1/100}')
    extra_limit=$(echo "$usage_data" | jq -r '.extra_usage.monthly_limit // 0' | awk '{printf "%.2f", $1/100}')
    extra_reset=$(date -d "$(date +%Y-%m-15) +1 month" +"%b 1" 2>/dev/null \
                  || date -v+1m -v1d +"%b %-d" 2>/dev/null)
    extra_reset=$(printf '%s' "$extra_reset" | tr '[:upper:]' '[:lower:]')
    col3="${white}extra:${reset} ${cyan}\$${extra_used}/\$${extra_limit}${reset}"
    [ -n "$extra_reset" ] && col3+=" ${dim}↺ ${extra_reset}${reset}"
  fi

  line2="${col1}${sep}${col2}"
  [ -n "$col3" ] && line2+="${sep}${col3}"

  # Flag visibly when we're serving cached data the API refused to refresh
  if [ -n "$cache_age" ] && [ "$cache_age" -gt "$stale_after" ]; then
    line2+="${sep}${yellow}⚠ stale $(( cache_age / 60 ))m${reset}"
  fi
else
  # No usable usage data (rate-limited, offline, no token). Say so rather than
  # rendering a fake 0% — but still emit a line so the row never vanishes.
  line2="${dim}5h: — | weekly: — (usage api unavailable)${reset}"
fi

# ── Output ────────────────────────────────────────────────────────────────────

printf "%b" "$line1"
[ -n "$line2" ] && printf "\n%b" "$line2"

# Claude Code discards status line output on a nonzero exit, and the last
# command above is a test that fails whenever line2 is empty. Always succeed.
exit 0
