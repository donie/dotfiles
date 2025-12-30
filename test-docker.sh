#!/bin/bash
# Quick Docker testing script for dotfiles installation

set -e

DISTRO="${1:-ubuntu}"

case "$DISTRO" in
    ubuntu|debian)
        echo "Testing on Ubuntu 24.04..."
        docker build -f Dockerfile.debian -t dotfiles-test-debian . && \
        docker run --rm -it dotfiles-test-debian
        ;;
    arch)
        echo "Testing on Arch Linux..."
        docker build -f Dockerfile.arch -t dotfiles-test-arch . && \
        docker run --rm -it dotfiles-test-arch
        ;;
    *)
        echo "Usage: $0 [ubuntu|arch]"
        echo ""
        echo "Examples:"
        echo "  $0 ubuntu    # Test on Ubuntu 24.04"
        echo "  $0 arch      # Test on Arch Linux"
        exit 1
        ;;
esac

echo ""
echo "✅ Test completed successfully!"
