dep_check(){
    # usage dep-check <command>
    local COMMAND="$1"
    if ! command -v "$COMMAND" &> /dev/null; then
        echo "Error: $COMMAND is not installed"
        return 1
    fi
    return 0
}

pdf_dc(){
    # Usage: pdf_dc <input.pdf> [password]
    # 1. Input file is mandatory
    # 2. Password is optional (defaults to 1144095880)

    local DEFAULT_PASSWORD="1144095880"
    local INPUT_FILE="$1"
    # Use Parameter Expansion: If $2 is unset or null, use DEFAULT_PASSWORD, otherwise use $2
    local PASSWORD="${2:-$DEFAULT_PASSWORD}"

    dep_check "qpdf" || return 1

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

pj(){
    # This function lets you jump to any project in your development directory.
    # Usage: pj <project-name>
    # It uses fzf to select the project from the list of projects in the development directory.

    # --- Dependency Check ---
    dep_check "fzf" || return 1
    dep_check "eza" || return 1
    #  Not checking for find or cd as they are core commands

    # Change this to where you keep your project
    local PROJECT_DIR="$HOME/projects"

    # 1. List directories max depth 2
    # 2. Pipe to fzf for fuzzy selection

    local selected_dir=$(find "$PROJECT_DIR" -maxdepth 2 -type d -mindepth 1 | fzf)

    if [ -n "$selected_dir" ]; then
        cd "$selected_dir" || return 1
        echo "Jumped to $selected_dir"
        eza -a --icons=always
        return 0
    else
        echo "No project selected"
        return 1

    fi    
}
