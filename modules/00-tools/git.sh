dep_check "git"  "rg" "fzf" "fd" || return 1

gitignore() {
    # Usage: gitignore <pattern> [pattern...]
    # Adds one or more patterns to .gitignore, commits, and pushes.

    if [ $# -eq 0 ]; then
        echo "Usage: gitignore <pattern> [pattern...]"
        return 1
    fi

    # 1. Locate Git Root
    local GIT_ROOT=$(git rev-parse --show-toplevel 2> /dev/null)
    if [ -z "$GIT_ROOT" ]; then
        echo "Error: Not a Git repository."
        return 1
    fi

    local GIT_IGNORE_FILE="$GIT_ROOT/.gitignore"

    # 2. Create file if missing
    if [ ! -f "$GIT_IGNORE_FILE" ]; then
        touch "$GIT_IGNORE_FILE"
        echo "Created $GIT_IGNORE_FILE"
    fi

    # 3. Ensure trailing newline exists (do this once before loop)
    if [ -s "$GIT_IGNORE_FILE" ] && [ "$(tail -c1 "$GIT_IGNORE_FILE" | wc -l)" -eq 0 ]; then
        echo "" >> "$GIT_IGNORE_FILE"
    fi

    local added_count=0
    local commit_msg_list=""

    # 4. Loop through ALL arguments
    for pattern in "$@"; do
        # Check for duplicates (Fixed string, Exact line, Quiet)
        if rg -Fxq "$pattern" "$GIT_IGNORE_FILE"; then
            echo "Skipping '$pattern' (already in .gitignore)"
        else
            echo "$pattern" >> "$GIT_IGNORE_FILE"
            echo "Added '$pattern'"
            
            # Track changes for the commit message
            ((added_count++))
            commit_msg_list+="$pattern, "
        fi
    done

    # 5. Commit and Push ONLY if changes were made
    if [ $added_count -gt 0 ]; then
        # Remove trailing comma and space
        commit_msg_list="${commit_msg_list%, }"
        
        echo "Committing and pushing changes..."
        git add "$GIT_IGNORE_FILE"
        git commit -m "Add to .gitignore: $commit_msg_list"
        git push
    else
        echo "No new patterns were added."
    fi
}

gacp() {
    # Usage: gacp <commit-message>
    # This function adds all changes to the staging area, commits them with the provided message, and pushes them to the current branch.
    if [ -z "$1" ]; then
        echo "Usage: gacp <commit-message>"
        return 1
    fi

    local commit_message="$1"
    git add -A 
    git commit -m "$commit_message"
    # get current branch name dynamically
    local branch_name=$(git branch --show-current)
    git push origin "$branch_name"   
    echo "Pushed to origin/$branch_name"
}
