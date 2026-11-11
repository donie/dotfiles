# Dotfiles redesign

Status: **proposal**. Nothing in this document is implemented yet. The current
dotbot setup described in `AGENTS.md` remains the source of truth until the
migration lands.

## Goals

1. Bootstrap a fresh machine with one command and no prior Git credentials.
2. Install and maintain packages: Homebrew for macOS-native software, mise
   for runtimes and portable CLI tools.
3. Apply macOS system settings reproducibly, and document what can't be
   automated.
4. Support macOS, Debian and Arch Linux, with behavior selected by machine
   role.
5. Keep secrets and licensed assets out of the public repo, including in
   encrypted form.

## Non-goals

- Fully declarative systems (Nix, nix-darwin, home-manager). The learning
  curve and maintenance cost aren't justified for this scope. Revisit only
  if the role and package logic outgrows chezmoi templates.
- Recreating the current machine byte for byte. It is the reference, but its
  settings are reviewed one by one, not cloned (see [Audit](#audit-of-the-reference-machine)).
- Windows support.

## Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Migrate from dotbot to **chezmoi** | Built-in roles and OS templating, secret-manager integration, `run_once_` and `run_onchange_` scripts, single static binary, one-line bootstrap. Dotbot would need all of this rebuilt by hand. |
| D2 | chezmoi `mode = "symlink"` | Plain files stay symlinks into the repo, so in-place edits and tools that write back to their config, such as agent settings, keep working. Templates and secret-bearing files are rendered copies. |
| D3 | Secrets come from a **password-manager CLI** through templates | No ciphertext in public history, so nothing can be brute-forced later and nothing has to be rotated if a passphrase leaks. The vault login is the only bootstrap credential. chezmoi supports most password managers, and switching providers is a one-line template change. |
| D4 | **Licensed assets never enter Git**, encrypted or not | Licenses generally forbid redistribution, and binary blobs bloat public history permanently. They're pulled from cloud storage at install time, on roles that need them. |
| D5 | Retire the private submodule | Covered by D3 (secrets) and D4 (assets). Package lists aren't sensitive and become public. |
| D6 | **fish** on macOS, **bash** on Linux; retire zsh | zsh plus a prompt framework is heavier than needed. bash is always present on servers. |
| D7 | **Homebrew** for OS-native software, **mise** for runtimes and portable CLI tools | mise gives identical tool versions across macOS, Debian and Arch. Homebrew, apt and pacman keep what must be native: GUI apps, fonts, system libraries, build dependencies and login shells. A mise shim can't be listed in `/etc/shells`. |
| D8 | Age encryption kept only as a fallback | Use it only for a secret that must reach a machine without vault access. Use post-quantum hybrid keys (`age-keygen -pq`) and a high-entropy passphrase if it's ever adopted. |

## Machine roles

The role is chosen once during `chezmoi init` (`promptChoiceOnce`) and stored
in the local chezmoi config. The OS is detected from `.chezmoi.os` and
`.chezmoi.osRelease`.

| Layer | `mac-personal` | `mac-work` | `devbox` | `server` |
|---|:-:|:-:|:-:|:-:|
| Shell | fish | fish | bash | bash |
| Core CLI tools (mise) | ✓ | ✓ | ✓ | ✓ |
| Dev runtimes (mise) | ✓ | ✓ | ✓ | – |
| Editor config (nvim) | ✓ | ✓ | ✓ | ✓ |
| tmux | ✓ | ✓ | ✓ | ✓ |
| Agent configs | ✓ | ✓ | ✓ | optional |
| Homebrew formulae and casks | ✓ | ✓ (work set) | – | – |
| Mac App Store apps (`mas`) | ✓ | partial | – | – |
| macOS settings | ✓ | ✓ | – | – |
| Desktop app configs (terminals, media player, editors) | ✓ | ✓ | – | – |
| Licensed fonts | ✓ | ✓ | – | – |
| Secret-bearing configs | ✓ | – | – | – |

Servers get full command-line parity (same shell setup, aliases and core
tools) but no language toolchains.

## Repository layout (target)

```
.chezmoiroot              # contains "home"; the repo root holds docs and scripts
docs/
  design.md               # this file
  macos-manual.md         # steps that can't be automated, as a checklist
home/                     # chezmoi source state
  .chezmoi.toml.tmpl      # prompts for role; sets mode = "symlink"
  .chezmoiignore          # templated: drops layers by role and OS
  .chezmoidata/           # shared data, e.g. alias definitions used by fish and bash
  dot_config/
    private_fish/         # macOS; private_ keeps fish's 0700 directory mode
    nvim/  tmux/  mise/  git/  ...
  dot_bashrc.tmpl         # Linux
  .chezmoiscripts/
    run_onchange_before_10-packages-darwin.sh.tmpl   # brew bundle; reruns when the Brewfile changes
    run_onchange_before_10-packages-linux.sh.tmpl    # apt or pacman, minimal
    run_onchange_after_20-mise.sh.tmpl               # mise install
    run_onchange_after_30-macos-defaults.sh.tmpl
    run_once_after_40-fonts-darwin.sh.tmpl           # copy licensed fonts from cloud storage, if present
    run_once_after_90-login-shell.sh.tmpl            # chsh only if not already set
packages/
  Brewfile                # shared
  Brewfile.personal  Brewfile.work
  apt.txt  pacman.txt
```

`run_onchange_` scripts embed a hash of their inputs, for example
`{{ include "../packages/Brewfile" | sha256sum }}`, so they rerun only when
the inputs change.

## Packages

| Kind | Owner | Examples |
|---|---|---|
| GUI apps, fonts, Quick Look plugins | Homebrew cask, `mas` | |
| GNU userland overrides, build dependencies, services | Homebrew formula | coreutils, meson |
| Login shells, tmux, git | OS package manager | fish (macOS), bash (Linux) |
| Language runtimes | mise (`dev` set) | node, go, ruby, bun |
| Portable CLI tools | mise (`core` set, aqua or ubi backends) | rg, fd, bat, eza, fzf, delta, jq, gh, nvim |
| Python tooling | uv | |
| Prebuilt third-party binaries currently committed to `bin/` | mise github or ubi backend | BBDown (then delete `bin/BBDown`) |

The mise config is a template. The `core` set is installed on every role,
and `dev` is added on every role except `server`. This replaces nvm, rbenv
and other per-language version managers.

## Secrets

- Secret-bearing files are `*.tmpl` files that read their values from the
  vault through chezmoi's password-manager template functions, for example
  `{{ <pm-function> "<item>" "<field>" }}`.
  The repo holds only the file's structure.
- `.chezmoiignore` excludes them on roles that don't need them, so those
  machines never need vault access.
- Rendering requires an unlocked vault session. Edit these files through
  `chezmoi edit`, not in place.
- Never commit literal credentials. Existing guidance in `install.conf.yaml`
  about `"$ENV_VAR"` and `"!command"` credential sources carries over.

## Licensed assets

Fonts and similar assets live in personal cloud storage. A `run_once_`
script copies them into place if the source folder exists and skips
otherwise, so a machine without cloud storage still installs cleanly.

## macOS settings

- `run_onchange_after_30-macos-defaults.sh` holds idempotent
  `defaults write`, `scutil` and `PlistBuddy` calls, grouped by area and with
  a dry-run flag. It restarts affected processes (Dock, Finder,
  SystemUIServer) at the end.
- **Find keys on the current macOS version, don't copy them from old
  notes.** Snapshot `defaults read`, change the setting in System Settings,
  snapshot again, and diff.
- Anything requiring a GUI, Full Disk Access, Apple ID sign-in, or that
  macOS no longer exposes (some Spotlight, Sharing and Dictation settings,
  Safari extensions, App Store sign-in) goes into `docs/macos-manual.md` as
  a checklist.

## Bootstrap flow

macOS:

1. Install Homebrew, which also installs the Xcode Command Line Tools.
2. `brew install chezmoi age` (age only if D8 is ever used) and the
   password-manager CLI.
3. Log in to the vault CLI.
4. `chezmoi init --apply <github-user>`: clones over HTTPS without
   credentials, prompts for the role, links configs and runs the scripts.
   Non-interactive: add `--promptChoice "Machine role=<role>"`. The key is
   the prompt text, not the data key.
5. Work through `docs/macos-manual.md`.
6. Optionally, `gh auth login`. This is only needed to push.

Linux: same as macOS, using `sh -c "$(curl -fsLS get.chezmoi.io)" -- init
--apply <github-user>`. Steps 1–3 are skipped on `server` and `devbox`
unless a secret is needed there.

## Migration plan

Each phase lands on its own branch and is verified in a clean VM before
merging.

1. **Prune.** Remove zsh and its prompt framework, the unused WezTerm
   config, and backup and old files. Vim stays as is, next to nvim.
   *Done.*
2. **Pilot.** Bring git, fish and one secret-bearing template under chezmoi
   in symlink mode. Validate on a throwaway Linux VM and on this Mac.
   *git and fish done:* `~/.config/fish` is now a real directory with
   per-file symlinks, so fisher plugin files stay local and are no longer
   tracked. They're installed by a `run_onchange_` script keyed on
   `fish_plugins`.
3. **Configs.** Move the remaining configs. Delete `install`,
   `install.conf.yaml` and the dotbot submodule once nothing depends on
   them. Update `AGENTS.md` and `agents/bin/sync-*`.
4. **Packages.** Public Brewfiles, the mise config and Linux package lists.
   Remove version-manager setup from the shells and hardcoded Homebrew
   paths.
5. **macOS.** Settings script and the manual checklist.
6. **Linux.** Templated bashrc on the devbox, then server, then Arch.
7. **Retire the private submodule**, once D3 and D4 cover everything it
   held.
8. **CI (optional).** Debian and Arch containers run
   `chezmoi init --apply` with role `server`.

## Audit of the reference machine

The current Mac is the target state, but years of OS upgrades have left
cruft behind. Before each phase, check:

- [ ] `brew leaves`, `brew list --cask` and `mas list` against the
  Brewfiles: keep or drop each.
- [ ] Global installs outside Homebrew (cargo, npm, bun, uv tools, Go
  binaries, old version managers): move each to mise or drop it.
- [ ] `PATH` entries: each one justified or removed.
- [ ] `~/.config` and app preferences not tracked in the repo.
- [ ] LaunchAgents, login items, `/etc/shells` and `/etc/hosts`.
- [ ] macOS settings found with the snapshot-and-diff method above.

Results of the audit stay outside this public repo. Only the resulting
package lists and settings are committed.

## Testing

- Linux: disposable VMs or containers (OrbStack, Docker) for Debian and
  Arch.
- macOS: a disposable macOS VM (Tart or UTM) to prove the bootstrap from a
  clean install.
- Before merging any phase, run `chezmoi diff` on the reference machine and
  confirm it's empty or expected.

## Open questions

- Which password manager: templates are written so a later switch is
  mechanical.
- Should alias and environment definitions be generated for both fish and
  bash from `.chezmoidata`, or kept as two hand-maintained files?
- Do agent configs belong on the `server` role?
