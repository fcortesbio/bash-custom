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
