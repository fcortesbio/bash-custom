wlc() {
    # Usage: wlc [--headers] <command> [args...]
    # Copies command output (stdout and stderr) to Wayland clipboard.
    dep_check "wl-copy" || return 1
    local header_mode=false
    local cmd_str

    # Parse flags
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -h|--headers)
                header_mode=true
                shift
                ;;
            --) 
                shift
                break
                ;;
            *) 
                break
                ;;
        esac
    done

    if [[ "$#" -eq 0 ]]; then
        echo "Usage: wlc [--headers] <command> [args...]" >&2
        return 1
    fi

    cmd_str="$*"

    {
        if [[ "$header_mode" == true ]]; then
            printf "# %s\n" "$cmd_str"
            printf "# type: combined (stdout/stderr)\n"
        fi

        # Execute command with stderr redirected to stdout to capture everything
        "$@" 2>&1
    } | tee >(wl-copy)
}

bl() {
    # Usage: bl [--functions | --aliases] [--verbose]
    # Lists custom functions/aliases using an external awk parser.

    # --- CONFIGURATION ---
    local CUSTOM_DIR="$HOME/bash-custom"
    local PARSER_PATH="$CUSTOM_DIR/parser.awk"
    # ---------------------

    # Safety Checks
    if [ ! -d "$CUSTOM_DIR" ]; then
        echo "Error: Directory $CUSTOM_DIR not found."
        return 1
    fi
    if [ ! -f "$PARSER_PATH" ]; then
        echo "Error: Parser script not found at $PARSER_PATH"
        return 1
    fi

    local show_funcs="true"
    local show_aliases="true"
    local verbose="false"

    # Argument Parsing
    for arg in "$@"; do
        case $arg in
            --functions) show_aliases="false" ;;
            --aliases)   show_funcs="false" ;;
            --verbose)   verbose="true" ;;
            *) echo "Usage: bl [--functions] [--aliases] [--verbose]"; return 1 ;;
        esac
    done

    # The Magic Command
    # 1. find: gets all .sh files
    # 2. xargs: passes them to awk
    # 3. awk: runs the parser file (-f) with our variables (-v)
    find "$CUSTOM_DIR" -maxdepth 1 -name "*.sh" -print0 | \
    xargs -0 awk -f "$PARSER_PATH" \
         -v show_funcs="$show_funcs" \
         -v show_aliases="$show_aliases" \
         -v verbose="$verbose"
}

dep_check(){
    # Usage: dep-check <command>
    # This function checks if a command is installed.
    local COMMAND="$1"
    if ! command -v "$COMMAND" &> /dev/null; then
        echo "Error: $COMMAND is not installed"
        return 1
    fi
    return 0
}

pdf_dc(){
    # Usage: pdf_dc <input.pdf> [password]
    # This function decrypts a PDF file using qpdf.

    dep_check "qpdf" || return 1

    # 1. Input file is mandatory
    # 2. Password is optional (defaults to 1144095880)
    local DEFAULT_PASSWORD="1144095880"
    local INPUT_FILE="$1"
    # Use Parameter Expansion: If $2 is unset or null, use DEFAULT_PASSWORD, otherwise use $2
    local PASSWORD="${2:-$DEFAULT_PASSWORD}"

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
    # Usage: pj <project-name>
    # This function lets you jump to any project in your development directory.

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

scrub_history() {
    # 1. SAFETY CHECKS (Do this first before touching anything)
    if [ $# -eq 0 ]; then
        echo "Usage: scrub_history <term1> [term2] [term3]..."
        echo "Example: scrub_history facebook.com twitter.com"
        return 1
    fi

    if pgrep -x "firefox" > /dev/null; then
        echo "❌ Error: Firefox is running. Please close it first."
        return @
    fi

    if pgrep -x "chrome" > /dev/null || pgrep -x "google-chrome-stable" > /dev/null; then
        echo "❌ Error: Google Chrome is running. Please close it first."
        return 1
    fi

    # 2. SETUP PATHS
    local firefox_profile
    local firefox_db
    local chrome_db
    
    # Find Firefox DB
    firefox_profile=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" 2>/dev/null | head -n 1)
    firefox_db="$firefox_profile/places.sqlite"
    
    # Find Chrome DB
    chrome_db="$HOME/.config/google-chrome/Default/History"

    # 3. BACKUPS (Perform once per run)
    echo "🛡️  Backing up databases..."
    [ -f "$firefox_db" ] && cp "$firefox_db" "${firefox_db}.bak"
    [ -f "$chrome_db" ]  && cp "$chrome_db" "${chrome_db}.bak"

    # 4. ITERATION (The Logic Loop)
    # We loop through every argument provided to the function
    for term in "$@"; do
        echo "🧹 Scrubbing term: '$term'..."

        # --- Firefox Deletion ---
        if [ -f "$firefox_db" ]; then
            sqlite3 "$firefox_db" <<EOF
            DELETE FROM moz_historyvisits 
            WHERE place_id IN (SELECT id FROM moz_places WHERE url LIKE '%$term%');
            DELETE FROM moz_places 
            WHERE url LIKE '%$term%' 
            AND id NOT IN (SELECT fk FROM moz_bookmarks WHERE fk IS NOT NULL);
EOF
        fi

        # --- Chrome Deletion ---
        if [ -f "$chrome_db" ]; then
            sqlite3 "$chrome_db" <<EOF
            DELETE FROM visits 
            WHERE url IN (SELECT id FROM urls WHERE url LIKE '%$term%');
            DELETE FROM urls 
            WHERE url LIKE '%$term%';
EOF
        fi
    done

    # 5. OPTIMIZATION (Vacuum once at the end)
    echo "🏗️  Optimizing databases (VACUUM)..."
    [ -f "$firefox_db" ] && sqlite3 "$firefox_db" "VACUUM;"
    [ -f "$chrome_db" ]  && sqlite3 "$chrome_db" "VACUUM;"

    echo "🎉 All Done."
}
