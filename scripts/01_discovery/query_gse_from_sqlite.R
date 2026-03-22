#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

help_msg <- paste(
  "Usage: query_gse_from_sqlite.R --sqlite-path PATH --out-csv PATH [--keywords K1,K2,...]",
  "",
  "Options:",
  "  --sqlite-path   Path to GEOmetadb sqlite file",
  "  --out-csv       Output CSV path",
  "  --keywords      Comma-separated keywords for gse title/summary/design",
  "  --help          Show this help",
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

sqlite_path <- get_arg("--sqlite-path")
out_csv <- get_arg("--out-csv")
keywords_raw <- get_arg("--keywords", "colon,colorectal,crc,cancer,tumor,tumour,neoplasm")

if (is.null(sqlite_path) || is.null(out_csv)) {
  cat(help_msg, "\n")
  quit(save = "no", status = 1)
}

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
})

if (!file.exists(sqlite_path)) {
  stop(sprintf("SQLite file not found: %s", sqlite_path))
}

keywords <- unlist(strsplit(keywords_raw, ","))
keywords <- trimws(keywords)
keywords <- keywords[nzchar(keywords)]

make_like_clause <- function(field, vals) {
  parts <- sprintf("%s LIKE '%%%s%%'", field, gsub("'", "''", vals))
  paste(parts, collapse = " OR ")
}

title_clause <- make_like_clause("LOWER(gse.title)", tolower(keywords))
summary_clause <- make_like_clause("LOWER(gse.summary)", tolower(keywords))
design_clause <- make_like_clause("LOWER(gse.overall_design)", tolower(keywords))

query <- sprintf(
  paste(
    "SELECT DISTINCT",
    "  gse.gse,",
    "  gse.title,",
    "  gse.type AS experiment_type,",
    "  gpl.gpl,",
    "  gpl.title AS platform_title,",
    "  gpl.technology,",
    "  gpl.manufacturer",
    "FROM gse",
    "JOIN gse_gpl ON gse.gse = gse_gpl.gse",
    "JOIN gpl ON gse_gpl.gpl = gpl.gpl",
    "WHERE gpl.organism = 'Homo sapiens'",
    "  AND (",
    "    gpl.title LIKE '%%SNP 6.0%%' OR",
    "    gpl.title LIKE '%%Mapping%%250K%%' OR",
    "    gpl.title LIKE '%%Mapping%%50K%%' OR",
    "    gpl.title LIKE '%%Mapping%%10K%%' OR",
    "    gpl.title LIKE '%%CytoScan%%' OR",
    "    gpl.title LIKE '%%OncoScan%%' OR",
    "    gpl.title LIKE '%%HumanHap%%' OR",
    "    gpl.title LIKE '%%Omni%%' OR",
    "    gpl.title LIKE '%%CytoSNP%%' OR",
    "    gpl.title LIKE '%%Infinium%%'",
    "  )",
    "  AND (LOWER(gse.type) LIKE '%%snp%%' OR LOWER(gse.type) LIKE '%%genotyping%%' OR LOWER(gse.type) LIKE '%%genome variation%%')",
    "  AND ((%s) OR (%s) OR (%s))",
    "  AND gpl.technology NOT LIKE '%%sequencing%%'",
    "  AND gpl.technology NOT LIKE '%%RNA%%'",
    "  AND gpl.technology NOT LIKE '%%methylation%%'",
    "  AND gpl.technology NOT LIKE '%%expression%%'",
    sep = "\n"
  ),
  title_clause, summary_clause, design_clause
)

con <- dbConnect(SQLite(), sqlite_path)
on.exit(dbDisconnect(con), add = TRUE)

res <- dbGetQuery(con, query)
dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)
write.csv(res, out_csv, row.names = FALSE)

cat(sprintf("Rows: %d\n", nrow(res)))
cat(sprintf("Saved: %s\n", out_csv))
