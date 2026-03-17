_fuzzy_select_dir() {
    local base="$1"
    local query="$2"
    local max_depth="${3:-2}"

    command -v fzf >/dev/null && command -v fd >/dev/null || return 1
    [[ -d "$base" ]] || return 1

    fd . "$base" \
        --type d \
        --mindepth 1 \
        --max-depth "$max_depth" 2>/dev/null |
    fzf \
        --query="$query" \
        --select-1 \
        --exit-0
}

_fuzzy_select_dir_preview() {
    local base="$1"
    local query="$2"
    local max_depth="${3:-2}"

    command -v fzf >/dev/null && command -v fd >/dev/null && command -v eza >/dev/null || return 1
    [[ -d "$base" ]] || return 1

    fd . "$base" \
        --type d \
        --mindepth 1 \
        --max-depth "$max_depth" 2>/dev/null |
    fzf \
        --query="$query" \
        --select-1 \
        --exit-0 \
        --preview 'eza --tree --level 2 --icons=always --color=always {}' \
        --preview-window="right:50%:rounded"
}

_jump_to() {
    local dir="$1"
    [[ -d "$dir" ]] || return 1

    cd "$dir" || return 1

    if [[ "$JUMP_VERBOSE" == true ]]; then
        printf "\033[1;32mJumped to:\033[0m %s\n" "$dir"
        eza -la --icons 2>/dev/null
    fi
}

jump() {
    local base="$1"
    local query="$2"
    local depth="${3:-2}"

    local dir
    dir=$(_fuzzy_select_dir_preview "$base" "$query" "$depth") || return

    _jump_to "$dir"
}

_fuzzy_search_dir() {
    local base="$1"
    local query="$2"

    command -v rg >/dev/null && command -v fzf >/dev/null || return 1
    [[ -d "$base" ]] || return 1

    rg --files-with-matches --no-messages "$query" "$base" |
    xargs -I {} dirname {} |
    sort -u |
    fzf --header "Search: $query"
}

jump_search() {
    local base="$1"
    local query="$2"

    local dir
    dir=$(_fuzzy_search_dir "$base" "$query") || return

    _jump_to "$dir"
}

# open selected dir in nvim
edit_dir() {
    local dir
    dir=$(_fuzzy_select_dir "$HOME/Projects") || return
    nvim "$dir"
}

# copy path instead of cd
copy_dir() {
    local dir
    dir=$(_fuzzy_select_dir "$HOME") || return
    printf "%s" "$dir" | wl-copy
}