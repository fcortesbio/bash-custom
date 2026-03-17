# Common wrappers
alias src="source ~/.bashrc" # quick source 
alias grep='rg' # grep wrapper
alias ls='eza --icons --group-directories-first' # ls wrapper
alias ll='eza -la --icons --octal-permissions --git' # ll wrapper

# Shortcuts


# Jumpers
cnf() { jump "$HOME/.config" "$1" 3; }
pj()  { jump "$HOME/Projects" "$1"; }
vlt() { jump "$HOME/Vaults" "$1"; }
dl()  { jump "$HOME/Downloads" "$1"; }
rp()  { jump "$HOME/Repositories" "$1"; }
sc()  { jump "$HOME/Scripts" "$1"; }