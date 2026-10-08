---
name: mermaid
description: "Must read guide on creating/editing mermaid charts with valiation tools"
---

# Mermaid Skill

Use this skill to write Mermaid diagrams, usually inside Markdown, and to validate them with the official Mermaid CLI (the same parser GitHub and most Markdown renderers use).

## Prerequisites

- Node.js + npm (for `npx`).
- First run downloads a headless Chromium via Puppeteer. If Chromium is missing, set `PUPPETEER_EXECUTABLE_PATH`.

## Tool

`tools/validate.sh` is relative to this skill's directory.

```bash
./tools/validate.sh doc.md                  # every ```mermaid block in a Markdown file
./tools/validate.sh diagram.mmd [out.svg]   # one diagram, with an ASCII preview
```

- Non-zero exit = at least one invalid diagram.
- For Markdown, a failure names the block and the file line of the error, e.g. `✗ Block 3 (doc.md:16), error at doc.md:18`.
- The ASCII preview is best-effort; not all diagram types are supported.
- Nothing is written next to the input. Pass `out.svg` only when the user wants a rendered file.

## Workflow

1. Pick the diagram type (table below).
2. Write the diagram where it belongs: a ```` ```mermaid ```` block in the Markdown file, or a `.mmd` file.
3. Run `./tools/validate.sh` on that file.
4. Fix any errors and re-run until it passes. Don't report a diagram as done before it validates.

## Choose a diagram type

| Need | Type | Starter |
| --- | --- | --- |
| Process, decision tree, architecture | Flowchart | `flowchart LR` |
| Calls and messages between parts | Sequence | `sequenceDiagram` |
| Lifecycle, state machine | State | `stateDiagram-v2` |
| Classes, modules, relationships | Class | `classDiagram` |
| Database tables and cardinality | ER | `erDiagram` |
| Schedule, project plan | Gantt | `gantt` |
| Events over time | Timeline | `timeline` |
| Branches and merges | Git graph | `gitGraph` |
| Brainstorm, topic breakdown | Mindmap | `mindmap` |
| Shares of a whole | Pie | `pie` |
| Bars or lines over categories | XY chart | `xychart-beta` |
| Two-axis prioritisation | Quadrant | `quadrantChart` |
| User steps and sentiment | User journey | `journey` |
| Flows between quantities | Sankey | `sankey-beta` |

## Authoring guidance

- Keep labels short and concrete; reuse the user's terms.
- Label edges whenever a branch or message would otherwise be ambiguous.
- Use `LR` for wide flows and `TB` for narrow documents.
- Split a crowded diagram into several focused ones instead of shrinking it.
- Don't rely on color alone to carry meaning.

## Common syntax mistakes

- Quote labels that contain punctuation or parentheses: `A["Parse (v2)"]`, not `A[Parse (v2)]`.
- `end` in lowercase as a node ID breaks flowcharts; use `End` or `finish`.
- Node IDs can't contain spaces; give the ID a label instead: `api[Payment API]`.
- For a line break inside a label, use `<br>` in a quoted label: `A["one<br>two"]`.
- In sequence diagrams, every message needs both sides: `A->>B: text`.
