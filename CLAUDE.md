# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that uses **Dotbot** for declarative configuration management across macOS. The repository manages shell, editor, terminal, and application configurations with automated installation and symlinking.

## Common Commands

### Installation & Setup
```bash
./install                    # Install/update all dotfiles using Dotbot
git submodule update --init --recursive  # Update submodules (dotbot, dotfiles-private)
```

### Configuration Management
The repository uses `install.conf.yaml` for all symlink definitions and installation logic. To modify what gets installed:
1. Edit `install.conf.yaml` to add/remove symlinks
2. Run `./install` to apply changes

### Shell Development
```bash
# Fish shell (primary)
fish_config                  # Open web-based Fish configuration
fisher update                # Update Fish plugins (fisher, fzf.fish, nvm.fish)

# Zsh (alternative)
# Uses z4h framework - configuration in shell/zsh/zshrc
```

### Editor Configuration

**Neovim (LazyVim):**
```bash
nvim                         # Will auto-install Lazy plugin manager on first run
# Inside nvim:
:Lazy                        # Open plugin manager
:Lazy sync                   # Update all plugins
:checkhealth                 # Verify configuration
```

**Vim (legacy):**
```bash
vim +PlugInstall +qa         # Install vim-plug plugins
vim +PlugUpdate +qa          # Update vim-plug plugins
```

### Custom Utilities

Custom scripts are located in `bin/` and symlinked to `~/_runtime/bin/`:
- `build-mpv` - Comprehensive MPV build script for macOS
- `code-shell` - Create/attach tmux sessions for VS Code projects
- `dall` - Batch file downloader using wget
- `nas` - Network storage utility
- `BBDown` - Bilibili video downloader

## Architecture

### Directory Structure

```
dotfiles/
├── install.conf.yaml        # Dotbot configuration (declarative install manifest)
├── install                  # Installation script (runs Dotbot)
├── shell/                   # Shell configurations
│   ├── fish/               # Fish shell (primary) - config.fish, fish_plugins
│   ├── zsh/                # Zsh with z4h framework - zshrc, zshenv, p10k.zsh
│   ├── kitty/              # Kitty terminal config (primary terminal)
│   ├── ghostty.config      # Ghostty terminal alternative
│   ├── wezterm.lua         # WezTerm terminal alternative
│   └── gitconfig           # Git configuration with delta diff viewer
├── nvim/                    # Neovim with LazyVim starter
│   ├── init.lua            # Entry point
│   ├── lua/config/         # Core configuration (lazy.lua, keymaps.lua, options.lua, autocmds.lua)
│   └── lua/plugins/        # Custom plugin specifications
├── vim/                     # Traditional Vim with vim-plug
│   ├── vimrc               # Main configuration
│   └── plug.vim            # vim-plug plugin manager
├── tmux/                    # Tmux configuration
│   ├── tmux.conf           # Main config (Ctrl+A prefix, vim bindings)
│   └── shared.sh           # Helper functions
├── mpv/                     # MPV media player config with scripts and fonts
├── bin/                     # Custom executable scripts
├── sublime/                 # Sublime Text config (macOS only)
├── dotbot/                  # Dotbot framework (git submodule)
└── dotfiles-private/        # Private configs (git submodule)
    ├── brewfile            # Homebrew package manifest
    └── gallery-dl.conf     # Private downloader settings
```

### Key Architectural Patterns

**Dotbot Declarative Configuration:**
- All symlinks defined in `install.conf.yaml`
- Automatic parent directory creation
- Conditional linking based on OS (e.g., `if: '[ \`uname\` = Darwin ]'`)
- Excludes patterns for runtime data (e.g., `mpv/watch_later`)
- Shell commands run after linking (submodule init, shell change, plugin installation)

**Configuration vs Runtime Separation:**
- Configuration: This repository (version controlled)
- Runtime data: `~/_runtime/` directory (not in repo)
- Custom scripts symlinked to `~/_runtime/bin/`
- Homebrew packages manifest at `~/_runtime/Brewfile`

**Multi-Shell Support:**
- Fish is primary shell (installed by `./install` via `chsh -s $(which fish)`)
- Zsh available as alternative with z4h framework
- Shared tools: FZF, rbenv, nvm/nvm.fish

**Editor Ecosystem:**
- Neovim uses LazyVim (modern, lazy-loading plugin system)
- Vim uses vim-plug (traditional, installed automatically)
- Both configured to use system clipboard
- Default `vi`/`vim` commands aliased to `nvim` in Fish

