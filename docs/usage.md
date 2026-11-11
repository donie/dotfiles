# Day-to-day use

How to change things on one machine and bring them to the others. For setup
from scratch see `macos-manual.md` or `linux-manual.md`; for the reasoning behind the layout see
`design.md`.

## Making a change

1. Edit, commit, push.
   - Plain files under `home/` are symlinked into `~`, so editing
     `~/.tmux.conf` edits the repo directly.
   - Templates (`*.tmpl`) are rendered copies: edit them in `home/` and run
     `./install` (or `chezmoi apply`).
2. On every other machine: `git -C ~/dotfiles pull && ./install`, or
   `chezmoi update`, which does both.

## What `./install` does on a machine that's already set up

chezmoi compares the repo with the machine and only acts on differences.

| Change in the repo | What the other machine does |
|---|---|
| Edited a symlinked file | Nothing: `git pull` already changed the file the link points to |
| Added a file under `home/` | Creates the link |
| Edited a template | Rewrites the rendered copy if the result changed |
| Secret-bearing file (`create_`) | Never re-rendered once it exists, so the vault isn't needed |
| Removed a file from `home/` | **Nothing.** The old link stays. List the path in `home/.chezmoiremove` to delete it everywhere, or remove it by hand |

Scripts in `home/.chezmoiscripts/` follow their name prefix:

| Prefix | Ours | Runs |
|---|---|---|
| `run_onchange_` | Homebrew, apt (Linux), mise tools, fisher, agent skills, vim plugins, macOS settings | When the rendered script changes. Each embeds a checksum of its inputs (Brewfile, apt list, mise config, vimrc, …), so changing an input reruns it. |
| `run_once_` | dotbot link cleanup, mise install (Linux) | Once per machine |
| `run_after_` | fonts, hostname, login shell | Every apply; they check first and exit when there's nothing to do |

What each machine has run is recorded in `~/.config/chezmoi/chezmoistate.boltdb`.
A new machine runs everything once.

## What never happens automatically

- **Upgrades.** Missing packages get installed; installed ones are never
  upgraded. Run `brew upgrade` (or `brew cu` for casks) and `mise upgrade`;
  on Linux, `sudo apt upgrade` and `mise self-update`.
  mise entries set to `latest` mean "newest at install time", so machines
  drift until each one upgrades; pin a version where it matters.
- **Uninstalls.** Removing a line from a Brewfile or the mise config leaves the
  package installed. To find leftovers:
  - Homebrew: `cat ~/dotfiles/packages/Brewfile* | brew bundle cleanup --file=-`
    (add `--force` to remove). It also lists App Store apps that are still
    installed but no longer in any Brewfile (e.g. apps removed from the
    store); skip `--force` if you want to keep those.
  - apt: `sudo apt remove <package>` by hand; the list is short.
  - mise: `mise prune` removes versions no config uses.
- **Removed configs.** See the table above.

## Previewing

- `chezmoi diff`: exact changes to files.
- `chezmoi status`: short list. ` R` lines for `run_after_` scripts are normal.
- `./install --dry-run --verbose`: everything, without changing anything.
- `chezmoi verify --exclude scripts`: exits 0 when every managed file matches.

## Machine role and hostname

- Asked once by `chezmoi init` and stored in `~/.config/chezmoi/chezmoi.toml`.
- The role prompt accepts any unique abbreviation and continues as soon as
  the input is unambiguous: `mac-w` already means `mac-work`, `d` means
  `devbox`. Check the result with
  `grep -A3 '\[data\]' ~/.config/chezmoi/chezmoi.toml`.
- To change either later:
  `chezmoi init --source ~/dotfiles --promptChoice "Machine role=<role>" --promptString "Hostname=<name>"`,
  then `./install`. Packages installed for the old role stay installed.

## Troubleshooting

- **A Homebrew tap fails with a GitHub login prompt** ("Invalid username or
  token", "could not read Username"): the tap's repository most likely no
  longer exists. GitHub asks for credentials instead of answering 404 for
  missing repos over HTTPS. Check with `gh api repos/<owner>/homebrew-<tap>`
  and drop or replace the tap.
- **`brew bundle check` says a formula "needs to be installed or updated"**
  when it is installed: it counts outdated packages as unsatisfied.
  `./install` uses `--no-upgrade` and won't touch them.
- **`mas` says "No apps found in the App Store for ADAM ID"**: the app was
  removed from the store (or isn't sold in your region). Drop it from the
  Brewfile; an already installed copy keeps working.
- **A cask fails with "It seems there is already an App at …"**: the app was
  installed outside Homebrew. `brew install --cask --adopt <name>` makes
  Homebrew manage it; if versions differ, delete the app first.
- **A cask is "unavailable: No Cask with this name exists"**: Homebrew removed
  or renamed it. `brew search --cask <name>` for a successor, or drop it.
- **Fonts are skipped with "probably not downloaded from iCloud"**: mark the
  fonts folder Keep Downloaded (see `macos-manual.md`) and rerun `./install`.
- **A mise tool fails on Linux with "unsupported env: linux/arm64"** (or
  amd64): the tool's registry entry doesn't list a build for that platform,
  even if upstream ships one. Check the release assets
  (`gh release view --repo <owner>/<repo>`); if the build is there, use the
  `github:<owner>/<repo>` backend, which reads the release directly. If
  there's no build and mise falls back to `cargo install` ("cargo may be
  required"), the tool belongs in the dev set, which has Rust (`tokei` is
  there for this reason).
- **apt hangs during `./install`**: a package is asking a configuration
  question. The apt script runs apt-get with `DEBIAN_FRONTEND=noninteractive`
  through `sudo env`, because sudo drops it from the environment otherwise.
  If it happens anyway, answer in another terminal or kill the `dialog`
  process, then run `sudo dpkg --configure -a`.
- **A script failed midway**: fix the cause and rerun `./install`. Scripts are
  idempotent, and chezmoi only records a `run_onchange_` script as done when
  it succeeds, so a failed one runs again.
- **Some Homebrew entries failed** (App Store not signed in, a network
  error): the Homebrew script only warns, so it counts as done and won't rerun
  until a Brewfile changes. Retry by hand:
  `cat ~/dotfiles/packages/Brewfile ~/dotfiles/packages/Brewfile.<personal|work> | brew bundle install --no-upgrade --file=-`
