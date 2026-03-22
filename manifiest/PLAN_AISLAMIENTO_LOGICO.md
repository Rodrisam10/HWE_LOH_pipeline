# Plan de aislamiento logico (sin mover masivos)

## Principios aplicados

- No modificar evidencia primaria en `results/`, `rawData/` o archivos `.sqlite`.
- No duplicar archivos grandes; registrar ubicacion, tamano y rol.
- Priorizar trazabilidad de etapa piloto (`GSE12906`) por encima de cobertura multi-GSE.
- Mantener cadena de dependencias desde `Documentación_GSE_sniffer.Rmd` hacia scripts de parsing y salidas.

## Que SI se aísla en esta carpeta

- Documentacion forense estructurada (manifiestos, mapas, validaciones).
- Tabla de correspondencia de nombres inconsistentes.
- Catalogo de artefactos y estado operativo.

## Que NO se copia

- `GEOmetadb.sqlite` (muy grande).
- SOFT comprimidos grandes (ej. `GSE12906_family.soft.gz`).
- Directorios masivos de tablas parseadas (`results/parsed_tables/GSE12906`).
- Matrices CSV grandes y headers masivos.

## Criterio de reproducibilidad

La reproducibilidad queda definida por:

1. Rutas absolutas de entrada/salida.
2. Script exacto de parsing (`parse_soft_v11.awk`) y controlador (`diagnose_v2.sh`).
3. Evidencia de ejecucion (`debug_log_v2.txt`, conteos de salida, cobertura de GSE).

## Limites conocidos

- Existen scripts historicos con nombres inconsistentes o referencias a archivos no presentes.
- El flujo CEL/crlmm se considera fuera de alcance de este aislamiento piloto.
- La metodologia estadistica de `01_build_snp_matrix.Rmd` no replica completamente el paper original (test exacto/MLE).
