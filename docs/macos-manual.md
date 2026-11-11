# macOS: manual steps

What `./install` can't do on a new Mac. Day-to-day updates and
troubleshooting are in `usage.md`. Scripted settings are in
`home/.chezmoiscripts/run_onchange_after_50-macos-defaults.sh.tmpl`; this is
everything else.

## Before `./install`

- [ ] Sign in to the App Store, so `mas` can install the App Store apps in
      the Brewfiles.
- [ ] Sign in to iCloud and make sure the licensed fonts are fully
      downloaded: in Finder, right-click iCloud Drive > Documents > Setups >
      fonts and choose **Keep Downloaded**. With "Optimize Mac Storage" on,
      iCloud may keep only placeholders, which the font script can't read;
      it skips them with a warning, and a later `./install` picks them up.
- [ ] mac-personal only: install and unlock the password manager CLI, so
      chezmoi can create secret-bearing configs on the first run. The
      Brewfile installs `bitwarden-cli` too, but chezmoi needs it earlier.
      ```fish
      brew install bitwarden-cli
      bw login
      set -gx BW_SESSION (bw unlock --raw)
      ```
      Run `./install` in the same shell.

- [ ] Run `./install` from a terminal: it asks for the role and hostname,
      and needs your password once to set the hostname and the login shell.

## After `./install`

- [ ] Log out and back in, so trackpad and keyboard-shortcut settings apply.
- [ ] `gh auth login` (GitHub.com, HTTPS, log in with a browser). `gh` comes
      from mise, but logging in is manual. `.gitconfig` uses `gh` as git's
      credential helper for github.com, so pushing over HTTPS needs it;
      cloning and pulling public repos don't. The token is stored in the
      macOS Keychain. Not automated on purpose: the browser login creates a
      token per machine that can be revoked on its own, while a token kept in
      the vault would be one long-lived token shared by every machine.
- [ ] Raycast: set its hotkey to ⌘Space (the script frees it from
      Spotlight). Shottr: set ⌘⇧3/4/5 the same way.
- [ ] `BBDown login` (mac-personal): the login cookie is local only, in
      `~/.config/BBDown/BBDown.data`.

## Settings that can't be scripted

- [ ] Keyboard > Input Sources: add **ABC** and **Pinyin – Simplified**.
      Input sources written with `defaults` don't load reliably.
- [ ] Lock Screen > Require password after screen saver begins: 5 minutes
      (`sysadminctl -screenLock 300 -password -` also works).
- [ ] Safari > Extensions: enable Wipr and Userscripts.
- [ ] Spotlight > Search Privacy: exclude large folders you don't search
      (the exclusion list is protected and can't be written by a script).
- [ ] Dictionaries (mac-personal): copy the `.dictionary` bundles (LDOCE5 and
      the Chinese/Japanese/Korean ones) from a backup into
      `~/Library/Dictionaries`, then enable them in Dictionary > Settings.
      They're third-party and stay out of this repo.
- [ ] Only if region-locked emoji are hidden (macOS on devices sold in some
      regions hides the ROC flag): set the system Country and log out.
      ```sh
      /usr/libexec/PlistBuddy -c "Print :Country" /Library/Preferences/.GlobalPreferences.plist
      sudo defaults write /Library/Preferences/.GlobalPreferences.plist Country -string TW
      ```

## Apps installed by hand

| App | Why it's manual | How |
|---|---|---|
| Rex (terminal) | Beta, no Homebrew cask yet | superlogical.com/rex/docs/installation |
| Claude Code, Amp, Cursor Agent, Droid | Install and update themselves | Each vendor's install script; they land in `~/.local/bin` |
| Orca, Open WebUI, krokiet | Only needed on some machines | As needed |
| Anything in `packages/Brewfile.extras` | Optional per machine | `brew bundle --file=~/dotfiles/packages/Brewfile.extras`, or `brew install --cask <name>` |

## Migrating a Mac from the old dotbot setup

For a Mac that still has the dotbot-based checkout of this repo.

1. `brew install chezmoi` (plus `bitwarden-cli` on mac-personal), then
   `git -C ~/dotfiles pull`. Warnings that
   `dotbot` and `dotfiles-private` can't be removed are expected: Git leaves
   the old submodule directories behind.
2. mac-personal only: unlock the password manager CLI (see "Before
   `./install`"); `~/.gallery-dl.conf` is created from the vault.
3. Optional preview of what Homebrew would install:
   `cat ~/dotfiles/packages/Brewfile ~/dotfiles/packages/Brewfile.<personal|work> | brew bundle check --verbose --file=-`.
   Apps that are already there but were installed outside Homebrew or the
   App Store show up as missing, and their entries would fail ("already an
   App at …"); adopt or drop them first (see `usage.md`, Troubleshooting).
4. `./install` in a terminal. Before applying, a one-time script
   (`run_once_before_00-retire-dotbot-links.sh.tmpl`) removes the old dotbot
   links that are dead or point into `dotbot`/`dotfiles-private`, and turns a
   symlinked `~/.config/fish` into a real directory, keeping
   `fish_variables`. Homebrew then installs whatever the Brewfiles list that's
   missing, which can take a while.
5. Delete the leftovers: `rm -rf ~/dotfiles/dotbot ~/dotfiles/dotfiles-private
   ~/dotfiles/.git/modules`. Untracked leftovers of moved configs (for example
   `~/dotfiles/shell/fish`) show in `git status --ignored` and can go too.
6. Optional cleanup of what mise now provides:
   - `cat ~/dotfiles/packages/Brewfile* | brew bundle cleanup --file=-` lists
     Homebrew packages that aren't in any Brewfile; add `--force` to remove
     them.
   - Remove old version managers: `rm -rf ~/.nvm ~/.rbenv`.

### Verifying the migration

```fish
# 1. The cleanup script ran (one line with a timestamp)
chezmoi state get-bucket --bucket=scriptState | jq -r '.[] | "\(.runAt)  \(.name)"' | grep retire

# 2. No dead links, and none into dotbot/dotfiles-private (prints only "done")
set dirs ~ ~/.config ~/.config/fish ~/.config/fish/conf.d
set -a dirs ~/.config/fish/functions ~/.config/fish/completions ~/.config/ghostty
set -a dirs ~/.claude ~/.claude/skills ~/.codex ~/.codex/skills
set -a dirs ~/.pi/agent ~/.pi/agent/skills ~/.pi/agent/extensions
set -a dirs ~/.vim/autoload ~/_runtime ~/_runtime/bin
for d in $dirs
    for l in (find $d -maxdepth 1 -type l 2>/dev/null)
        set t (readlink $l)
        if not test -e $l; or string match -q -r "dotbot/|dotfiles-private/" -- $t
            echo "$l -> $t"
        end
    end
end
echo done

# 3. ~/.config/fish is a real directory, and fish_variables survived
test -L ~/.config/fish; and echo "still a symlink"; or echo "real directory"
ls ~/.config/fish/fish_variables

# 4. Every managed file matches the repo
chezmoi verify --exclude scripts; and echo OK
```

The first `./install` also prints one `removed old dotbot link: …` line per
link it removed.
