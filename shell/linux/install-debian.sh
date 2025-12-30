#!/bin/bash
# Debian package installation script
# Idempotent - safe to run multiple times

set -e # Exit on error for critical sections

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/packages"

# Color output for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Update package lists (idempotent)
log_info "Updating package lists..."
sudo apt-get update -qq || log_warn "Failed to update package lists"

# Function to install package if not already installed
install_if_missing() {
  local package=$1
  local critical=${2:-false}

  if dpkg -l | grep -q "^ii  $package "; then
    log_info "$package is already installed"
    return 0
  fi

  log_info "Installing $package..."
  if sudo apt-get install -y -qq "$package" 2>/dev/null; then
    log_info "$package installed successfully"
    return 0
  else
    if [ "$critical" = "true" ]; then
      log_error "Failed to install critical package: $package"
    else
      log_warn "Failed to install $package (may not be available)"
    fi
    return 1
  fi
}

# Install packges
log_info "Installing packages..."
while IFS= read -r package; do
  [[ -z "$package" || "$package" =~ ^# ]] && continue
  install_if_missing "$package" true
done <"$PACKAGE_DIR/debian.txt"

log_info "Building nvim for Debian"
bash neovim-debian.sh

# Version managers (special handling)
install_version_managers() {
  # nvm installation (use install script, not package manager)
  if [ ! -d "$HOME/.nvm" ]; then
    log_info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash ||
      log_warn "nvm installation failed"
    bash nvm install --lts --latest-npm || log_warn "failed to install lts with nvm"
  else
    log_info "nvm already installed"
  fi

  # uv installation (Python package manager)
  if ! command -v uv &>/dev/null; then
    log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh || log_warn "uv installation failed"
  else
    log_info "uv already installed"
  fi
}

log_info "Installing version managers..."
install_version_managers

# Tmux Plugin Manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  log_info "Installing Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" ||
    log_warn "TPM installation failed"
else
  log_info "TPM already installed"
fi

log_info "Debian/Ubuntu package installation complete!"
