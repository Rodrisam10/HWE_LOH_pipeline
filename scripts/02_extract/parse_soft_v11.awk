# parse_soft_v11.awk
# - Usa 'next' para saltar la etiqueta !sample_table_begin
# - Loguea errores en archivo externo

BEGIN {
    FS = "\t"
    in_sample = 0
    in_table = 0
    current_gsm = ""
    header = ""
    block_lines = 0
    table_type = ""
    output_file = ""
    buffer = ""
    metadata_buffer = ""
    IGNORECASE = 1
}

# Limpieza global de retorno de carro (Windows fix)
{ sub(/\r$/, "") }

# Función Logger auxiliar
function log_msg(msg) {
    if (debug_file != "") print msg >> debug_file
}

# --- 1. DETECCIÓN SAMPLE ---
/^\^SAMPLE/ {
    if (in_table && output_file != "") close(output_file)
    in_sample = 1
    in_table = 0
    block_lines = 0
    table_type = ""
    output_file = ""
    buffer = ""
    
    # Detección GSM robusta (ignora espacios/tabs)
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

# --- 3. INICIO TABLA (CORREGIDO) ---
/^!sample_table_begin/ {
    if (in_sample) {
        in_table = 1
        block_lines = 0
        # CRÍTICO: 'next' fuerza a saltar esta línea y leer el HEADER real en la siguiente
        next 
    }
}

# --- 4. FIN TABLA ---
/^!sample_table_end/ {
    in_table = 0
    if (output_file != "") close(output_file)
}

# --- 5. PROCESAMIENTO ---
in_table {
    # CASO A: ENCABEZADO
    if (block_lines == 0) {
        header = $0
        
        # Clasificación
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
            # Solo logueamos si falla
            log_msg("  [FAIL] " current_gsm " Header desconocido: <" header ">")
        }
    } 
    
    # CASO B: DATOS
    else {
        if (table_type == "CHECK_DATA") {
            split($0, fields, "\t")
            val = fields[2]
            if (val ~ /^(AA|AB|BB|NC|No Call|--|A|B|[0-9])$/) {
                table_type = "TEXT_GENOTYPE"
            } 
            else if (val ~ /^-?[0-9\.]+$/) { 
                 table_type = "NUMERIC_DATA" 
            }
            else {
                 table_type = "UNKNOWN"
                 if (block_lines == 1) {
                     log_msg("  [FAIL] " current_gsm " Dato desconocido en Col2: <" val ">")
                 }
            }
        }

        # --- ESCRITURA ---
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