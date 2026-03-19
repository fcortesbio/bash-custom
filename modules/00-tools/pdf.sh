dep_check "qpdf" "rg" || return 1

pdf_dc() {
    # Usage: pdf_dc <input.pdf> [password]
    # This function decrypts a PDF file using qpdf.

    # --- Configuration ---
    local env_file="$HOME/Secrets/.env"
    local input_file="$1"
    local password="$2"

    # 1. Load default password if not provided as an argument
    if [[ -z "$password" ]]; then
        if [[ -f "$env_file" ]]; then
            # Source in a subshell or carefully to avoid polluting environment
            # Here we just want the value of defpass
            local defpass
            defpass=$(rg "^defpass=" "$env_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
            password="${defpass}"
        fi
    fi

    # 2. Final check: if still empty, prompt or error
    if [[ -z "$password" ]]; then
        echo "Error: No password provided and 'defpass' not found in .env" >&2
        return 1
    fi

    # 3. Input file validation
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file '$input_file' not found" >&2
        return 1
    fi

    local output_file="${input_file%.pdf}_decrypted.pdf"

    # 4. Prevent Accidental Overwrite
    if [[ -f "$output_file" ]]; then
        echo "Error: Output file '$output_file' already exists."
        read -p "Do you want to overwrite it? (y/n): " overwrite
        if [[ "$overwrite" != "y" ]]; then
            echo "Operation cancelled."
            return 1
        fi
    fi

    # 5. Decryption Process
    echo "Decrypting $input_file..."
    if qpdf --password="$password" --decrypt "$input_file" "$output_file"; then
        echo "✅ Decryption successful: $output_file"
    else
        local exit_code=$?
        echo "❌ Decryption failed (qpdf exit code: $exit_code)"
        return $exit_code
    fi
}
