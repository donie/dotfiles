# macOS: manual steps

What `./install` can't do on a new Mac. Scripted settings are in
`home/.chezmoiscripts/run_onchange_after_50-macos-defaults.sh.tmpl`; this is
everything else.

## Before `./install`

- [ ] Sign in to the App Store, so `mas` can install the App Store apps in
      the Brewfiles.
- [ ] Log in to the password manager CLI (`bw login`, then
      `set -gx BW_SESSION (bw unlock --raw)`) if this Mac gets
      secret-bearing configs (role `mac-personal`).

- [ ] Run `./install` from a terminal: it asks for the role and hostname,
      and needs your password once to set the hostname and the login shell.

## After `./install`

- [ ] Log out and back in, so trackpad and keyboard-shortcut settings apply.
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

1. `brew install chezmoi`, then `git -C ~/dotfiles pull`. Warnings that
   `dotbot` and `dotfiles-private` can't be removed are expected: Git leaves
   the old submodule directories behind.
2. mac-personal only: unlock the password manager CLI (see "Before
   `./install`"); `~/.gallery-dl.conf` is created from the vault.
3. `./install` in a terminal. Before applying, a one-time script
   (`run_once_before_00-retire-dotbot-links.sh.tmpl`) removes the old dotbot
   links that are dead or point into `dotbot`/`dotfiles-private`, and turns a
   symlinked `~/.config/fish` into a real directory, keeping
   `fish_variables`. Homebrew then installs whatever the Brewfiles list that's
   missing, which can take a while.
4. Delete the leftovers: `rm -rf ~/dotfiles/dotbot ~/dotfiles/dotfiles-private
   ~/dotfiles/.git/modules`. Untracked leftovers of moved configs (for example
   `~/dotfiles/shell/fish`) show in `git status --ignored` and can go too.
5. Optional cleanup of what mise now provides:
   - `cat ~/dotfiles/packages/Brewfile* | brew bundle cleanup --file=-` lists
     Homebrew packages that aren't in any Brewfile; add `--force` to remove
     them.
   - Remove old version managers: `rm -rf ~/.nvm ~/.rbenv`.
