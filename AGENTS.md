# Agent Guide for `donie/dotfiles`

This repository is a **public** dotfiles managed by [dotbot](https://github.com/anishathalye/dotbot). It contains the user's personal shell, editor, and tool configurations for macOS (primary) and potentially Linux.

---

## Architecture Overview

### Dotbot Bootstrap
- Entry point: `./install` (Bash script)
- Dotbot config: `./install.conf.yaml`
- The install script initializes the `dotbot` submodule and runs `bin/dotbot` against the YAML config.
- **To install on a new machine**: `git clone --recurse-submodules <repo>` then run `./install`.

### Public vs Private Split

| Repository | Visibility | Contents |
|------------|-----------|----------|
| `donie/dotfiles` | **Public** | Shell configs, editor configs, nvim, tmux, mpv, bin scripts, generic tooling |
| `donie/dotfiles-private` | **Private** | Confidential data, licensed assets, and personal configs that must not be made public |

`dotfiles-private` is included as a **Git submodule** (`./dotfiles-private`). It is referenced in `install.conf.yaml` to symlink private assets into `~`.

---

## Key Directory Map

```
.
├── install                 # Bootstrap script (run this to install)
├── install.conf.yaml       # Dotbot manifest
├── dotbot/                 # Dotbot submodule (GitHub: anishathalye/dotbot)
├── dotfiles-private/       # PRIVATE submodule — see warning below
├── agents/                 # Coding agent configs (claude, codex, pi, skills)
├── shell/                  # Shell configs (fish, zsh, git, kitty, ghostty, wezterm)
├── nvim/                   # Neovim configuration (Lua-based)
├── vim/                    # Vim configuration + vim-plug bootstrap
├── tmux/                   # tmux config
├── mpv/                    # mpv player config
├── bin/                    # Utility scripts symlinked to ~/_runtime/bin/
└── sublime/                # Sublime Text user settings (macOS only)
```

### Symlink Targets (from `install.conf.yaml`)
- `agents/*` → `~/.claude/*`, `~/.codex/*`, `~/.pi/agent/*`
- `shell/*` → `~/.config/*`, `~/.zshrc`, `~/.gitconfig`
- `nvim/` → `~/.config/nvim`
- `vim/vimrc` → `~/.vimrc`
- `tmux/tmux.conf` → `~/.tmux.conf`
- `mpv/` → `~/.config/mpv` (excludes `watch_later/`)
- `bin/*` → `~/_runtime/bin/*`
- `dotfiles-private/*` → various `~` locations for private configs/assets (see `install.conf.yaml`)

---

## ⚠️ Critical Rules for Agents

### 1. NEVER modify `dotfiles-private`
- `dotfiles-private/` contains **confidential data and commercial assets** (e.g. licensed fonts, credentials, personal bundles).
- Do **not** read files inside `dotfiles-private/` beyond names/sizes unless explicitly asked by the user.
- Do **not** commit changes inside `dotfiles-private/`.
- Do **not** log, echo, or expose paths or contents from `dotfiles-private` in commit messages, PRs, or generated documentation.

### 2. Keep `install.conf.yaml` valid
- This is the source of truth for dotbot. When adding or removing dotfile links, update this YAML file.
- Use `relink: true` and `create: true` defaults already set at the top of the file.
- If a new config directory needs symlinking, follow the existing pattern:
  ```yaml
  ~/.config/<tool>: <local-dir>/
  ```

### 3. Submodules
- There are two submodules: `dotbot` and `dotfiles-private`.
- When cloning the repo fresh, use `--recurse-submodules`.
- `dotbot` is upstream from `anishathalye/dotbot`; do not commit custom changes into it.
- If `dotfiles-private` fails to update (e.g. SSH key missing on a new machine), the install will error on that step. This is expected and should be handled by the user.

### 4. Cross-platform considerations
- This repo is primarily macOS-centric (`Darwin` checks exist, Sublime Text path targets `~/Library/...`).
- `fish` is the default login shell (`chsh -s $(which fish)` is run by dotbot).
- Some `bin/` scripts or `shell/` configs may assume macOS paths or Homebrew. Test changes on macOS if possible, or gate with `if: '[ $(uname) = Darwin ]'` in dotbot config.

---

## Agent Configurations

All coding agent configurations are managed under `agents/`:

| Agent | Directory | Sync Method |
|-------|-----------|-------------|
| Claude | `agents/claude/` | dotbot symlink |
| Codex | `agents/codex/` | dotbot symlink |
| pi | `agents/pi/` | dotbot + `pi update --extensions` |
| Skills | `agents/skills/manifest.json` | `npx skills add/update` |

Run `agents/bin/sync-agents` to update everything.
Run `agents/bin/sync-pi` to update pi packages and fetch latest `uv.ts`.
Run `agents/bin/sync-skills` to update all skills from the manifest.

## Common Tasks

### Adding a new tool config
1. Create the config directory/file in the repo (e.g. `shell/myapp/`).
2. Add a `link:` entry in `install.conf.yaml` pointing to the desired `~` location.
3. Run `./install` to verify it symlinks correctly.
4. Do **not** add secrets or licensed assets to the public repo.

### Removing a tool config
1. Remove the `link:` entry from `install.conf.yaml`.
2. Optionally remove the source directory from the repo.
3. Consider adding a `clean: ['~']` target or manual cleanup note if orphaned symlinks remain.

### Updating dotbot
```bash
cd dotbot && git fetch && git checkout <tag> && cd .. && git add dotbot && git commit -m "Update dotbot to <tag>"
```

---

## Testing Checklist

Before claiming changes are complete:
- [ ] No new files were accidentally created inside `dotfiles-private/`.
- [ ] No secrets, tokens, or licensed assets were added to the public repo.
- [ ] `install.conf.yaml` parses as valid YAML.
