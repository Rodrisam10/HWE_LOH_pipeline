# parse_soft_v12.awk
# Novedades: 
# 1. Extracción de !platform_table (Mapeo de SNPs)
# 2. Modo ONLY_PLATFORM para no tocar las muestras ya procesadas

BEGIN {
    FS = "\t"
    in_sample = 0
    in_table = 0
    in_platform = 0
    
    current_gsm = ""
    current_gse = "GSE_UNKNOWN" # Valor por defecto
    
    header = ""
    block_lines = 0
    table_type = ""
    output_file = ""
    platform_file = ""
    
    buffer = ""
    metadata_buffer = ""
    IGNORECASE = 1
}

# Limpieza global
{ sub(/\r$/, "") }

# Función Logger
function log_msg(msg) {
    if (debug_file != "") print msg >> debug_file
}

# --- 0. DETECCIÓN DE LA SERIE (Para nombrar el header) ---
/^!Series_geo_accession/ {
    # Usualmente formato: !Series_geo_accession = GSE12906
    split($0, parts, "=")
    gsub(/ /, "", parts[2]) # Quitar espacios
    current_gse = parts[2]
    log_msg("  [INFO] Serie detectada: " current_gse)
}

# =======================================================
#               BLOQUE DE PLATAFORMA (NUEVO)
# =======================================================

/^!platform_table_begin/ {
    in_platform = 1
    # Definir nombre del archivo: header_GSE12906.tsv
    if (out_dir == "") out_dir = "."
    platform_file = out_dir "/header_" current_gse ".tsv"
    
    log_msg("  [INFO] Extrayendo plataforma a: " platform_file)
    # Saltamos esta línea para leer el header real en la siguiente iteración
    next 
}

/^!platform_table_end/ {
    if (in_platform) {
        in_platform = 0
        close(platform_file)
        log_msg("  [OK] Tabla de plataforma guardada.")
        
        # SI ESTAMOS EN MODO SOLO PLATAFORMA, TERMINAMOS AQUÍ
        if (only_platform == 1) {
            log_msg("  [INFO] Modo 'only_platform' activado. Saliendo del archivo.")
            nextfile # Pasa al siguiente archivo (o termina si es el único)
        }
    }
}

in_platform {
    # Escribir línea tal cual en el archivo de plataforma
    print $0 >> platform_file
}

# =======================================================
#               BLOQUE DE MUESTRAS (EXISTENTE)
# =======================================================

# Si estamos en modo "Solo Plataforma", ignoramos todo lo de abajo
{ if (only_platform == 1) next }

# --- 1. DETECCIÓN SAMPLE ---
/^\^SAMPLE/ {
    if (in_table && output_file != "") close(output_file)
    in_sample = 1
    in_table = 0
    block_lines = 0
    table_type = ""
    output_file = ""
    buffer = ""
    
    if (match($0, /GSM[0-9]+/)) {
        current_gsm = substr($0, RSTART, RLENGTH)
    } else {
        current_gsm = "UNKNOWN_" NR
    }
    metadata_buffer = "# " $0 "\n"
}

# --- 2. METADATOS ---
in_sample && !in_table {
    if ($0 ~ /^!Sample_/ || $0 ~ /^#/) {
        metadata_buffer = metadata_buffer "# " $0 "\n"
    }
}

# --- 3. INICIO TABLA ---
/^!sample_table_begin/ {
    if (in_sample) {
        in_table = 1
        block_lines = 0
        next 
    }
}

# --- 4. FIN TABLA ---
/^!sample_table_end/ {
    in_table = 0
    if (output_file != "") close(output_file)
}

# --- 5. PROCESAMIENTO MUESTRAS ---
in_table {
    if (block_lines == 0) {
        header = $0
        if (header ~ /allelefreq/ || header ~ /log_r_ratio/ || header ~ /log2ratio/ || header ~ /signal/) {
            table_type = "NUMERIC_DATA"
        }
        else if (header ~ /call/ || header ~ /genotype/ || header ~ /confidence/ || header ~ /cnag/ || header ~ /Call_test/) {
             table_type = "TEXT_GENOTYPE"
        }
        else if (header ~ /ID_REF/ && header ~ /VALUE/) {
             table_type = "CHECK_DATA" 
        }
        else {
            table_type = "UNKNOWN"
            log_msg("  [FAIL] " current_gsm " Header desconocido: <" header ">")
        }
    } 
    else {
        if (table_type == "CHECK_DATA") {
            split($0, fields, "\t")
            val = fields[2]
            if (val ~ /^(AA|AB|BB|NC|No Call|--|A|B|[0-9])$/) { table_type = "TEXT_GENOTYPE" } 
            else if (val ~ /^-?[0-9\.]+$/) { table_type = "NUMERIC_DATA" }
            else { table_type = "UNKNOWN" }
        }

        if (table_type != "UNKNOWN" && table_type != "") {
            if (output_file == "") {
                if (out_dir == "") out_dir = "."
                output_file = out_dir "/" current_gsm ".tsv"
                print metadata_buffer > output_file
                print header >> output_file
            }
            buffer = buffer "\n" $0
            if (block_lines % 5000 == 0) {
                print buffer >> output_file
                buffer = ""
            }
        }
    }
    block_lines++
}

END {
    if (buffer != "" && output_file != "") print buffer >> output_file
}