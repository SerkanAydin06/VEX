#!/usr/bin/env bash
# VEX hızlı doğrulama (bash). validate_local.ps1'in Linux/Git Bash karşılığı;
# çıktıyı kısa tutar: yalnız başarısız denetimlerin son satırlarını gösterir.
#
#   tools/validate.sh            -> 107+ Python denetimi (paralel)
#   tools/validate.sh --godot    -> + Godot import, integrity_test, *_runtime_test
#
# Godot yolu: $GODOT, yoksa PATH'teki `godot`.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PYTHON="${PYTHON:-python3}"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON=python
JOBS="${VEX_VALIDATE_JOBS:-8}"
LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT
export PYTHONDONTWRITEBYTECODE=1

failed=0
audits=(tests/*_audit.py)
printf '%s\n' "${audits[@]}" | xargs -P "$JOBS" -I{} sh -c \
  "'$PYTHON' '{}' > '$LOG_DIR/'\$(basename '{}').log 2>&1 || echo '{}' >> '$LOG_DIR/failed'"
if [ -s "$LOG_DIR/failed" ]; then
  while read -r audit; do
    failed=$((failed + 1))
    echo "FAIL $audit"
    tail -n 4 "$LOG_DIR/$(basename "$audit").log" | sed 's/^/    /'
  done < <(sort "$LOG_DIR/failed")
fi
echo "Python audits: $(( ${#audits[@]} - failed )) / ${#audits[@]} passed"

if [ "${1:-}" = "--godot" ]; then
  GODOT_BIN="${GODOT:-godot}"
  if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
    echo "Godot bulunamadı (GODOT=$GODOT_BIN)."
    exit 2
  fi
  run_godot() {
    local label="$1"; shift
    if "$GODOT_BIN" --headless --path "$ROOT" "$@" > "$LOG_DIR/godot.log" 2>&1 \
      && ! grep -q 'SCRIPT ERROR\|Parse Error' "$LOG_DIR/godot.log"; then
      return 0
    fi
    failed=$((failed + 1))
    echo "FAIL $label"
    sed 's/\x1b\[[0-9;]*m//g' "$LOG_DIR/godot.log" | grep -E 'ERROR|SCRIPT|Parse' | head -n 8 | sed 's/^/    /'
  }
  run_godot "godot import" --editor --quit
  scenes=(tests/integrity_test.tscn tests/*_runtime_test.tscn)
  for scene in "${scenes[@]}"; do
    run_godot "$scene" "$scene"
  done
  echo "Godot: import + ${#scenes[@]} test scene(s) checked"
fi

if [ "$failed" -eq 0 ]; then
  echo "VEX VALIDATION PASSED"
else
  echo "VEX VALIDATION FAILED ($failed)"
  exit 1
fi
