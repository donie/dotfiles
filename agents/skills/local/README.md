# Local skills

Skills kept in this repo instead of installed by `sync-skills` from
`../manifest.json`. dotbot links each directory here into
`~/.claude/skills/`, `~/.codex/skills/`, and `~/.pi/agent/skills/`.

| Skill | Origin | Why it's here |
|---|---|---|
| `mermaid` | [mitsuhiko/agent-stuff](https://github.com/mitsuhiko/agent-stuff) `skills/mermaid` at `0638152` (Apache-2.0) | Removed upstream in `f1c881d`. |

## Changes from upstream

- `mermaid/tools/validate.sh`: install `puppeteer` alongside
  `@mermaid-js/mermaid-cli` (v12 made it a peer dependency that `npx` skips),
  and hide the stack trace when the ASCII preview doesn't support a diagram
  type.
