# inspector_gadget.awk - vFinal_Polished
BEGIN {
    FS = "\t"
    status = "NO_GENOTYPE"
    header_score = 0
}

# Inicio de la tabla de datos
/^!sample_table_begin/ {
    in_table = 1
    line_count = 0
    header_found = 0
    next
}

/^!sample_table_end/ {
    in_table = 0
    next
}

in_table {
    line_count++

    # --- 1. ANÁLISIS DEL HEADER ---
    if (line_count == 1 && !header_found) {
        header = $0
        header_found = 1
        
        # Palabras clave de confianza
        if ($0 ~ /B_Allele_Freq/ || $0 ~ /Log_R_Ratio/ || \
            $0 ~ /CONFIDENCE/ || $0 ~ /FORCED CALL/ || \
            $0 ~ /RAS1/ || $0 ~ /Genotype/ || $0 ~ /Call/) {
            header_score = 1
        }
        next
    }

    # --- 2. ANÁLISIS DE DATOS ---
    if (line_count > 1 && line_count < 100) {
        
        # A) Genotipado de TEXTO (AA, AB, BB, NC, No Call)
        if ($0 ~ /(^|\t)(AA|AB|BB|NC|No Call)(\t|$)/) {
            status = "HARD_GENOTYPE" # Asignamos, NO imprimimos aun
            exit 0 # Vamos directo al END
        }

        # B) Genotipado NUMÉRICO (0, 1, 2)
        if ($0 ~ /(^|\t)(0|1|2)(\t|$)/ && NF > 2) { 
            status = "MAYBE_GENOTYPE"
            # No salimos, seguimos buscando algo mejor
        }

        # C) Señales Crudas (Intensity)
        if ((header ~ /SIGNAL/ || header ~ /Intensity/) && $0 ~ /\t[0-9]{3,}/) {
            status = "SIGNAL_DATA"
            exit 0
        }

        # D) Illumina BAF
        if (header ~ /B_Allele_Freq/ && $0 ~ /\t(0|1|0\.[0-9]+)(\t|$)/) {
             status = "SIGNAL_DATA"
             exit 0
        }
    }
    
    if (line_count > 150) {
        in_table = 0 # Dejamos de leer esta tabla si no encontramos nada pronto
    }
}

END {
    print status
}