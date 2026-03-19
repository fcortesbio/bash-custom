# FastFetch
if [[ $(tty) == *"pts"* ]]; then
    if [ ! -f $HOME/.config/ml4w/settings/hide-fastfetch ]; then
        fastfetch
    fi
fi

# Startship
eval "$(starship init bash)"