**Terminal Configuration:**
- Kitty is primary (GPU-accelerated, configured with BerkeleyMono Nerd Font)
- Catppuccin Mocha theme with dark mode
- Ghostty and WezTerm as alternatives
- All use powerline-compatible fonts

### Submodule Management

Two git submodules:
1. `dotbot/` - The Dotbot framework (public)
2. `dotfiles-private/` - Private configurations and proprietary fonts (private repo)

Always update both when pulling: `git submodule update --init --recursive`

### Technology Stack

- **Configuration Manager:** Dotbot (declarative YAML)
- **Shells:** Fish (primary), Zsh with z4h
- **Terminals:** Kitty (primary), Ghostty, WezTerm
- **Editors:** Neovim (LazyVim), Vim (vim-plug), Sublime Text
- **Multiplexer:** Tmux
- **Package Manager:** Homebrew (brewfile in dotfiles-private)
- **Version Managers:** rbenv (Ruby), nvm.fish (Node), uv (Python)
- **Tools:** FZF, ripgrep, delta, direnv

## Modification Guidelines

### Adding New Configurations

1. Add the configuration file(s) to the appropriate directory (e.g., `shell/`, `nvim/`)
2. Edit `install.conf.yaml` to add the symlink under the `link:` section
3. Run `./install` to apply

### Adding Custom Scripts

1. Add executable script to `bin/`
2. Add symlink in `install.conf.yaml`: `~/_runtime/bin/scriptname: bin/scriptname`
3. Run `./install` to symlink

### Plugin Management

**Fish:** Edit `shell/fish/fish_plugins` and run `fisher update`
**Neovim:** Add plugin spec to `nvim/lua/plugins/`, restart nvim (auto-installs)
**Vim:** Add plugin to `vim/vimrc`, run `vim +PlugInstall +qa`

### Private Configurations

Private/sensitive configs go in `dotfiles-private/` submodule (separate private repository). Reference them in `install.conf.yaml` with paths like `dotfiles-private/filename`.

## Linux Server Setup

This repository now supports Linux servers (Debian/Ubuntu and Arch Linux) in addition to macOS desktop environments.

### Supported Linux Distributions

- **Debian** 11+ (Bullseye and later)
- **Ubuntu** 20.04+ (Focal and later)
- **Arch Linux** (rolling release)

### Prerequisites (Linux)

1. Git installed: `sudo apt install git` (Debian/Ubuntu) or `sudo pacman -S git` (Arch)
2. Sudo access for package installation
3. Internet connection for downloading packages and tools

### Installation on Linux

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install
```

The installer will automatically:
1. Detect your Linux distribution
2. Install appropriate packages for your distro (apt or pacman)
3. Set up bash configuration with aliases and functions
4. Install version managers (pyenv, nvm, uv)
5. Configure vim, tmux, and git
6. Set bash as your default shell

### What Gets Installed on Linux

**Tier 1 (Critical CLI Tools)**:
- git, tmux, neovim, vim, htop
- ripgrep, fd, fzf, bat
- curl, wget, coreutils, less
- findutils, sed, tar, rsync, gnupg

**Tier 2 (Development Tools - Python/Node)**:
- python3, pip, pyenv (version manager)
- nodejs, npm, nvm (version manager)
- make, cmake, gh (GitHub CLI)
- build-essential (Debian) / base-devel (Arch)

**Tier 3 (Enhanced Tools)**:
- ncdu (disk usage analyzer)
- httpie (HTTP client)

### Post-Installation (Linux)

1. **Log out and log back in** for shell change to take effect
2. **Install Python version**:
   ```bash
   pyenv install 3.11.0
   pyenv global 3.11.0
   ```
3. **Install Node version**:
   ```bash
   nvm install --lts
   nvm use --lts
   ```
4. **Install tmux plugins**: Launch tmux, press `Ctrl+a` then `I` (capital i)

### Configuration Files (Linux)

- `~/.bashrc` - Main bash configuration with git prompt and tool integrations
- `~/.bash_aliases` - Aliases (cat→bat, vi→nvim, ll, git shortcuts, etc.)
- `~/.bash_profile` - Login shell config
- `~/.tmux.conf` - Tmux config (automatically sources Linux-specific overrides)
- `~/.tmux-linux.conf` - Linux-specific tmux settings (clipboard handling)
- `~/.vimrc` / `~/.config/nvim` - Vim/Neovim config (clipboard already OS-aware)
- `~/.gitconfig` - Git configuration with delta diff viewer

### Common Commands (Linux)

```bash
# Reload bash configuration
source ~/.bashrc
# or
reload

