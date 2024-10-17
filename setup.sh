#!/usr/bin/bash

# Adding it490.sh to alias in bashrc with the current working directory
# This is so that the script can be run from anywhere
add_alias() {
    # Check to see what is the default shell
    if [ -z "$SHELL" ]; then
        echo "Error: SHELL environment variable not set."
        exit 1
    fi
    # If using bash put in .bashrc if zsh put in .zshrc
    if [[ "$SHELL" == "/usr/bin/bash" ]]; then
        echo "Adding alias to .bashrc ..."
        echo "alias it490='bash $PWD/it490.sh'" >> ~/.bashrc
        source ~/.bashrc
        echo "Alias added."
    elif [[ "$SHELL" == "/usr/bin/zsh" ]]; then
        echo "Adding alias to .zshrc ..."
        echo "alias it490='bash $PWD/it490.sh'" >> ~/.zshrc
        source ~/.zshrc
        echo "Alias added."
    else
        echo "Error: Unsupported shell. I only care about two at the moment."
        exit 1
    fi
}

add_alias