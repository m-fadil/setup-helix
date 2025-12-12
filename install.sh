#!/usr/bin/env bash
set -euo pipefail

# Configuration: URLs & paths
HX_URL="https://github.com/m-fadil/setup-helix/releases/download/v1.0.0/hx"
HELIX_TARBALL_URL="https://github.com/helix-editor/helix/releases/download/25.07.1/helix-25.07.1-x86_64-linux.tar.xz"
HELIX_TARBALL="helix-25.07.1-x86_64-linux.tar.xz"
HELIX_SHARE_DIR="/usr/local/share/helix"
HELIX_RUNTIME_DIR="$HELIX_SHARE_DIR/runtime"
REPO_URL="https://github.com/m-fadil/setup-helix.git"

# Check required dependencies
echo "Checking dependencies..."
MISSING_DEPS=()

if ! command -v curl &> /dev/null; then
  MISSING_DEPS+=("curl")
fi

if ! command -v git &> /dev/null; then
  MISSING_DEPS+=("git")
fi

if ! command -v xz &> /dev/null; then
  MISSING_DEPS+=("xz-utils or xz")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
  echo ""
  echo "[ERROR] The following dependencies are not installed:"
  for dep in "${MISSING_DEPS[@]}"; do
    echo "  - $dep"
  done
  echo ""
  echo "How to install dependencies:"
  echo ""
  echo "Debian/Ubuntu:"
  echo "  apt-get update && apt-get install -y curl git xz-utils"
  echo ""
  echo "RHEL/CentOS/Fedora:"
  echo "  yum install -y curl git xz"
  echo ""
  echo "Arch Linux:"
  echo "  pacman -S curl git xz"
  echo ""
  echo "Alpine Linux:"
  echo "  apk add curl git xz"
  echo ""
  exit 1
fi

# Detect if sudo is needed
if [ "$EUID" -eq 0 ]; then
  # Running as root, no sudo needed
  SUDO=""
else
  # Not root, check if sudo is available
  if command -v sudo &> /dev/null; then
    SUDO="sudo"
  else
    echo ""
    echo "[ERROR] This script requires root access to install to /usr/local"
    echo "Options:"
    echo "  1. Install sudo: apt-get install sudo (Debian/Ubuntu) or yum install sudo (RHEL/CentOS)"
    echo "  2. Run as root: su -c './install-helix.sh'"
    echo ""
    exit 1
  fi
fi

# Setup temporary directories and cleanup trap
TARBALL_TEMP_DIR=$(mktemp -d)
CONFIG_TEMP_DIR=$(mktemp -d)
HX_TEMP_FILE=$(mktemp)

# Cleanup function
cleanup() {
  echo ""
  echo "   -> Cleaning up temporary files..."
  rm -rf "$TARBALL_TEMP_DIR" "$CONFIG_TEMP_DIR" "$HX_TEMP_FILE"
}

# Register cleanup to run on exit (normal or error)
trap cleanup EXIT

echo ""
echo "=========================================="
echo "  HELIX EDITOR INSTALLATION"
echo "=========================================="
echo ""

# ==================== INSTALL HX BINARY ====================
echo "[1/5] Downloading and installing hx binary..."

echo "   -> Downloading hx from GitHub releases"
curl -L -o "$HX_TEMP_FILE" "$HX_URL"

echo "   -> Setting executable permission"
chmod +x "$HX_TEMP_FILE"

echo "   -> Moving to /usr/local/bin (requires root access)"
$SUDO mv "$HX_TEMP_FILE" /usr/local/bin/hx

echo "   [OK] hx binary successfully installed"
echo ""

# ==================== INSTALL HELIX RUNTIME ====================
echo "[2/5] Downloading and installing Helix runtime..."

echo "   -> Downloading Helix tarball (25.07.1)"
curl -L -o "$TARBALL_TEMP_DIR/$HELIX_TARBALL" "$HELIX_TARBALL_URL"

echo "   -> Extracting tarball"
tar xf "$TARBALL_TEMP_DIR/$HELIX_TARBALL" -C "$TARBALL_TEMP_DIR"

echo "   -> Looking for runtime folder"
if [ -d "$TARBALL_TEMP_DIR/helix-25.07.1-x86_64-linux/runtime" ]; then
  RUNTIME_SRC="$TARBALL_TEMP_DIR/helix-25.07.1-x86_64-linux/runtime"
else
  echo ""
  echo "[ERROR] 'runtime' folder not found after extraction"
  exit 1
fi

echo "   -> Preparing directory $HELIX_SHARE_DIR"
$SUDO mkdir -p "$HELIX_SHARE_DIR"

echo "   -> Moving runtime to $HELIX_RUNTIME_DIR"
$SUDO rm -rf "$HELIX_RUNTIME_DIR"
$SUDO mv "$RUNTIME_SRC" "$HELIX_RUNTIME_DIR"

echo "   [OK] Helix runtime successfully installed"
echo ""

# ==================== SETUP LOCAL CONFIGURATION ====================
echo "[3/5] Setting up local configuration..."

echo "   -> Creating directory ~/.config/helix"
mkdir -p "$HOME/.config/helix"

echo "   -> Creating symlink runtime to ~/.config/helix/runtime"
if [ -L "$HOME/.config/helix/runtime" ] || [ -d "$HOME/.config/helix/runtime" ]; then
  rm -rf "$HOME/.config/helix/runtime"
fi
ln -s "$HELIX_RUNTIME_DIR" "$HOME/.config/helix/runtime"

echo "   [OK] Local configuration successfully set up"
echo ""

# ==================== CLONE & APPLY CUSTOM CONFIG ====================
echo "[4/5] Fetching and applying custom configuration..."

echo "   -> Cloning configuration repository"
echo "      From: $REPO_URL"
git clone "$REPO_URL" "$CONFIG_TEMP_DIR" --quiet

echo "   -> Checking for 'config' folder in repository"
if [ -d "$CONFIG_TEMP_DIR/config/helix" ]; then
  echo "   -> Copying and replacing configuration to ~/.config/helix"
  cp -rf "$CONFIG_TEMP_DIR/config/helix/"* "$HOME/.config/helix/"
  echo "   [OK] Custom configuration successfully applied"
else
  echo "   [WARNING] 'config/helix' folder not found in repository"
fi
echo ""

# ==================== CLEANUP ====================
echo "[5/5] Cleaning up temporary files..."
echo "   [OK] Cleanup will run automatically when script finishes"
echo ""

# ==================== DONE ====================
echo "=========================================="
echo "  INSTALLATION SUCCESSFUL!"
echo "=========================================="
echo ""
echo "Installation locations:"
echo "   * Binary     : /usr/local/bin/hx"
echo "   * Runtime    : $HELIX_RUNTIME_DIR"
echo "   * Config     : ~/.config/helix"
echo ""
echo "Verify installation:"
echo "   $ hx --version"
echo ""
echo "Start using Helix:"
echo "   $ hx <filename>"
echo ""
