# Proposal: Multi-Config Approach for OS-Specific Dotfiles

## Current Problem

The current implementation uses a single `install.conf.yaml` with OS conditionals (`if` statements) everywhere. This has several issues:

1. **Messy output on macOS**: Linux shell commands still attempt to run and show error messages
2. **Hard to read**: Conditionals scattered throughout make it hard to see what's OS-specific
3. **Not elegant**: Having to use `if` on every single symlink/command is verbose

Example of current approach:
```yaml
~/.bashrc:
  if: '[ "$(uname)" = "Linux" ]'
  path: shell/bash/bashrc
```

## Proposed Solution: Multiple Configuration Files

Dotbot natively supports loading multiple configuration files. We can split into:

```
install.conf.yaml           # Shared/base config (git, vim, nvim, tmux, etc.)
install-darwin.conf.yaml    # macOS-specific (fish, kitty, ghostty, etc.)
install-linux.conf.yaml     # Linux-specific (bash, package installation, etc.)
```

### Modified `install` Script

```bash
#!/usr/bin/env bash

set -e

DOTBOT_DIR="dotbot"
DOTBOT_BIN="bin/dotbot"
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${BASEDIR}"
git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
git submodule update --init --recursive "${DOTBOT_DIR}"

# Determine which configs to load based on OS
CONFIGS=("install.conf.yaml")  # Base config always loaded

if [ "$(uname)" = "Darwin" ]; then
    CONFIGS+=("install-darwin.conf.yaml")
elif [ "$(uname)" = "Linux" ]; then
    CONFIGS+=("install-linux.conf.yaml")
fi

# Run Dotbot with all applicable configs
for config in "${CONFIGS[@]}"; do
    "${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" -c "${config}" "${@}"
done
```

### Example: install.conf.yaml (Base/Shared)

```yaml
- defaults:
    link:
      create: true
      relink: true

- clean: ['~']

# Cross-platform configurations
- link:
    ~/.gallery-dl.conf: dotfiles-private/gallery-dl.conf
    ~/.gitconfig: shell/gitconfig
    ~/.tmux.conf: tmux/tmux.conf
    ~/.vimrc: vim/vimrc
    ~/.vim/autoload/plug.vim: vim/plug.vim
    ~/.config/nvim: nvim/

- create:
    ~/.ssh:
      mode: 0700
    ~/.config:

# Cross-platform shell commands
- shell:
    - [git submodule update --init --recursive, Installing submodules]
    - description: Installing vim-plug
      command: "[ -f ~/.vim/autoload/plug.vim ] || curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    - description: Installing vim plugins
      command: "vim +PlugInstall +qa"
      stdin: true
      stdout: true
```

### Example: install-darwin.conf.yaml (macOS Only)

```yaml
# macOS-specific configurations
- link:
    ~/.config/fish: shell/fish/
    ~/.config/kitty: shell/kitty/
    ~/.config/ghostty/config: shell/ghostty.config
    ~/.zshrc: shell/zsh/zshrc
    ~/.zshenv: shell/zsh/zshenv
    ~/.p10k.zsh: shell/zsh/p10k.zsh
    ~/_runtime/Brewfile: dotfiles-private/brewfile
    ~/.config/mpv:
      path: mpv/
      exclude: [ mpv/watch_later ]
    ~/Library/Application Support/Sublime Text/Packages/User:
      create: true
      path: sublime/Packages/User/

# macOS bin scripts
- link:
    ~/_runtime/bin/code-shell: bin/code-shell
    ~/_runtime/bin/dall: bin/dall
    ~/_runtime/bin/nas: bin/nas
    ~/_runtime/bin/BBDown: bin/BBDown
    ~/_runtime/bin/BBDown.config: bin/BBDown.config
    ~/_runtime/bin/build-mpv: bin/build-mpv

- create:
    ~/_runtime/bin:

# macOS shell commands
- shell:
    - command: chsh -s $(which fish)
      description: Setting fish as default shell
```

### Example: install-linux.conf.yaml (Linux Only)

