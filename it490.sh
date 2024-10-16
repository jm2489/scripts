#!/bin/bash

# Function to display the details
show_details() {
    echo "Script Name: it490.sh"
    echo "Description: This is my infinity gauntlet script to setup the IT490 project from a fresh Ubuntu installation."
    echo "             Because I'm tired of having to be like Thanos and say, 'Fine, I'll do this myself.'"
    echo "Author: Judrianne Mahigne (jm2489@njit.edu)"
    echo "Version: 1.00"
    echo "Last Updated: Oct 15, 2024"
}

# Function to install packages from a file
install_packages() {
    local package_file="$1"

    if [ ! -f "$package_file" ]; then
        echo "Package file not found: $package_file"
        echo "Please run sudo ./it490.sh <package_list_file>"
        exit 1
    fi

    echo "Installing packages from $package_file ..."
    while IFS= read -r package || [[ -n "$package" ]]; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            echo "Installing: $package"
            sudo apt-get install -y "$package"
        else
            echo "$package is already installed."
        fi
    done < "$package_file"
    echo "All packages installed."
}


# Clone repository function
clone_repository() {
    
    if [ ! -f githubRepos ]; then
        echo "Error: File githubRepos not found."
        exit 1
    fi

    # Iterate over each URL and clone the repository
    while IFS= read -r repo_url || [[ -n "$repo_url" ]]; do
        repo_name=$(basename "$repo_url" .git)
        echo "Cloning $repo_name from $repo_url ..."
        git clone "$repo_url" "$repo_name" || {
            echo "Failed to clone $repo_url"
            continue
        }
        echo "$repo_name cloned successfully."
    done < githubRepos
}

# Function to set up MySQL
# The first infinity stone. LOL
setup_mysql() {
    echo "Setting up MySQL ..."
    chmod 600 client.cnf

    # Modify the MySQL bind-address to allow connections from any IP in the mysqld.cnf
    echo "Configuring MySQL bind-address..."
    sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

    # Restart MySQL service to apply changes
    echo "Restarting MySQL service..."
    sudo systemctl restart mysql

    if [ -f mysql_setup.sql ]; then
        echo "Running MySQL configuration from mysql_setup.sql..."
        sudo mysql < mysql_setup.sql
    else
        echo "Error: mysql_setup.sql not found."
        exit 1
    fi

    # Run mysql_secure_installation non-interactively
    # NEED TO REPLACE WITH MEANINGFUL PASSWORDS PLEASE
    echo "Running mysql_secure_installation..."
    sudo mysql_secure_installation <<EOF
y
2
y
y
y
y
EOF

    echo "MySQL configuration completed successfully."
    echo "Showing databse and tables:"
    mysql --defaults-file=client.cnf -e 'show databases;'
    mysql --defaults-file=client.cnf -e 'show tables;' logindb
    mysql --defaults-file=client.cnf -e 'desc users' logindb
    echo "Login info: User: rabbit Password: rabbitIT490!"
    echo "MySQL setup complete"
}

# Setup rabbitmq server
setup_rabbitmq() {
    echo "Setting up RabbitMQ ..."
    # Call child script rabbitmq.sh
    sudo ./rabbitmq.sh
    status=$?
    if [ "$status" -eq 0 ]; then
        echo "RabbitMQ server setup complete"
    else
        echo "Failed to setup RabbitMQ server (exit code: $status)"
    fi
}


# Main logic
case "$1" in
    -details)
        show_details
        ;;
    -clone)
        clone_repository
        ;;
    -install)
        if [ "$EUID" -ne 0 ]; then
            echo "Need sudo privileges to run -install."
            exit 1
        fi
        sudo -v
        while true; do 
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2>/dev/null &
        install_packages "$2"
        ;;
    -mysql)
        if [ "$EUID" -ne 0 ]; then
            echo "Need sudo privileges to run -mysql."
            exit 1
        fi
        sudo -v
        while true; do 
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2>/dev/null &
        setup_mysql
        ;;
    -rabbitmq)
        if [ "$EUID" -ne 0 ]; then
            echo "Need sudo privileges to run -rabbitmq."
            exit 1
        fi
        sudo -v
        while true; do 
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2>/dev/null &
        setup_rabbitmq
        ;;
    *)
        echo "Usage: $0 -details | -clone | -mysql | -install <package_list_file> "
        ;;
esac
