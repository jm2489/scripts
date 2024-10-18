#!/bin/bash

# # Creating a simple setup script to add it490.sh to alias
# # This is to make it easier to run the script from anywhere in the terminal
# # This script will be added to the .bashrc file or .zshrc file
 
scriptPath=$PWD
if [ -z "$1" ]; then
    echo "Setting up .bashrc"
    echo "alias sudo='sudo '" >> ~/.bashrc
    echo "alias it490='$scriptPath/it490.sh '" >> ~/.bashrc
    exec bash
    exit 0
else
    if [ "$1" == "zsh" ]; then
        echo "Setting up .zshrc"
        echo "alias sudo='sudo '" >> ~/.zshrc
        echo "alias it490='$scriptPath/it490.sh '" >> ~/.zshrc
        exec zsh
        exit 0
    fi
fi

echo "Done"
exit 0