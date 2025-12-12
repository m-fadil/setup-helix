#!/usr/bin/env bash
set -euo pipefail

# Konfigurasi URL & path
HX_URL="https://github.com/m-fadil/setup-helix/releases/download/v1.0.0/hx"
HELIX_TARBALL_URL="https://github.com/helix-editor/helix/releases/download/25.07.1/helix-25.07.1-x86_64-linux.tar.xz"
HELIX_TARBALL="helix-25.07.1-x86_64-linux.tar.xz"
HELIX_SHARE_DIR="/usr/local/share/helix"
HELIX_RUNTIME_DIR="$HELIX_SHARE_DIR/runtime"
REPO_URL="https://github.com/m-fadil/setup-helix.git"

# Deteksi apakah perlu sudo atau tidak
if [ "$EUID" -eq 0 ]; then
  # Running as root, tidak perlu sudo
  SUDO=""
else
  # Not root, cek apakah sudo tersedia
  if command -v sudo &> /dev/null; then
    SUDO="sudo"
  else
    echo ""
    echo "[ERROR] Script ini memerlukan akses root untuk instalasi ke /usr/local"
    echo "Opsi:"
    echo "  1. Install sudo: apt-get install sudo (Debian/Ubuntu) atau yum install sudo (RHEL/CentOS)"
    echo "  2. Jalankan sebagai root: su -c './install-helix.sh'"
    echo ""
    exit 1
  fi
fi

# Setup temporary directories dan cleanup trap
TARBALL_TEMP_DIR=$(mktemp -d)
CONFIG_TEMP_DIR=$(mktemp -d)
HX_TEMP_FILE=$(mktemp)

# Cleanup function
cleanup() {
  echo ""
  echo "   -> Membersihkan temporary files..."
  rm -rf "$TARBALL_TEMP_DIR" "$CONFIG_TEMP_DIR" "$HX_TEMP_FILE"
}

# Register cleanup untuk dijalankan saat exit (normal atau error)
trap cleanup EXIT

echo ""
echo "=========================================="
echo "  INSTALASI HELIX EDITOR"
echo "=========================================="
echo ""

# ==================== INSTALASI HX BINARY ====================
echo "[1/5] Mengunduh dan menginstal hx binary..."

echo "   -> Mengunduh hx dari GitHub releases"
curl -L -o "$HX_TEMP_FILE" "$HX_URL"

echo "   -> Mengatur permission executable"
chmod +x "$HX_TEMP_FILE"

echo "   -> Memindahkan ke /usr/local/bin (memerlukan akses root)"
$SUDO mv "$HX_TEMP_FILE" /usr/local/bin/hx

echo "   [OK] hx binary berhasil diinstal"
echo ""

# ==================== INSTALASI HELIX RUNTIME ====================
echo "[2/5] Mengunduh dan menginstal Helix runtime..."

echo "   -> Mengunduh Helix tarball (25.07.1)"
curl -L -o "$TARBALL_TEMP_DIR/$HELIX_TARBALL" "$HELIX_TARBALL_URL"

echo "   -> Mengekstrak tarball"
tar xf "$TARBALL_TEMP_DIR/$HELIX_TARBALL" -C "$TARBALL_TEMP_DIR"

echo "   -> Mencari folder runtime"
if [ -d "$TARBALL_TEMP_DIR/helix-25.07.1-x86_64-linux/runtime" ]; then
  RUNTIME_SRC="$TARBALL_TEMP_DIR/helix-25.07.1-x86_64-linux/runtime"
else
  echo ""
  echo "[ERROR] Folder 'runtime' tidak ditemukan setelah ekstraksi"
  exit 1
fi

echo "   -> Menyiapkan direktori $HELIX_SHARE_DIR"
$SUDO mkdir -p "$HELIX_SHARE_DIR"

echo "   -> Memindahkan runtime ke $HELIX_RUNTIME_DIR"
$SUDO rm -rf "$HELIX_RUNTIME_DIR"
$SUDO mv "$RUNTIME_SRC" "$HELIX_RUNTIME_DIR"

echo "   [OK] Helix runtime berhasil diinstal"
echo ""

# ==================== SETUP KONFIGURASI LOKAL ====================
echo "[3/5] Menyiapkan konfigurasi lokal..."

echo "   -> Membuat direktori ~/.config/helix"
mkdir -p "$HOME/.config/helix"

echo "   -> Membuat symlink runtime ke ~/.config/helix/runtime"
if [ -L "$HOME/.config/helix/runtime" ] || [ -d "$HOME/.config/helix/runtime" ]; then
  rm -rf "$HOME/.config/helix/runtime"
fi
ln -s "$HELIX_RUNTIME_DIR" "$HOME/.config/helix/runtime"

echo "   [OK] Konfigurasi lokal berhasil disiapkan"
echo ""

# ==================== CLONE & APPLY CUSTOM CONFIG ====================
echo "[4/5] Mengambil dan menerapkan konfigurasi custom..."

echo "   -> Cloning repository konfigurasi"
echo "      Dari: $REPO_URL"
git clone "$REPO_URL" "$CONFIG_TEMP_DIR" --quiet

echo "   -> Memeriksa folder 'config' di repository"
if [ -d "$CONFIG_TEMP_DIR/config/helix" ]; then
  echo "   -> Menyalin dan mengganti konfigurasi ke ~/.config/helix"
  cp -rf "$CONFIG_TEMP_DIR/config/helix/"* "$HOME/.config/helix/"
  echo "   [OK] Konfigurasi custom berhasil diterapkan"
else
  echo "   [WARNING] Folder 'config/helix' tidak ditemukan di repository"
fi
echo ""

# ==================== CLEANUP ====================
echo "[5/5] Membersihkan file temporary..."
echo "   [OK] Cleanup akan otomatis dijalankan saat script selesai"
echo ""

# ==================== SELESAI ====================
echo "=========================================="
echo "  INSTALASI BERHASIL!"
echo "=========================================="
echo ""
echo "Lokasi instalasi:"
echo "   * Binary     : /usr/local/bin/hx"
echo "   * Runtime    : $HELIX_RUNTIME_DIR"
echo "   * Config     : ~/.config/helix"
echo ""
echo "Verifikasi instalasi:"
echo "   $ hx --version"
echo ""
echo "Mulai menggunakan Helix:"
echo "   $ hx <nama-file>"
echo ""
