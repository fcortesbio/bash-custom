# General
alias ..="cd .."
alias ff="fastfetch --logo none"
alias src="source ~/.bashrc" # quick source 
alias grep="rg" # grep wrapper
alias find="fd" # find wrapper
alias v=$EDITOR
alias v.="$EDITOR ."
alias wifi="nmtui"
alias lock="hyprlock"
alias fm="yazi"
alias clock="tty-clock"
alias sys="btop" 
alias ql="quicklinks" # from our tools
alias cd="z"
alias zi="zoxide query -i --preview 'eza --tree --level 2 --color=always {}'"

# EZA navigation
alias ls="eza --icons --group-directories-first" # ls wrapper
alias ll="eza -la --icons --octal-permissions --git" # ll wrapper
alias lt="eza -a --tree --level=2 --icons=always"

# Volume
alias vol1="wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.2"
alias vol2="wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.4"
alias vol3="wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.6"
alias vol4="wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.8"
alias vol5="wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0"
alias volM="wpctl set-mute @DEFAULT_AUDIO_SINK@ 1"
alias volU="wpctl set-mute @DEFAULT_AUDIO_SINK@ 0"

# System
alias shutdown="systemctl poweroff"
alias reboot="systemctl reboot"
alias suspend="systemctl suspend"
alias hibernate="systemctl hibernate"

# ML4W
alias apps="~/.config/ml4w/bin/ml4w-apps.sh"
alias ss="~/.config/ml4w/bin/ml4w-screenshots.sh"

# Git
alias gs="git status" # Git status
alias ga="git add" # Stage changes 
alias gc="git commit -m" # Commit changes
alias gp="git push" # Push to remote origin
alias gpl="git pull" # Pull changes from remote
alias gst="git stash" # 
alias gsp="git stash; git pull" # 
alias gfo="git fetch origin" # download changes from origin
alias gcheck="git checkout" # branch checkout
alias gcredential="git config credential.helper store"
alias gadc="git add -A && git diff --staged | wl-copy" # git raw stage + diff + clip ; use wisely 


# -----------------------------------------------------
# ML4W Apps
# -----------------------------------------------------
alias wallpaper='~/.config/ml4w/bin/ml4w-wallpaper.sh'
alias ml4w='flatpak run com.ml4w.welcome'
alias ml4w-settings='flatpak run com.ml4w.settings'
alias ml4w-calendar='flatpak run com.ml4w.calendar'
alias ml4w-hyprland='flatpak run com.ml4w.hyprlandsettings'
alias ml4w-sidebar='flatpak run com.ml4w.sidebar'
