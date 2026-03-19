#!/usr/bin/env bash
# Entry point for shell customization

# Track startup time in microseconds (strip decimal)
STARTUP_START=${EPOCHREALTIME/./}

# --------------------------------------------------
# Dependency Check
# --------------------------------------------------
INIT_ERRORS=0

dep_check() {
    local missing=()
    local caller_name="$(basename "${BASH_SOURCE[1]}")"

    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
            ((INIT_ERRORS++))
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        printf "\e[1;31m[!] Dependency Error in %s:\e[0m\n" "$caller_name"
        printf "    Missing: \e[33m%s\e[0m\n" "${missing[*]}"
        printf "    Fix: \e[32msudo pacman -S %s\e[0m\n\n" "${missing[*]}"
        return 1
    fi
    return 0
}

dep_check "fd" || return 1

# --------------------------------------------------
# Module loader
# --------------------------------------------------
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$REPO_ROOT/modules"

# Set to true/false (no quotes needed for the check below)
DEBUG_LOAD=true 

# Ensure we use a predictable sort order for our numbered files
export LC_ALL=C

while IFS= read -r -d '' script; do
    [[ -r "$script" ]] || continue

    if [[ "$DEBUG_LOAD" == "true" ]]; then
        start=${EPOCHREALTIME/./}
        
        source "$script"
        
        end=${EPOCHREALTIME/./}
        duration_us=$((end - start))
        
        # Display relative path from MODULES_DIR for better visibility
        rel_path="${script#$MODULES_DIR/}"
        printf "Loaded %-30s %7d µs\n" "$rel_path" "$duration_us"
    else
        source "$script"
    fi
# Recursively find .sh files, sort them alphabetically
done < <(fd . "$MODULES_DIR" --type f --extension sh --print0 | sort -z)

# --------------------------------------------------
# Startup summary
# --------------------------------------------------
STARTUP_END=${EPOCHREALTIME/./}
TOTAL_US=$((STARTUP_END - STARTUP_START))
TOTAL_MS=$((TOTAL_US / 1000))

if [[ "$DEBUG_LOAD" == "true" ]]; then
    printf "\n\033[1;32mShell startup completed in %d µs (%d ms)\033[0m\n" "$TOTAL_US" "$TOTAL_MS"
fi