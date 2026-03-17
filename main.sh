# ~/Scripts/main.sh
# Entry point for shell customization

STARTUP_START=${EPOCHREALTIME/./}

# --------------------------------------------------
# Core utilities
# --------------------------------------------------

dep_check() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: required dependency '$cmd' not found" >&2
            return 1
        fi
    done
}

# Critical dependencies
if ! dep_check starship eza fzf git rg fd; then
    echo "Shell initialization aborted." >&2
    return 1
fi

# --------------------------------------------------
# Prompt
# --------------------------------------------------

eval "$(starship init bash)"

# --------------------------------------------------
# Module loader
# --------------------------------------------------

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$REPO_ROOT/modules"

DEBUG_LOAD=true

for script in "$MODULES_DIR"/*.sh; do
    [[ -r "$script" ]] || continue

    if $DEBUG_LOAD; then
        start=${EPOCHREALTIME/./}

        source "$script"

        end=${EPOCHREALTIME/./}
        duration_us=$((end - start))

        printf "Loaded %-25s %6d µs\n" "$(basename "$script")" "$duration_us"
    else
        source "$script"
    fi
done

# --------------------------------------------------
# Optional visual tools
# --------------------------------------------------

if command -v fastfetch &> /dev/null; then
    fastfetch
fi

# --------------------------------------------------
# Startup summary
# --------------------------------------------------

STARTUP_END=${EPOCHREALTIME/./}
TOTAL_US=$((STARTUP_END - STARTUP_START))
TOTAL_MS=$((TOTAL_US / 1000))

printf "\nShell startup completed in %d µs (%d ms)\n" "$TOTAL_US" "$TOTAL_MS"