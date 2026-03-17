# Ensure dependency is available if jumper is sourced independently
if ! command -v dep_check &> /dev/null; then
    source "$(dirname "$BASH_SOURCE")/utils.sh"
fi

_fuzzy_jump() {
    local target_base="$1"
    local label="$2"
    local query="$3"
    local max_depth="${4:-2}"

    # Gatekeeping: Hard dependencies
    dep_check "fzf" || return 1
    dep_check "eza" || return 1
    dep_check "fd"  || return 1

    if [[ ! -d "$target_base" ]]; then
        echo "Error: Base directory '$target_base' not found." >&2
        return 1
    fi

    # Since dep_check passed, we can define the command directly
    local list_cmd="fd . '$target_base' --max-depth $max_depth --type d --mindepth 1"

    local selected_dir
    # We capture the output of fd separately to ensure we don't pipe an error into fzf
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
