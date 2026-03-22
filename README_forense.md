# Aislamiento forense: piloto HWE-LOH (GSE12906)

Fecha de corte: 2026-03-20  
Raiz analizada: `F:/Documentos/UNMSM/TESIS`  
Exclusion explicita: `F:/Documentos/UNMSM/TESIS/Vaccinium`

## Objetivo

Documentar y aislar, de forma forense y reproducible, las unidades funcionales del proyecto piloto de replica HWE-LOH para `GSE12906`, minimizando riesgo operativo y evitando copiar/mover archivos masivos.

## Tipo de aislamiento aplicado

- Aislamiento **logico-documental** (no destructivo).
- No se movieron ni duplicaron archivos grandes.
- Se dejaron rutas absolutas, tamanos y rol de cada artefacto para trazabilidad.

## Alcance funcional aislado

1. Filtrado y seleccion de SOFT utiles (contexto de entrada).
2. Parsing de tablas de muestra desde SOFT con:
   - `scripts/parse_soft_v11.awk`
   - `scripts/diagnose_v2.sh`
3. Persistencia de tablas parseadas en `results/parsed_tables/GSE12906/`.
4. Integracion posterior con analisis HWE-LOH (`HWE-LOH_assay/scripts/01_build_snp_matrix.Rmd`).

## Evidencia de piloto GSE12906

- SOFT de entrada: `results/quarantine_maybe/GSE12906_family.soft.gz` (~1090.91 MB).
- Salida parseada: `results/parsed_tables/GSE12906/` (~5459.08 MB).
- Numero de tablas GSM parseadas: 332 archivos `GSM*.tsv`.
- Cabecera de plataforma: `results/parsed_tables/GSE12906/header_GSE12906.tsv` (~719.52 MB).

## Estado operativo de scripts clave (segun validacion ligera)

- `scripts/parse_soft_v11.awk`: operativo.
- `scripts/diagnose_v2.sh`: operativo para lote `quarantine_maybe -> parsed_tables`.
- Coherencia logica confirmada con `scripts/debug_log_v2.txt` (38 GSE procesados, 38 SOFT en cuarentena).

## Archivos de esta carpeta forense

- `Workflow_rescatado_GSE12906.Rmd`: version oficial mejorada del workflow.
- `scripts/`: scripts canonicos de trabajo rescatado.
- `manifiest/MANIFIESTO_UNIDADES_ANALISIS.tsv`: inventario funcional detallado por unidad.
- `manifiest/MAPA_RENOMBRES_COMPATIBILIDAD.tsv`: inconsistencias de nombres y mapeo canonico.
- `manifiest/INVENTARIO_GRANDES_REFERENCIAS.tsv`: rutas de archivos pesados (solo referencia, no copia).
- `manifiest/VALIDACION_LIGERA.md`: pruebas de consistencia de bajo costo.
- `manifiest/PLAN_AISLAMIENTO_LOGICO.md`: decisiones de aislamiento y limites.
