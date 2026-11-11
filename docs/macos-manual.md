# macOS: manual steps

What `./install` can't do on a new Mac. Settings will be added in phase 5
(see `design.md`).

## Before `./install`

- [ ] Sign in to the App Store, so `mas` can install the App Store apps in
      the Brewfiles.
- [ ] Log in to the password manager CLI (`bw login`, then
      `set -gx BW_SESSION (bw unlock --raw)`) if this Mac gets
      secret-bearing configs (role `mac-personal`).

## Apps installed by hand

| App | Why it's manual | How |
|---|---|---|
| Rex (terminal) | Beta, no Homebrew cask yet | superlogical.com/rex/docs/installation |
| Claude Code, Amp, Cursor Agent, Droid | Install and update themselves | Each vendor's install script; they land in `~/.local/bin` |
| BBDown | Reads its config and login data from its own directory | Release zip from github.com/nilaoda/BBDown into `~/_runtime/bin` |
| Orca, Open WebUI, krokiet | Only needed on some machines | As needed |
| Anything in `packages/Brewfile.extras` | Optional per machine | `brew bundle --file=~/dotfiles/packages/Brewfile.extras`, or `brew install --cask <name>` |
