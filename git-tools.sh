function new-repo() {
    # Create a new GitHub repository and initialize it locally; 
    # This assumes the gh cli is installed, configured, and the user is logged in.
    if [ -z "$1" ]; then
        echo "Usage: new-repo <repository-name>"
        return 1
    fi

    local repo_name="$1"

    gh repo create "$repo_name" --public
    git init "$repo_name"
    cd "$repo_name"
    touch README.md .gitignore LICENSE
    git remote add origin "https://github.com/fcortesbio/$repo_name.git"
    git add -A && git commit -m "Initial commit" && git push -u origin main
}

gitignore() {
    # Add a file/directory/pattern to .gitignore
    # 1. Check if the pattern argument is empty
    if [ -z "$1" ]; then
        echo "Usage: gitignore <pattern>"
        return 1
    fi

    # 2. Set the pattern variable to the first argument 
    local pattern="$1"

    # 3. Get the root directory of the git repository
    local GIT_ROOT=$(git rev-parse --show-toplevel 2> /dev/null)

    # 4. Define the full path to the .gitignore file in the root
    local GIT_IGNORE_FILE="$GIT_ROOT/.gitignore"

    # 5. Add the pattern to the root .gitignore file
    echo "$pattern" >> "$GIT_IGNORE_FILE"

    # Optional: Add a success message
    echo "Added '$pattern' to $GIT_IGNORE_FILE"
}