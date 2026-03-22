#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

help_msg <- paste(
  "Usage: build_snp_matrix.R --parsed-dir PATH --out-matrix PATH [--gse-id GSE12906]",
  "",
  "Options:",
  "  --parsed-dir   Directory containing GSM*.tsv",
  "  --out-matrix   Output matrix CSV",
  "  --gse-id       Label for reporting",
  "  --help         Show this help",
  sep = "\n"
)

get_arg <- function(flag, default = NULL) {
  i <- which(args == flag)
  if (length(i) == 0) return(default)
  if (i == length(args)) stop(sprintf("Missing value for %s", flag))
  args[i + 1]
}

if ("--help" %in% args || length(args) == 0) {
  cat(help_msg, "\n")
  quit(save = "no", status = 0)
}

parsed_dir <- get_arg("--parsed-dir")
out_matrix <- get_arg("--out-matrix")
gse_id <- get_arg("--gse-id", "GSE12906")

if (is.null(parsed_dir) || is.null(out_matrix)) {
  cat(help_msg, "\n")
  quit(save = "no", status = 1)
}

suppressPackageStartupMessages(library(data.table))

if (!dir.exists(parsed_dir)) stop(sprintf("Parsed directory not found: %s", parsed_dir))

files <- sort(list.files(parsed_dir, pattern = "^GSM.*\\.tsv$", full.names = TRUE))
if (length(files) == 0) stop(sprintf("No GSM TSV files found in %s", parsed_dir))

normalize_gt <- function(x) {
  y <- trimws(as.character(x))
  y[y %in% c("", "NA", "No Call", "NC", "--", "null", "NULL")] <- NA_character_
  y
}

dt_list <- vector("list", length(files))

for (i in seq_along(files)) {
  f <- files[i]
  gsm <- sub("\\.tsv$", "", basename(f))
  dt <- fread(f, sep = "\t", header = TRUE, comment.char = "#", showProgress = FALSE)
  if (!"ID_REF" %in% names(dt)) next
  geno_col <- if ("Call_test" %in% names(dt)) "Call_test" else if ("VALUE" %in% names(dt)) "VALUE" else NULL
  if (is.null(geno_col)) next
  tmp <- dt[, .(ID_REF, GT = normalize_gt(get(geno_col)))]
  setnames(tmp, "GT", gsm)
  dt_list[[i]] <- tmp
}

dt_list <- dt_list[!vapply(dt_list, is.null, logical(1))]
if (length(dt_list) == 0) stop("No valid genotype tables found.")

mat <- Reduce(function(x, y) merge(x, y, by = "ID_REF", all = TRUE), dt_list)
dir.create(dirname(out_matrix), recursive = TRUE, showWarnings = FALSE)
fwrite(mat, out_matrix)

cat(sprintf("GSE: %s\n", gse_id))
cat(sprintf("Samples: %d\n", ncol(mat) - 1))
cat(sprintf("SNP rows: %d\n", nrow(mat)))
cat(sprintf("Saved: %s\n", out_matrix))
