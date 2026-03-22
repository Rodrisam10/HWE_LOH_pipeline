#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run_demo.sh [--help]

Runs help commands for curated pipeline scripts and prints expected paths.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

ROOT_DIR="${TESIS_ROOT:-/f/Documentos/UNMSM/TESIS}"
REPO_DIR="${REPO_DIR_OVERRIDE:-$ROOT_DIR/HWE-LOH_GSE12906_forense}"

echo "Repo: $REPO_DIR"
echo "Data root: $ROOT_DIR"
echo ""

Rscript "$REPO_DIR/scripts/01_discovery/query_gse_from_sqlite.R" --help
echo ""
bash "$REPO_DIR/scripts/01_discovery/scout_master.sh" --help
echo ""
bash "$REPO_DIR/scripts/02_extract/diagnose_v2.sh" --help
echo ""
bash "$REPO_DIR/scripts/02_extract/extract_platform_force.sh" --help
echo ""
Rscript "$REPO_DIR/scripts/03_build/build_snp_matrix.R" --help
echo ""
Rscript "$REPO_DIR/scripts/03_build/compute_genotype_counts.R" --help
echo ""
Rscript "$REPO_DIR/scripts/04_qc/validate_outputs.R" --help
