dep_check "gh" "git" || return 1

function new-repo() {
    # Usage: new-repo <repository-name>
    # This function creates a new GitHub public repository and initializes it locally;

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