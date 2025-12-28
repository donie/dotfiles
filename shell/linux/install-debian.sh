#!/bin/bash
# Debian/Ubuntu package installation script
# Idempotent - safe to run multiple times

set -e  # Exit on error for critical sections

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

# Tier 1: Critical packages
log_info "Installing Tier 1 (Critical) packages..."
while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^# ]] && continue
    install_if_missing "$package" true
done < "$PACKAGE_DIR/tier1-critical-debian.txt"

# Tier 2: Development tools (Python/Node only)
log_info "Installing Tier 2 (Development) packages..."
while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^# ]] && continue
    install_if_missing "$package" false
done < "$PACKAGE_DIR/tier2-dev-debian.txt"

# Tier 3: Enhanced tools
log_info "Installing Tier 3 (Enhanced) packages..."
while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^# ]] && continue
    install_if_missing "$package" false
done < "$PACKAGE_DIR/tier3-enhanced-debian.txt"

# Version managers (special handling)
install_version_managers() {
    # pyenv installation
    if ! command -v pyenv &> /dev/null; then
        log_info "Installing pyenv..."
        curl -s https://pyenv.run | bash || log_warn "pyenv installation failed"
    else
        log_info "pyenv already installed"
    fi

    # nvm installation (use install script, not package manager)
    if [ ! -d "$HOME/.nvm" ]; then
        log_info "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
            || log_warn "nvm installation failed"
    else
        log_info "nvm already installed"
    fi

    # uv installation (Python package manager)
    if ! command -v uv &> /dev/null; then
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
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" \
        || log_warn "TPM installation failed"
else
    log_info "TPM already installed"
fi

log_info "Debian/Ubuntu package installation complete!"
