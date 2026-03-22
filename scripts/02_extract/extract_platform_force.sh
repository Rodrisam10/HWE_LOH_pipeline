#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: extract_platform_force.sh [options]

Options:
  --soft-file PATH   Input SOFT(.gz) file
  --out-file PATH    Output TSV with platform table
  --help             Show this help

Environment fallback:
  TESIS_ROOT (default: /f/Documentos/UNMSM/TESIS)
EOF
}

ROOT_DIR="${TESIS_ROOT:-/f/Documentos/UNMSM/TESIS}"
SOURCE_FILE="$ROOT_DIR/results/quarantine_maybe/GSE12906_family.soft.gz"
OUT_FILE="$ROOT_DIR/results/parsed_tables/GSE12906/header_GSE12906.tsv"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --soft-file) SOURCE_FILE="$2"; shift 2 ;;
    --out-file) OUT_FILE="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

out_dir=$(dirname "$OUT_FILE")
tmp_file="$out_dir/tmp_platform_extract.tsv"

[[ -f "$SOURCE_FILE" ]] || { echo "Missing SOFT file: $SOURCE_FILE"; exit 1; }
mkdir -p "$out_dir"

zcat -f "$SOURCE_FILE" | sed -n '/^!platform_table_begin/,/^!platform_table_end/p' > "$tmp_file"
grep -v "!platform_table" "$tmp_file" > "$OUT_FILE"
rm -f "$tmp_file"

if [[ ! -s "$OUT_FILE" ]]; then
  echo "Output file is empty: $OUT_FILE"
  exit 1
fi

echo "Platform header extracted to: $OUT_FILE"
