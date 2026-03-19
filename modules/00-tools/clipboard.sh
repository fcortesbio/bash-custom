dep_check "fzf" "wl-copy" || return 1

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
