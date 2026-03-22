#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scout_master.sh [options]

Options:
  --input-csv PATH      CSV with first column named GSE
  --results-dir PATH    Output root containing hits_confirmados/quarantine_maybe
  --log-file PATH       CSV report path
  --awk-detector PATH   AWK detector script
  --help                Show this help

Environment fallback:
  TESIS_ROOT (default: /f/Documentos/UNMSM/TESIS)
EOF
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${TESIS_ROOT:-/f/Documentos/UNMSM/TESIS}"
INPUT_CSV="$ROOT_DIR/input/GSE_candidates.csv"
RESULTS_DIR="$ROOT_DIR/results"
LOG_FILE="$RESULTS_DIR/cribado_reporte.csv"
AWK_SCRIPT="$SCRIPT_DIR/inspector_gadget.awk"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input-csv) INPUT_CSV="$2"; shift 2 ;;
    --results-dir) RESULTS_DIR="$2"; shift 2 ;;
    --log-file) LOG_FILE="$2"; shift 2 ;;
    --awk-detector) AWK_SCRIPT="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

[[ -f "$INPUT_CSV" ]] || { echo "Missing input CSV: $INPUT_CSV"; exit 1; }
[[ -f "$AWK_SCRIPT" ]] || { echo "Missing AWK detector: $AWK_SCRIPT"; exit 1; }

mkdir -p "$RESULTS_DIR/hits_confirmados" "$RESULTS_DIR/quarantine_maybe"
if [[ ! -f "$LOG_FILE" ]]; then
  echo "GSE,RESULT,ACTION,TIMESTAMP" > "$LOG_FILE"
fi

tail -n +2 "$INPUT_CSV" | while IFS=, read -r GSE _; do
  GSE=$(echo "$GSE" | tr -d '\r" ')
  [[ -z "$GSE" ]] && continue

  STUB="${GSE:0:${#GSE}-3}nnn"
  FAMILY_NAME="${GSE}_family.soft.gz"
  SIMPLE_NAME="${GSE}.soft.gz"
  URL_FAMILY="https://ftp.ncbi.nlm.nih.gov/geo/series/${STUB}/${GSE}/soft/${FAMILY_NAME}"
  URL_SIMPLE="https://ftp.ncbi.nlm.nih.gov/geo/series/${STUB}/${GSE}/soft/${SIMPLE_NAME}"

  FILE_NAME="$FAMILY_NAME"
  cd "$RESULTS_DIR"
  if ! curl -s -L -o "$FILE_NAME" "$URL_FAMILY" --fail; then
    FILE_NAME="$SIMPLE_NAME"
    if ! curl -s -L -o "$FILE_NAME" "$URL_SIMPLE" --fail; then
      echo "$GSE,DOWNLOAD_ERROR,NONE,$(date)" >> "$LOG_FILE"
      continue
    fi
  fi

  if [[ ! -s "$FILE_NAME" ]]; then
    rm -f "$FILE_NAME"
    echo "$GSE,CORRUPT_FILE,DELETED,$(date)" >> "$LOG_FILE"
    continue
  fi

  DETECTION=$(zcat "$FILE_NAME" | awk -f "$AWK_SCRIPT")
  case "$DETECTION" in
    HARD_GENOTYPE|SIGNAL_DATA)
      mv "$FILE_NAME" "hits_confirmados/$FILE_NAME"
      echo "$GSE,$DETECTION,KEPT_CONFIRMED,$(date)" >> "$LOG_FILE"
      ;;
    MAYBE_GENOTYPE)
      mv "$FILE_NAME" "quarantine_maybe/$FILE_NAME"
      echo "$GSE,$DETECTION,KEPT_MAYBE,$(date)" >> "$LOG_FILE"
      ;;
    *)
      rm -f "$FILE_NAME"
      echo "$GSE,NO_GENOTYPE,DELETED,$(date)" >> "$LOG_FILE"
      ;;
  esac
done
