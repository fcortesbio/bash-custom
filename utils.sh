#!/bin/bash

# --- CORE UTILITIES ---

dep_check() {
    # Usage: dep_check <command>
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed" >&2
        return 1
    fi
}

# --- CLIPBOARD & DOCUMENTATION ---

wlc() {
    # Usage: wlc [--headers] <command> [args...]
    # Captures stdout and stderr to the Wayland clipboard while printing to terminal.
    dep_check "wl-copy" || return 1
    
    local header_mode=false
    local cmd_str

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -h|--headers) header_mode=true; shift ;;
            --) shift; break ;;
            *) break ;;
        esac
    done

    if [[ "$#" -eq 0 ]]; then
        echo "Usage: wlc [--headers] <command> [args...]" >&2
        return 1
    fi

    cmd_str="$*"

    {
        if [[ "$header_mode" == true ]]; then
            printf "# Command: %s\n" "$cmd_str"
            printf "# Date: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')"
            printf "# Type: combined (stdout/stderr)\n\n"
        fi
        # Execute and merge streams
        "$@" 2>&1
    } | tee >(wl-copy)
}

# --- SYSTEM EXPLORATION ---

bl() {
    # Usage: bl [--functions | --aliases] [--verbose]
    # Lists custom functions/aliases using an inlined AWK parser.
    local CUSTOM_DIR="$HOME/bash-custom"
    
    if [[ ! -d "$CUSTOM_DIR" ]]; then
        echo "Error: Directory $CUSTOM_DIR not found." >&2
        return 1
    fi

    local show_funcs="true"
    local show_aliases="true"
    local verbose="false"

    for arg in "$@"; do
        case $arg in
            --functions) show_aliases="false" ;;
            --aliases)   show_funcs="false" ;;
            --verbose)   verbose="true" ;;
            *) echo "Usage: bl [--functions] [--aliases] [--verbose]" >&2; return 1 ;;
        esac
    done

    # Inlined AWK logic for maximum portability
    local awk_script='
    FNR == 1 {
        n = split(FILENAME, parts, "/")
        printf "\n\033[1;33m>>> %s\033[0m\n", parts[n]
    }
    /^alias / {
        if (show_aliases == "true") printf "  \033[36m[ALIAS]\033[0m    %s\n", $0
    }
    /^(function +)?[a-zA-Z0-9_-]+(\(\))? *\{/ {
        if (show_funcs == "true") {
            line = $0
            sub(/^function /, "", line); sub(/\(\)/, "", line)
            sub(/\{/, "", line); sub(/ +$/, "", line)
            printf "  \033[32m[FUNC]\033[0m      %s\n", line
            if (verbose == "true") {
                while ((getline doc_line) > 0) {
                    if (doc_line ~ /^[ \t]*#/) {
                        sub(/^[ \t]*# ?/, "", doc_line)
                        printf "              \033[90m%s\033[0m\n", doc_line
                    } else break
                }
            }
        }
    }'

    find "$CUSTOM_DIR" -maxdepth 1 -name "*.sh" -print0 | \
    xargs -0 awk -v show_funcs="$show_funcs" \
                 -v show_aliases="$show_aliases" \
                 -v verbose="$verbose" \
                 "$awk_script"
}

# --- PRIVACY & CLEANUP ---

scrub_history() {
    # Usage: scrub_history <term1> [term2...]
    if [[ $# -eq 0 ]]; then
        echo "Usage: scrub_history <term1> [term2...]" >&2
        return 1
    fi

    # Check for running browsers
    if pgrep -x "firefox" > /dev/null || pgrep -x "chrome" > /dev/null; then
        echo "Error: Browser is running. Please close Firefox/Chrome first." >&2
        return 1
    fi

    # Path Discovery
    local ff_base="$HOME/.mozilla/firefox"
    local chrome_db="$HOME/.config/google-chrome/Default/History"

    for term in "$@"; do
        # SQL Sanitize: escape single quotes by doubling them
        local safe_term="${term//\'/\'\'}"
        echo "Processing term: '$term'..."

        # 1. Firefox (Handles multiple profiles)
        if [[ -d "$ff_base" ]]; then
            find "$ff_base" -name "places.sqlite" -type f | while read -r db; do
                [ -f "$db" ] && cp "$db" "${db}.bak"
                sqlite3 "$db" <<EOF
DELETE FROM moz_historyvisits WHERE place_id IN (SELECT id FROM moz_places WHERE url LIKE '%$safe_term%');
DELETE FROM moz_places WHERE url LIKE '%$safe_term%' AND id NOT IN (SELECT fk FROM moz_bookmarks WHERE fk IS NOT NULL);
EOF
            done
        fi

        # 2. Chrome
        if [[ -f "$chrome_db" ]]; then
            [ -f "$chrome_db" ] && cp "$chrome_db" "${chrome_db}.bak"
            sqlite3 "$chrome_db" <<EOF
DELETE FROM visits WHERE url IN (SELECT id FROM urls WHERE url LIKE '%$safe_term%');
DELETE FROM urls WHERE url LIKE '%$safe_term%';
EOF
        fi
    done

    # 3. Vacuum
    echo "Optimizing databases..."
    find "$ff_base" -name "places.sqlite" -exec sqlite3 {} "VACUUM;" \; 2>/dev/null
    [[ -f "$chrome_db" ]] && sqlite3 "$chrome_db" "VACUUM;"
}

pdf_dc() {
    # Usage: pdf_dc <input.pdf> [password]
    # This function decrypts a PDF file using qpdf.
    dep_check "qpdf" || return 1
    dep_check "rg" || return 1

    # --- Configuration ---
    local env_file="$HOME/bash-custom/.env"
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

_fuzzy_jump_engine() {
    local target_base="$1"
    local label="$2"
    local query="$3"
    local max_depth="${4:-2}"

    dep_check "fzf" || return 1
    dep_check "eza" || return 1

    if [[ ! -d "$target_base" ]]; then
        echo "Error: Base directory '$target_base' not found." >&2
        return 1
    fi

    local list_cmd
    if command -v fd &> /dev/null; then
        list_cmd="fd . '$target_base' --max-depth $max_depth --type d --mindepth 1"
    else
        list_cmd="find '$target_base' -maxdepth $max_depth -type d -mindepth 1"
    fi

    local selected_dir
    selected_dir=$(eval "$list_cmd" | fzf \
        --query="$query" \
        --select-1 \
        --exit-0 \
        --preview "eza --tree --level 2 --icons=always --color=always {}" \
        --preview-window="right:50%:rounded" \
        --header "Jump to $label")

    if [[ -n "$selected_dir" && -d "$selected_dir" ]]; then
        cd "$selected_dir" || return 1
        echo -e "\033[1;32mJumped to:\033[0m $selected_dir"
        echo "------------------------------------------"
        eza -la --icons=always
    fi
}

pj() {
    # Usage: pj [query]
    _fuzzy_jump_engine "$HOME/projects" "Project" "$1"
}

conf() {
    # Usage: conf [query]
    # Increased depth to 3 for nested configs (e.g., nvim/lua/user)
    _fuzzy_jump_engine "$HOME/.config" "Config" "$1" 3
}
