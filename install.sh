#!/usr/bin/env bash
set -euo pipefail

# Konfigurasi URL & path
HX_URL="https://github.com/m-fadil/compose-frappe-development/releases/download/v1.0.0/hx"
HELIX_TARBALL_URL="https://github.com/helix-editor/helix/releases/download/25.07.1/helix-25.07.1-x86_64-linux.tar.xz"
HELIX_TARBALL="helix-25.07.1-x86_64-linux.tar.xz"
HELIX_SHARE_DIR="/usr/local/share/helix"
HELIX_RUNTIME_DIR="$HELIX_SHARE_DIR/runtime"
REPO_URL="https://github.com/m-fadil/compose-frappe-development.git"

echo ""
echo "=========================================="
echo "  INSTALASI HELIX EDITOR"
echo "=========================================="
echo ""

# ==================== INSTALASI HX BINARY ====================
echo "[1/5] Mengunduh dan menginstal hx binary..."
echo "   -> Pindah ke home directory"
cd "$HOME"

echo "   -> Mengunduh hx dari GitHub releases"
curl -L -o hx "$HX_URL"

echo "   -> Mengatur permission executable"
chmod +x hx

echo "   -> Memindahkan ke /usr/local/bin (memerlukan sudo)"
sudo mv hx /usr/local/bin/hx

echo "   [OK] hx binary berhasil diinstal"
echo ""

# ==================== INSTALASI HELIX RUNTIME ====================
echo "[2/5] Mengunduh dan menginstal Helix runtime..."
echo "   -> Mengunduh Helix tarball (25.07.1)"
curl -L -o "$HELIX_TARBALL" "$HELIX_TARBALL_URL"

echo "   -> Mengekstrak tarball"
tar xf "$HELIX_TARBALL"

echo "   -> Mencari folder runtime"
if [ -d "helix-25.07.1-x86_64-linux/runtime" ]; then
  RUNTIME_SRC="helix-25.07.1-x86_64-linux/runtime"
elif [ -d "runtime" ]; then
  RUNTIME_SRC="runtime"
else
  echo ""
  echo "[ERROR] Folder 'runtime' tidak ditemukan setelah ekstraksi"
  exit 1
fi

echo "   -> Menyiapkan direktori $HELIX_SHARE_DIR"
sudo mkdir -p "$HELIX_SHARE_DIR"

echo "   -> Memindahkan runtime ke $HELIX_RUNTIME_DIR"
sudo rm -rf "$HELIX_RUNTIME_DIR"
sudo mv "$RUNTIME_SRC" "$HELIX_RUNTIME_DIR"

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
echo "   -> Membuat temporary directory"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "   -> Cloning repository konfigurasi"
echo "      Dari: $REPO_URL"
git clone "$REPO_URL" "$TEMP_DIR" --quiet

echo "   -> Memeriksa folder 'config' di repository"
if [ -d "$TEMP_DIR/config/helix" ]; then
  echo "   -> Menyalin dan mengganti konfigurasi ke ~/.config/helix"
  cp -rf "$TEMP_DIR/config/helix/"* "$HOME/.config/helix/"
  echo "   [OK] Konfigurasi custom berhasil diterapkan"
else
  echo "   [WARNING] Folder 'config' tidak ditemukan di repository"
fi
echo ""

# ==================== CLEANUP ====================
echo "[5/5] Membersihkan file temporary..."
echo "   -> Menghapus tarball"
rm -f "$HELIX_TARBALL"

echo "   -> Menghapus folder ekstraksi"
if [ -d "helix-25.07.1-x86_64-linux" ]; then
  rm -rf "helix-25.07.1-x86_64-linux"
fi

echo "   [OK] Cleanup selesai"
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
