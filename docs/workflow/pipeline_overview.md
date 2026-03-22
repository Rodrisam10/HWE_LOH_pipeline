# Pipeline Overview

Stages:

1. Discover candidate GSE studies from GEO sqlite metadata.
2. Download and classify SOFT files using AWK pattern detection.
3. Parse useful sample tables from SOFT to GSM-level TSV files.
4. Extract platform header table for SNP annotation.
5. Build SNP-by-sample genotype matrix.
6. Compute AA/AB/BB counts and heterozygosity metrics.
7. Validate and report curated outputs.

Primary pilot dataset:

- GSE12906.
