#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

help_msg <- paste(
  "Usage: compute_genotype_counts.R --matrix-csv PATH --out-counts PATH [--platform-header PATH] [--map-mode auto]",
  "",
  "Options:",
  "  --matrix-csv       Input SNP x sample matrix",
  "  --out-counts       Output CSV with AA/AB/BB and HWE metrics",
  "  --platform-header  Optional platform header TSV for annotation",
  "  --out-annot        Optional output CSV with merged annotation",
  "  --map-mode         auto | text | numeric123",
  "  --help             Show this help",
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

matrix_csv <- get_arg("--matrix-csv")
out_counts <- get_arg("--out-counts")
platform_header <- get_arg("--platform-header")
out_annot <- get_arg("--out-annot")
map_mode <- get_arg("--map-mode", "auto")

if (is.null(matrix_csv) || is.null(out_counts)) {
  cat(help_msg, "\n")
  quit(save = "no", status = 1)
}

suppressPackageStartupMessages(library(data.table))

if (!file.exists(matrix_csv)) stop(sprintf("Matrix file not found: %s", matrix_csv))

dt <- fread(matrix_csv, showProgress = FALSE)
if (!"ID_REF" %in% names(dt)) stop("ID_REF column not found in matrix")

sample_cols <- setdiff(names(dt), "ID_REF")

normalize <- function(x, mode = "auto") {
  y <- trimws(as.character(x))
  y[y %in% c("", "NA", "No Call", "NC", "--", "null", "NULL", "0")] <- NA_character_

  if (mode == "numeric123" || (mode == "auto" && all(na.omit(unique(y)) %in% c("1", "2", "3")))) {
    y[y == "1"] <- "AA"
    y[y == "2"] <- "AB"
    y[y == "3"] <- "BB"
  }

  if (mode == "text" || mode == "auto") {
    y[y %in% c("A/A", "AA")] <- "AA"
    y[y %in% c("A/B", "AB", "BA")] <- "AB"
    y[y %in% c("B/B", "BB")] <- "BB"
  }

  y
}

geno <- as.matrix(dt[, ..sample_cols])
geno <- apply(geno, c(1, 2), normalize, mode = map_mode)

AA <- rowSums(geno == "AA", na.rm = TRUE)
AB <- rowSums(geno == "AB", na.rm = TRUE)
BB <- rowSums(geno == "BB", na.rm = TRUE)
n <- AA + AB + BB

p <- ifelse(n > 0, (2 * AA + AB) / (2 * n), NA_real_)
q <- ifelse(n > 0, 1 - p, NA_real_)
H_exp <- 2 * p * q
H_obs <- ifelse(n > 0, AB / n, NA_real_)

counts <- data.table(ID_REF = dt$ID_REF, AA = AA, AB = AB, BB = BB, n = n, p = p, q = q, H_exp = H_exp, H_obs = H_obs)
dir.create(dirname(out_counts), recursive = TRUE, showWarnings = FALSE)
fwrite(counts, out_counts)

if (!is.null(platform_header) && file.exists(platform_header) && !is.null(out_annot)) {
  hdr <- fread(platform_header, sep = "\t", header = TRUE, showProgress = FALSE)
  if ("ID" %in% names(hdr)) setnames(hdr, "ID", "ID_REF")
  if ("ID_REF" %in% names(hdr)) {
    merged <- merge(counts, hdr, by = "ID_REF", all.x = TRUE)
    dir.create(dirname(out_annot), recursive = TRUE, showWarnings = FALSE)
    fwrite(merged, out_annot)
  }
}

cat(sprintf("Rows: %d\n", nrow(counts)))
cat(sprintf("Saved: %s\n", out_counts))
