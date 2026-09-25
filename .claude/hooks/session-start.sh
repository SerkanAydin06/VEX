#!/bin/bash
# Claude Code on the web: Godot 4.7.1'i kur ve projeyi bir kez import et, böylece
# tools/validate.sh --godot ve headless runtime testleri oturum başında hazır olur.
# Yerel makinede hiçbir şey yapmaz. İdempotenttir; kurulum varsa atlanır.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

GODOT_VERSION="4.7.1"
GODOT_DIR="$HOME/.local/share/vex-godot/$GODOT_VERSION"
GODOT_BIN="$GODOT_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

if [ ! -x "$GODOT_BIN" ]; then
  mkdir -p "$GODOT_DIR"
  archive="$GODOT_DIR/godot.zip"
  curl -fsSL --retry 4 --retry-delay 2 -o "$archive" \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
  python3 -c "import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$archive" "$GODOT_DIR"
  rm -f "$archive"
  chmod +x "$GODOT_BIN"
fi

# Push öncesi doğrulama hook'unu etkinleştir (tools/git-hooks/pre-push).
git -C "$PROJECT_DIR" config core.hooksPath tools/git-hooks || true

mkdir -p "$HOME/.local/bin"
ln -sf "$GODOT_BIN" "$HOME/.local/bin/godot"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export GODOT=\"$GODOT_BIN\"" >> "$CLAUDE_ENV_FILE"
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# İlk import .godot önbelleğini ve CSV çevirilerini üretir; önbellek varsa hızlıdır.
"$GODOT_BIN" --headless --editor --path "$PROJECT_DIR" --quit > /dev/null 2>&1 || \
  echo "VEX session-start: Godot import uyarı verdi; 'tools/validate.sh --godot' ile kontrol et." >&2
