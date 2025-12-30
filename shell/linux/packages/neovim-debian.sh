#!/usr/bin/env bash
set -euo pipefail

NEOVIM_REPO="https://github.com/neovim/neovim.git"
NEOVIM_DIR="neovim"

log() {
  # Simple logger with levels
  # Usage: log INFO "message"
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*" >&2
}

detect_arch() {
  # Detect architecture and map to Neovim deb name
  local arch
  arch="$(uname -m)"

  case "$arch" in
  x86_64 | amd64)
    echo "x86_64"
    ;;
  aarch64 | arm64)
    echo "arm64"
    ;;
  *)
    log "ERROR" "Unsupported architecture: $arch"
    log "ERROR" "This script currently supports x86_64 and arm64 only."
    exit 1
    ;;
  esac
}

ARCH="$(detect_arch)"
DEB_NAME="nvim-linux-${ARCH}.deb"

log "INFO" "Detected architecture: ${ARCH}"

log "INFO" "Installing build dependencies (may require sudo)..."
sudo apt-get update -y
sudo apt-get install -y \
  ninja-build \
  gettext \
  cmake \
  curl \
  build-essential \
  git \
  cpack || {
  log "WARN" "Some distributions ship cpack via 'cmake' only; ignoring cpack install failure."
}

if [ -d "${NEOVIM_DIR}/.git" ]; then
  log "INFO" "Neovim directory exists, updating repository..."
  git -C "${NEOVIM_DIR}" fetch --all --prune
  git -C "${NEOVIM_DIR}" pull --ff-only
else
  log "INFO" "Cloning Neovim repository..."
  git clone "$NEOVIM_REPO" "$NEOVIM_DIR"
fi

cd "$NEOVIM_DIR"

log "INFO" "Building Neovim (RelWithDebInfo)..."
make CMAKE_BUILD_TYPE=RelWithDebInfo

log "INFO" "Creating .deb package with cpack..."
cd build

cpack -G DEB

if [ ! -f "$DEB_NAME" ]; then
  log "ERROR" "Expected package ${DEB_NAME} not found in build directory."
  log "ERROR" "Available .deb files:"
  ls -1 *.deb 2>/dev/null || log "ERROR" "No .deb files found."
  exit 1
fi

log "INFO" "Installing Neovim from ${DEB_NAME} (may require sudo)..."
sudo dpkg -i "$DEB_NAME" || {
  log "WARN" "dpkg reported issues, attempting to fix dependencies..."
  sudo apt-get install -f -y
}

log "INFO" "Neovim installation completed successfully."
log "INFO" "Run 'nvim --version' to verify."
