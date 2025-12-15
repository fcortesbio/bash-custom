function new-repo() {
    # Usage: new-repo <repository-name>
    # This function creates a new GitHub public repository and initializes it locally;
    dep_check "git" || return 1
    dep_check "gh" || return 1
    dep_check "git" || return 1
    if [ -z "$1" ]; then
        echo "Usage: new-repo <repository-name>"
        return 1
    fi

    local repo_name="$1"
    
    # 1. Create and navigate to directory
    mkdir -p $repo_name
    cd $repo_name || return 1

    # 2. Initialize Git and create starter files

    git init -b main 
    echo "# $repo_name" > README.md
    touch .gitignore LICENSE

    # 3. Stage and commit
    git add -A && git commit -m "Initial commit"

    # 4. Use GH CLI to create remote and push in one step
    # --source=. drives gh to use current dir
    # --remote=origin tells gh to use the origin remote
    # --push pushes the current commits to the remote repository
    gh repo create "$repo_name" --public --source=. --remote=origin --push
}

gitignore() {
    # Usage: gitignore <pattern>
    # This function adds a file/directory/pattern to the .gitignore file.
    dep_check "git" || return 1
    dep_check "rg" || return 1
    # 1. Check if the pattern argument is empty
    if [ -z "$1" ]; then
        echo "Usage: gitignore <pattern>"
        return 1
    fi

    local pattern="$1"
    # 2. Check if we are in a git repository.
    local GIT_ROOT=$(git rev-parse --show-toplevel 2> /dev/null)
    if [ -z "$GIT_ROOT" ]; then
        echo "Error: Not a Git repository."
        return 1
    fi

    local GIT_IGNORE_FILE="$GIT_ROOT/.gitignore"

    # 3. Create file if it doesn't exist
    if [ ! -f "$GIT_IGNORE_FILE" ]; then
        touch "$GIT_IGNORE_FILE"
        echo "Created $GIT_IGNORE_FILE"
    fi
    
    # 4. Check for duplicates (grep -F (fixed string) -x (exact match) -q (quiet))
    if rg -Fxq "$pattern" "$GIT_IGNORE_FILE"; then
        echo "Pattern already exists in $GIT_IGNORE_FILE"
        return 0
    fi

    # 5. Ensure a trailing newline exists before appending
    if [ -s "$GIT_IGNORE_FILE" ] && [ "$(tail -c1 "$GIT_IGNORE_FILE" | wc -l)" -eq 0 ]; then
        echo "" >> "$GIT_IGNORE_FILE"
    fi

    # 6. Append the pattern to the .gitignore file and confirm
    echo "$pattern" >> "$GIT_IGNORE_FILE"
    echo "Added '$pattern' to $GIT_IGNORE_FILE"
    git add "$GIT_IGNORE_FILE" && git commit -m "Add $pattern to .gitignore" && git push
}

gacp() {
    # Usage: gacp <commit-message>
    # This function adds all changes to the staging area, commits them with the provided message, and pushes them to the current branch.
    dep_check "git" || return 1
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
