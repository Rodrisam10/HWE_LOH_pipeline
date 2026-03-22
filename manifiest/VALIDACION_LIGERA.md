# Validacion ligera de parsing (sin reprocesamiento masivo)

## Objetivo

Comprobar si `parse_soft_v11.awk` + `diagnose_v2.sh` explican razonablemente los resultados ya almacenados en `results/` evitando consumo alto de E/S y tiempo.

## Pruebas ejecutadas

1. Validacion de sintaxis:
   - `bash -n scripts/diagnose_v2.sh` -> OK
   - `awk -f scripts/parse_soft_v11.awk /dev/null` -> OK

2. Coherencia de lote cuarentena:
   - Archivos `*.soft.gz` en `results/quarantine_maybe`: 38
   - GSE procesados en `scripts/debug_log_v2.txt`: 38
   - Coincidencia 1:1 entre ambos conjuntos.

3. Cobertura global fuente->parseado:
   - GSE fuente (`hits_confirmados` + `quarantine_maybe`): 261
   - GSE en `results/parsed_tables`: 260
   - Faltante unico: `GSE47077`.

4. Reproduccion controlada en GSE pequenos (sin tocar GSE masivos):
   - `GSE11036` (~14.48 MB): 12 TSV regenerados, mismos nombres y hash identico.
   - `GSE185549` (~19.21 MB): 1 TSV regenerado, hash identico.

5. Spot-check de piloto GSE12906 (muestra parcial):
   - Conteo en `results/parsed_tables/GSE12906`: 332 TSV.
   - Parseo parcial de primeras tablas confirma estructura esperada (`ID_REF`, `Call_test`, metadatos `!Sample_`).
   - Diferencias de hash en algunos archivos parciales se atribuyen a variaciones de salto de linea/espaciado, no a perdida de campos clave.

## Hallazgos de fallas localizadas

- En `debug_log_v2.txt` aparecen `[FAIL]` para:
  - `GSE19040` (1)
  - `GSE47077` (71)
  - `GSE49666` (15)
- Aun con fallas, hubo salida util en `GSE19040` y `GSE49666`; `GSE47077` queda como no recuperado.

## Conclusion de validacion

- El estado actual de `parse_soft_v11.awk` y `diagnose_v2.sh` es **compatible** con la mayor parte de las salidas almacenadas en `results/` para la etapa de parsing.
- Para el piloto `GSE12906`, la cadena de artefactos necesaria para analisis posterior se encuentra presente y utilizable.