```yaml
# Linux-specific configurations
- link:
    ~/.bashrc: shell/bash/bashrc
    ~/.bash_profile: shell/bash/bash_profile
    ~/.bash_aliases: shell/bash/bash_aliases
    ~/.tmux-linux.conf: tmux/tmux-linux.conf

# Linux bin scripts (FHS standard location)
- link:
    ~/.local/bin/code-shell: bin/code-shell
    ~/.local/bin/dall: bin/dall
    ~/.local/bin/nas: bin/nas

- create:
    ~/.local/bin:

# Linux shell commands
- shell:
    # Detect distro and run appropriate installer
    - command: |
        if [ -f /etc/os-release ]; then
          . /etc/os-release
          if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ] || echo "$ID_LIKE" | grep -q "debian"; then
            bash shell/linux/install-debian.sh
          elif [ "$ID" = "arch" ] || echo "$ID_LIKE" | grep -q "arch"; then
            bash shell/linux/install-arch.sh
          else
            echo "Unsupported Linux distribution: $ID"
            exit 1
          fi
        fi
      description: Installing Linux packages

    # Set bash as default shell
    - command: |
        case "$SHELL" in
          *bash*) echo "bash is already the default shell" ;;
          *)
            echo "Changing default shell to bash..."
            chsh -s $(which bash)
            ;;
        esac
      description: Setting bash as default shell

    # Source tmux-linux.conf from main tmux.conf
    - command: |
        if ! grep -q "source-file.*tmux-linux.conf" ~/.tmux.conf 2>/dev/null; then
          echo "" >> ~/.tmux.conf
          echo "# Linux-specific configuration" >> ~/.tmux.conf
          echo "if-shell 'uname | grep -q Linux' 'source-file ~/.tmux-linux.conf'" >> ~/.tmux.conf
        fi
      description: Adding Linux tmux config sourcing
```

## Benefits

### ✅ Clean Separation
- macOS configs in one file, Linux in another
- Shared configs in base file
- No conditionals cluttering the YAML

### ✅ No Failed Commands
- Linux commands NEVER run on macOS (different config file)
- macOS commands NEVER run on Linux
- Clean install output on both platforms

### ✅ Better Maintainability
- Easy to see what's OS-specific at a glance
- Adding new OS-specific configs is straightforward
- No need to remember to add `if` conditions

### ✅ Standard Dotbot Pattern
- This is a recommended approach in Dotbot documentation
- Many advanced dotfile repos use this pattern
- Leverages Dotbot's native multi-config support

## Comparison

### Current Approach (Single File with Conditionals)

```yaml
# 200+ lines with conditionals everywhere
~/.bashrc:
  if: '[ "$(uname)" = "Linux" ]'
  path: shell/bash/bashrc

~/.config/fish:
  if: '[ "$(uname)" = "Darwin" ]'
  path: shell/fish/
```

**Issues:**
- ❌ Verbose (every item needs conditional)
- ❌ Linux commands still attempt to run on macOS
- ❌ Hard to maintain
- ❌ Error-prone (easy to forget `if`)

### Multi-Config Approach (3 Files)

**install.conf.yaml** - 40 lines (shared stuff)
**install-darwin.conf.yaml** - 50 lines (macOS only)
**install-linux.conf.yaml** - 60 lines (Linux only)

```yaml
# install-linux.conf.yaml - clean, no conditionals
- link:
    ~/.bashrc: shell/bash/bashrc
    ~/.bash_profile: shell/bash/bash_profile
```

**Benefits:**
- ✅ Clean YAML, no conditionals
- ✅ Commands only run on correct OS
- ✅ Easy to read and maintain
- ✅ Clear separation of concerns

## Migration Steps

1. Create `install-darwin.conf.yaml` with all macOS-specific content
2. Create `install-linux.conf.yaml` with all Linux-specific content
3. Reduce `install.conf.yaml` to only shared content
4. Modify `install` script to load configs based on OS
5. Test on both macOS and Linux

## Recommendation

**Strongly recommend** migrating to the multi-config approach. It's cleaner, more maintainable, and eliminates the issues we're seeing with the current implementation.
