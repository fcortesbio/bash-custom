pdf_dc(){
    # Usage: pdf_dc <input.pdf> [password]
    # 1. Input file is mandatory
    # 2. Password is optional (defaults to 1144095880)

    local DEFAULT_PASSWORD="1144095880"
    local INPUT_FILE="$1"
    # Use Parameter Expansion: If $2 is unset or null, use DEFAULT_PASSWORD, otherwise use $2
    local PASSWORD="${2:-$DEFAULT_PASSWORD}"

    ## --- Dependency Check ---
    if ! command -v qpdf &> /dev/null; then
        echo "Error: qpdf is not installed"
        return 1
    fi
    # --- Input File Check ---
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: Input file '$INPUT_FILE' not found"
        return 1
    fi

    ### --- Output File Setup ---

    local BASENAME="${INPUT_FILE%.pdf}"
    local OUTPUT_FILE="${BASENAME}_decrypted.pdf"

    # if [ -f "$OUTPUT_FILE" ]; then
    #     echo "Error: Output file '$OUTPUT_FILE' already exists"
    #     return 1
    # fi

    ### Prevent Accidental Overwrite ---
    if [ -f "$OUTPUT_FILE" ]; then
        echo "Error: Output file '$OUTPUT_FILE' already exists"
        read -p "Do you want to overwrite it? (y/n): " overwrite
        if [ "$overwrite" != "y" ]; then
            echo "Exiting..."
            return 1
        fi
    fi

    ### --- Decryption Process ---
    echo "Decrypting $INPUT_FILE to $OUTPUT_FILE..."
    echo "Output to: $(pwd)/$OUTPUT_FILE"

    qpdf --password="$PASSWORD" --decrypt "$INPUT_FILE" "$OUTPUT_FILE"
    
    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "Decryption successful."
    else
        echo "Decryption failed. qpdf returned exit code $EXIT_CODE"
        return 1
    fi

    return $EXIT_CODE
}