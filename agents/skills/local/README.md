# Local skills

Skills kept in this repo instead of installed by `sync-skills` from
`../manifest.json`. dotbot links each directory here into
`~/.claude/skills/`, `~/.codex/skills/`, and `~/.pi/agent/skills/`.

| Skill | Origin | Why it's here |
|---|---|---|
| `mermaid` | [mitsuhiko/agent-stuff](https://github.com/mitsuhiko/agent-stuff) `skills/mermaid` at `0638152` (Apache-2.0) | Removed upstream in `f1c881d`. |

## Changes from upstream

- `mermaid/tools/validate.sh`:
  - Install `puppeteer` alongside `@mermaid-js/mermaid-cli` (v12 made it a
    peer dependency that `npx` skips).
  - Validate Markdown files directly: checks every ```` ```mermaid ```` block
    and, on failure, names the block and the file line of the error.
  - Show parser errors without the JavaScript stack trace; renders go to a
    temp dir, never next to the input.
- `mermaid/SKILL.md`: Markdown-first workflow, a diagram-type chooser covering
  all main types, authoring guidance (adapted from
  [imxv/Pretty-mermaid-skills](https://github.com/imxv/Pretty-mermaid-skills),
  MIT), and common syntax mistakes, each checked against mermaid-cli 12.
