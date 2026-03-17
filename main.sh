# ~/Scripts/main.sh
# Entry point for shell customization

# 1. Core utilities (Primitives)
dep_check() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed" >&2
            return 1
        fi
    done
}

# 2. Critical Dependency Check
dep_check "starship" "fastfetch" "eza" "fzf" "git" || return 1

# 3. Prompt Initialization
eval "$(starship init bash)"

# 4. Recursive Module Loading
# We use an absolute path to ensure reliability regardless of where bash starts
MODULES_DIR="$HOME/Scripts"

while IFS= read -r -d '' script; do
    # INVARIANT: Prevent infinite recursion by skipping this file
    [[ "$script" == *"/main.sh" ]] && continue
    
    if [ -r "$script" ] && [ -f "$script" ]; then
        source "$script"
    fi
done < <(find "$MODULES_DIR" -type f -name "*.sh" -print0 | sort -z)

# 5. Visual components
fastfetch