# Package management
update              # apt update && apt upgrade (Debian) or pacman -Syu (Arch)
install <package>   # Install package
search <package>    # Search for package

# Navigation
ll                  # List all files with details
..                  # cd to parent directory
...                 # cd two levels up
....                # cd three levels up

# Tool replacements (aliased)
cat file.txt        # Uses bat (syntax highlighting)
find pattern        # Uses fd (faster alternative)
top                 # Uses htop (better interface)
vi / vim            # Uses nvim (Neovim)

# Git shortcuts
g                   # git
gs                  # git status
ga                  # git add
gc                  # git commit
gp                  # git push
gl                  # git pull
gd                  # git diff
gco                 # git checkout
gb                  # git branch
glog                # git log --oneline --graph --decorate

# FZF shortcuts
Ctrl+R              # Search command history
Ctrl+T              # Search files

# Proxy toggle
sgproxy on          # Enable proxy
sgproxy off         # Disable proxy
```

### Troubleshooting (Linux)

**Issue**: Package installation fails for some packages
**Solution**: Some tier 3 packages may not be available in your distro's repos. This is expected and won't block installation. The installer will warn but continue.

**Issue**: Clipboard doesn't work in tmux/vim
**Solution**: Install xclip (`sudo apt install xclip` or `sudo pacman -S xclip`) or xsel. On headless servers without X11, tmux clipboard works within tmux sessions only (yank with `y` in copy mode, paste with `Ctrl+a` then `]`).

**Issue**: pyenv/nvm commands not found after install
**Solution**: Log out and log back in to reload shell, or run `source ~/.bashrc` to reload configuration in current session.

**Issue**: bash is not the default shell
**Solution**: Run `chsh -s $(which bash)` manually and log out/log in.

**Issue**: vim clipboard doesn't work
**Solution**: Check if neovim has clipboard support: `nvim --version | grep clipboard` (should show `+clipboard`). Install xclip or xsel if needed.

**Issue**: Can't run ./install multiple times
**Solution**: The installation is designed to be idempotent. If you see errors, check that you have sudo access and that git submodules are initialized (`git submodule update --init --recursive`).

### Customization (Linux)

**Machine-specific settings**: Create `~/.bashrc.local` for local customizations (not tracked in git).

**Example** `~/.bashrc.local`:
```bash
# Machine-specific settings
export CUSTOM_VAR=value
alias custom='echo custom'

# Override proxy settings for this machine
sgproxy() {
    case "$1" in
        on)
            export https_proxy=http://192.168.1.100:8888
            ;;
        *)
            sgproxy "$@"
            ;;
    esac
}
```

### Key Differences: macOS vs Linux

| Feature | macOS | Linux Servers |
|---------|-------|---------------|
| **Shell** | Fish/Zsh | Bash |
| **Package Manager** | Homebrew | apt/pacman |
| **Development Tools** | Full suite (Go, Rust, Ruby, Python, Node) | Python & Node only |
| **GUI Applications** | Extensive (180+ apps) | None (server use) |
| **Terminal Emulator** | Kitty/Ghostty configured | N/A (SSH access) |
| **Media Player** | MPV with custom config | N/A |

### Architecture Notes (Linux)

**OS Detection**: Install.conf.yaml uses `if: '[[ \`uname\` = Linux ]]'` for Linux-specific configurations and `if: '[ \`uname\` = Darwin ]'` for macOS-specific configurations.

**Package Installation**: Distro detection via `/etc/os-release`, then runs `shell/linux/install-debian.sh` or `shell/linux/install-arch.sh` accordingly.

**Tmux Configuration**: Main `tmux.conf` works on both OSes. On Linux, `~/.tmux-linux.conf` is automatically sourced to override macOS-specific settings (clipboard integration, status line).

**Vim Clipboard**: Already OS-aware in vimrc (uses `clipboard=unnamed` on macOS, `clipboard=unnamedplus` on Linux).

**Portable Scripts**: These bin scripts work on both OSes:
- `bin/nas` - rsync-based NAS sync
- `bin/code-shell` - tmux session manager for VS Code
- `bin/dall` - wget-based batch downloader

**macOS-Only Scripts**: These are NOT symlinked on Linux:
- `bin/build-mpv` - macOS-specific MPV builder
- `bin/BBDown` - Architecture-specific binary
