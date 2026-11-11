<!-- PROMPT_FAMILY -->

## Web search escalation

- Default to `web_search`. It routes OpenAI (via the ChatGPT subscription,
  regardless of the active model) then Exa. Don't pass `provider` unless
  deliberately overriding.
- Escalate to `agent-browser` when the task needs rendered/JS content, page
  interaction, or visual verification. Never drive a search engine with the
  browser — anti-bot CAPTCHAs block it; get the URL from `web_search`, then
  browse it.
- Treat "latest / newest / current" questions as freshness-sensitive: routing
  falls back only on errors, never on staleness, so verify against an
  authoritative page when the answer must be current.
