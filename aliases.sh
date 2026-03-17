# Common wrappers
alias src="source ~/.bashrc" # quick source 
alias ls='eza --icons --group-directories-first' # ls wrapper
alias ll='eza -la --icons --octal-permissions --git' # ll wrapper

# Shortcuts


# Jumpers
alias cnf='_fuzzy_jump "$HOME/.config" "Config" "$1" 3'
alias pj='_fuzzy_jump "$HOME/Projects" "Project" "$1"'
alias vlt='_fuzzy_jump "$HOME/Vaults" "Vaults" "$1"'
alias dl='_fuzzy_jump "$HOME/Downloads" "Downloads" "$1"'
alias rp='_fuzzy_jump "$HOME/Repositories" "Repositories" "$1"'
alias sc='_fuzzy_jump "$HOME/Scripts" "Scripts" "$1"'