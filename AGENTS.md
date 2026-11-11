# Agent Guide for `donie/dotfiles`

This repository is a **public** dotfiles repo managed by [chezmoi](https://www.chezmoi.io/). It holds the user's shell, editor, terminal and coding-agent configurations for macOS (primary) and Linux (Debian, Arch; in progress). The plan and its rationale are in `docs/design.md`.

---

## Architecture Overview

### How it installs
- Entry point: `./install`, a thin wrapper. On first run it calls `chezmoi init --source <repo>`, which asks for the machine role, then it runs `chezmoi apply` (extra arguments are passed through, e.g. `./install --dry-run --verbose`).
- Machine roles: `mac-personal`, `mac-work`, `devbox`, `server`. Non-interactive init: `chezmoi init --source <repo> --promptChoice "Machine role=<role>"` (the key is the prompt text).
- `.chezmoiroot` points chezmoi at `home/`, the source state. Everything else at the repo root is supporting material.
- chezmoi runs in **symlink mode**: plain files in `home/` become symlinks into the repo, so edits through `~` land in Git. Templates (`*.tmpl`), `private_` and `encrypted_` files are rendered copies; edit those in `home/` and run `chezmoi apply`.
- Configs whose apps write new files into their directory (nvim, mpv, kitty, rex, Sublime `User`) stay as top-level directories and are linked as whole directories by `symlink_*.tmpl` entries in `home/`.
- What goes where by OS and role is decided in `home/.chezmoiignore`.

### Public vs private
| Location | Contents |
|---|---|
| This repo | Everything that can be public |
| Password manager | Secrets, read by `create_private_*.tmpl` templates |
| iCloud Drive `Documents/Setups/fonts/` | Licensed fonts, installed by a script; never in Git |
| `dotfiles-private/` submodule | Being retired (phase 7); no longer used by `./install` |

---

## Key Directory Map

```
.
├── install                 # Wrapper: chezmoi init (first run) + chezmoi apply
├── .chezmoiroot            # Contains "home"
├── home/                   # chezmoi source state (mirrors ~)
│   ├── .chezmoi.toml.tmpl  # Role prompt, symlink mode
│   ├── .chezmoiignore      # Per-OS / per-role exclusions
│   ├── .chezmoiscripts/    # brew bundle, mise install, fisher plugins, agent skills, vim plugins, fonts, login shell
│   ├── dot_config/         # fish, ghostty, mise; symlink_ entries for nvim, mpv, kitty, rex
│   ├── dot_claude/ dot_codex/ dot_pi/   # Coding agent configs
│   ├── dot_gitconfig dot_tmux.conf dot_vimrc dot_vim/
│   ├── _runtime/bin/       # Personal scripts → ~/_runtime/bin
│   └── private_Library/    # Sublime Text User link (macOS)
├── packages/               # Brewfile (shared), Brewfile.personal, Brewfile.extras (manual)
├── agents/                 # Agent tooling: sync scripts, skills manifest, repo-local skills
├── nvim/ mpv/ rex/         # Whole-directory configs (linked from home/)
├── shell/                  # bash (Linux, not yet managed), kitty (linked from home/)
├── sublime/                # Sublime Text User package (linked from home/)
├── tmux/shared.sh          # Unreferenced helper, kept for now
├── docs/                   # design.md, macos-manual.md
└── dotfiles-private/       # PRIVATE submodule (being retired) — see rule 1
```

---

## ⚠️ Critical Rules for Agents

### 1. NEVER modify `dotfiles-private`
- It contains confidential data and licensed material.
- Do **not** read files inside it beyond names and sizes unless the user explicitly asks.
- Do **not** commit changes inside it, or expose its paths or contents in commit messages, PRs or docs.

### 2. Secrets and licensed assets
- Never commit literal secrets, encrypted or not. Secret-bearing configs are `create_private_*.tmpl` templates that read values from the password manager (currently `bitwardenFields`). Never print vault values.
- `create_` means the vault is only read when the target doesn't exist yet; everyday `chezmoi apply` doesn't need an unlocked vault.
- `home/dot_pi/agent/web-search.json` must stay credential-free. If a provider key is ever needed, use a `"$ENV_VAR"` or `"!command"` credential source, never a literal key.
- Licensed assets (fonts) never enter the repo.

### 3. One owner per path
- Every target in `~` is managed by chezmoi or by nothing. When adding a config, add it under `home/`; when removing one, delete it from `home/` and remove the now-dangling target by hand (chezmoi doesn't clean up like dotbot did; use `home/.chezmoiremove` if needed).
- Watch directory permissions: chezmoi sets a directory's mode from its source name. Existing `0700` directories (e.g. `~/Library`) need `private_` in their source path, or chezmoi will loosen them. Check `chezmoi diff` for `old mode 40…` lines.

### 4. Cross-platform
- macOS is primary; Linux support is in progress (`docs/design.md`, phase 6).
- fish is the macOS login shell (set by `run_after_90-login-shell.sh.tmpl`); Linux uses bash.
- Gate OS- or role-specific targets in `home/.chezmoiignore`, and OS-specific scripts with `{{ if eq .chezmoi.os "darwin" }}`.

---

## Packages

- **Homebrew** (macOS only): what must be native: casks, App Store apps, fonts, GNU userland, shells, build toolchains. `packages/Brewfile` is shared by both Macs, `Brewfile.personal` adds personal apps, `Brewfile.extras` is never installed automatically. The install script never upgrades or removes anything.
- **mise** (every OS): portable CLI tools and language runtimes. `home/dot_config/mise/config.toml` is the core set (every role); `conf.d/dev.toml` (not on servers) and `conf.d/personal.toml` (mac-personal) are gated in `.chezmoiignore`. Use `os = ["macos"]` / `["linux"]` per tool for OS-specific entries.
- Add a CLI tool to mise, not Homebrew, unless it has no mise build for the OS (e.g. `btop` on macOS) or must be a real system binary.
- Config that shells out to mise tools from non-interactive contexts must use the shims (`$HOME/.local/share/mise/shims/<tool>`), as `home/dot_gitconfig` does for `delta` and `gh`.
- Python projects use uv; Python CLI tools go in mise as `pipx:<name>`.

## Agent Configurations

| Agent | Location | Sync |
|---|---|---|
| Claude | `home/dot_claude/` | chezmoi |
| Codex | `home/dot_codex/AGENTS.md` | chezmoi |
| pi | `home/dot_pi/agent/` | chezmoi + `pi update --extensions` |
| Repo-local skills | `agents/skills/local/` (all agents), `agents/claude/skills/` (Claude) | linked by `run_onchange_after_20-agent-skills.sh.tmpl` |
| Installed skills | `agents/skills/manifest.json` | `npx skills add/update` |

- `agents/bin/sync-agents`: runs `./install`, then the two scripts below.
- `agents/bin/sync-pi`: updates pi packages and fetches the latest `uv.ts`.
- `agents/bin/sync-skills`: installs and updates skills from the manifest.

fisher plugin files are not tracked: `home/dot_config/private_fish/fish_plugins` lists them and `run_onchange_after_10-fish-plugins.sh.tmpl` installs them.

## Common Tasks

### Adding a config
1. Single file: put it under `home/` using chezmoi naming (`dot_`, `private_`, …), e.g. `home/dot_config/myapp/config`.
2. A directory the app writes into: keep it at the repo root and add `home/<path>/symlink_<name>.tmpl` containing `{{ .chezmoi.workingTree }}/<dir>`.
3. Gate it by OS or role in `home/.chezmoiignore` if needed.
4. Run `chezmoi diff`, then `./install`.

### Removing a config
1. Delete it from `home/` (and its root directory, if any).
2. Remove the target in `~` by hand, or list it in `home/.chezmoiremove`.

---

## Testing Checklist

Before claiming changes are complete:
- [ ] `chezmoi diff` shows only intended changes (including no unexpected `old mode 40…` directory permission changes).
- [ ] `chezmoi status` is clean after `./install` (` R` lines for `run_after_` scripts are expected).
- [ ] Rendered scripts pass `chezmoi execute-template < <script.tmpl> | sh -n`.
- [ ] No files were created inside `dotfiles-private/`.
- [ ] No secrets, tokens or licensed assets were added to the repo.
