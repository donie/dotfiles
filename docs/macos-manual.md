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
