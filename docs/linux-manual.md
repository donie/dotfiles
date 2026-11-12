# Linux setup

Setting up a Debian, Ubuntu or Arch machine (roles `devbox` and `server`).
For everyday use afterwards see `usage.md`.

## Before the bootstrap: sudo (minimal installs)

The bootstrap runs as your normal user and uses sudo for system packages and
locales. Cloud images and most installers already set this up. A minimal
install where you gave a root password (Debian's netinst, Arch) has no sudo,
so do this once as root (`su -`), replacing `donie` with your user:

```sh
# Debian, Ubuntu
apt install sudo curl
usermod -aG sudo donie

# Arch: also enable the wheel group, which the stock sudoers leaves commented out
pacman -S sudo
usermod -aG wheel donie
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel
```

Log out and back in so the new group applies, and check with `sudo true`.
This stays manual on purpose: chezmoi runs unprivileged and can't grant
itself root, and who gets root on a machine should be a visible, deliberate
step.

## Bootstrap

No git, Homebrew or vault login needed. As your normal user (not root), with
`curl` and `sudo` available:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin \
  init --apply --source ~/dotfiles donie
```

- Installs chezmoi to `~/.local/bin` and clones the repo to `~/dotfiles`
  over HTTPS. chezmoi's built-in git client is used while `git` isn't
  installed yet.
- Asks for the machine role: `devbox` or `server`. Non-interactive: add
  `--promptChoice "Machine role=server"`.
- Then, in order:
  1. Installs missing system packages from `packages/apt.txt` (Debian,
     Ubuntu) or `packages/pacman.txt` (Arch), plus the matching `.dev.txt`
     on the devbox, and sets up the locales (see below). This asks for
     your sudo password. On Arch, installing runs a full `pacman -Syu`
     (Arch doesn't support partial upgrades), so the first apply also
     upgrades the system.
  2. Installs mise to `~/.local/bin`.
  3. Links the configs: `~/.bashrc`, git, tmux, vim, nvim, the mise config,
     and the agent configs on the devbox.
  4. Installs the mise tools and vim plugins.

Open a new shell afterwards: `~/.bashrc` activates mise, so the tools are on
`PATH`.

The devbox takes about 4 minutes, and a server about 1, on either distro.

## After the bootstrap

- [ ] `gh auth login`, only if this machine pushes to GitHub. The clone's
  remote is HTTPS, and git uses `gh` as its credential helper.
- [ ] Coding agents (devbox): install the agent CLIs by hand, then
  `agents/bin/sync-agents`. They update themselves, so they aren't in mise.
- [ ] tmux plugins:
  `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`, then
  `prefix + I` inside tmux.
- [ ] Optional: [ble.sh](https://github.com/akinomyoga/ble.sh) for fish-like
  autosuggestions and highlighting in bash. `~/.bashrc` loads it from
  `~/.local/share/blesh` if it's there.
- [ ] Machine-specific shell settings go in `~/.bashrc.local`, which isn't
  tracked.

## Notes

- **CPU architecture.** The configs don't depend on the CPU. Only mise's
  downloads do, and it picks the release asset for `uname -m`. x86_64 is the
  best-supported target. On arm64, a mise registry entry sometimes lacks the
  Linux build even when upstream ships one (it happened with `tlrc`); switch
  that tool to the `github:` backend. Both architectures are tested on
  Debian (see Testing in `design.md`). Arch is tested on x86_64 only:
  official Arch Linux has no arm64 build (Arch Linux ARM is a separate
  project).
- **Clipboard in tmux.** Copying in copy mode (`y`) uses OSC 52, so the
  selection reaches the clipboard of the machine you're typing on, even over
  SSH. The local terminal must allow clipboard writes (Ghostty and kitty do by
  default).
- **Login shell.** It stays bash. Login shells read `~/.bashrc` through
  Debian's `~/.profile` or Arch's `~/.bash_profile`.
- **Locales.** The packages script generates every locale in
  `packages/locales.txt` (`en_US.UTF-8`, `zh_CN.UTF-8`, `ja_JP.UTF-8`) and
  makes the first one the system default (`LANG` in `/etc/default/locale`
  on Debian, `/etc/locale.conf` on Arch), which cron, services and the
  console use. An existing default is kept, unless it's only a fallback
  (`C`, `C.UTF-8`, `POSIX`). Without this, fresh installs lack
  `en_US.UTF-8`, and since macOS terminals and ssh pass
  `LANG`/`LC_ALL=en_US.UTF-8` along, every shell would start with
  `setlocale` warnings. Any UTF-8 locale handles Chinese and Japanese
  text; zh_CN and ja_JP add localized dates, messages and sorting for
  programs run with them, e.g. `LC_TIME=ja_JP.UTF-8 date`.
