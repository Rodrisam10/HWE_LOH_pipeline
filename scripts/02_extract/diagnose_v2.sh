#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: diagnose_v2.sh [options]

Options:
  --source-dir PATH   Directory with *.soft.gz files
  --out-dir PATH      Output parent directory for parsed tables
  --awk-parser PATH   AWK parser file
  --log-file PATH     Log destination
  --help              Show this help

Environment fallback:
  TESIS_ROOT (default: /f/Documentos/UNMSM/TESIS)
EOF
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORENSE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT_DIR="${TESIS_ROOT:-/f/Documentos/UNMSM/TESIS}"
SOURCE_DIR="$ROOT_DIR/results/quarantine_maybe"
BASE_OUT_DIR="$ROOT_DIR/results/parsed_tables"
AWK_SCRIPT="$SCRIPT_DIR/parse_soft_v11.awk"
LOG_FILE="$FORENSE_DIR/manifiest/debug_log_v2_forense.txt"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-dir) SOURCE_DIR="$2"; shift 2 ;;
    --out-dir) BASE_OUT_DIR="$2"; shift 2 ;;
    --awk-parser) AWK_SCRIPT="$2"; shift 2 ;;
    --log-file) LOG_FILE="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

[[ -d "$SOURCE_DIR" ]] || { echo "Missing source dir: $SOURCE_DIR"; exit 1; }
[[ -f "$AWK_SCRIPT" ]] || { echo "Missing AWK parser: $AWK_SCRIPT"; exit 1; }

echo "=== LOG DE EJECUCION V2 ===" > "$LOG_FILE"
echo "Fecha: $(date)" >> "$LOG_FILE"

shopt -s nullglob
files=("$SOURCE_DIR"/*.soft.gz)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No *.soft.gz files in $SOURCE_DIR"
  exit 0
fi

for archive in "${files[@]}"; do
  filename=$(basename "$archive")
  gse_name=$(echo "$filename" | sed -E 's/(_family)?\.soft\.gz//')
  target_dir="$BASE_OUT_DIR/$gse_name"
  rm -rf "$target_dir"
  mkdir -p "$target_dir"

  echo ">> Procesando Archivo: $gse_name" >> "$LOG_FILE"
  zcat -f "$archive" | awk -v out_dir="$target_dir" -v debug_file="$LOG_FILE" -f "$AWK_SCRIPT"

  count=$(ls "$target_dir"/*.tsv 2>/dev/null | wc -l)
  if [[ "$count" -eq 0 ]]; then
    rmdir "$target_dir" 2>/dev/null || true
    echo "  [FAIL] $gse_name sin tablas" >> "$LOG_FILE"
  fi
done

echo "Done. Log: $LOG_FILE"
