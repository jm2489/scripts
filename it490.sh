#!/bin/bash

# Function to display the details of this wonderfully curated script!
show_details() {
    echo "Script Name: it490.sh"
    echo "Description: This is my infinity gauntlet script to setup the IT490 project from a fresh Ubuntu installation."
    echo "             Because I'm tired of having to be like Thanos and say, 'Fine, I'll do this myself.'"
    echo "Author: Judrianne Mahigne (jm2489@njit.edu)"
    echo "Version: 1.00"
    echo "Last Updated: Oct 16, 2024"
}

# Function to install packages from a file
install_packages() {

    package_file="packageList"

    if [ ! -f "$package_file" ]; then
        echo "Error: Package file packageList not found:"
        exit 1
    fi

    echo "Installing packages from $package_file ..."
    while IFS= read -r package || [[ -n "$package" ]]; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            sudo apt-get install -y "$package"
        else
            echo "$package is already installed."
        fi
    done < "$package_file"
    echo "All packages installed."
}


# Clone repository function
clone_repository() {

    githubRepos="githubRepos"
    
    if [ ! -f "$githubRepos" ]; then
        echo "Error: File githubRepos not found."
        exit 1
    fi

    while IFS= read -r repo_url || [[ -n "$repo_url" ]]; do
        git clone "$repo_url" || {
            echo "Failed to clone $repo_url"
            continue
        }
        echo "$repo_name cloned successfully."
    done < "$githubRepos"
}

# Function to set up MySQL
# The first infinity stone. LOL
setup_mysql() {

    echo "Setting up MySQL ..."

    # Modify the MySQL bind-address to allow connections from any IP in the /etc/mysql/mysqld.cnf
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

    # Run mysql_secure_installation non-interactively with pre loaded answers below.
    # Looks really ugly tbh I might do this just the one time.
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
# Second infinity stone. Idk which infinity stone to match up to what function. Use your imagination
setup_rabbitmq() {

    echo "Setting up RabbitMQ ..."
    # sudo ./rabbitmq.sh
    # status=$?
    status=0 # testing purposes
    if [ "$status" -eq 0 ]; then
        user=$(awk -F: '$3 == 1000 {print $1}' /etc/passwd)
        if [ ! -d NJIT ]; then
            sudo -u $user $0 -git-clone
        else
            echo "Directory NJIT already exists!"
            echo "Skipping git clone..."
        fi
        if [ -d /home/$user/RabbitMQ ]; then
            read -p "Script will overwrite directory /home/$user/RabbitMQ.. Do you want to continue? [y/n] " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                sudo rm -rf /hom/$user/RabbitMQ
                sudo -u $user cp -r NJIT/IT490/RabbitMQ /home/$user/
                echo "Copied RabbitMQ directory to /home/$user/RabbitMQ"
            else
                echo "Exiting."
                exit 1
            fi
        else
            sudo -u $user cp -r NJIT/IT490/RabbitMQ /home/$user/
            echo "Copied RabbitMQ directory to /home/$user/RabbitMQ"
        fi
    else
        echo "Failed to setup RabbitMQ server (exit code: $status)"
    fi
    # After RabbitMQ was successfully configured. Set it up in systemd as a service
    # Very straightforward. Would probably need to do some checks if service of the same name exists and etc. This is fine for now.
    echo "Editing service file..."
    sudo sed -i "s|^ExecStart=.*|ExecStart=/usr/bin/php /home/$user/RabbitMQ/testRabbitMQServer.php|" /home/$user/RabbitMQ/testRabbitMQServer.service
    echo "Creating service file in systemd..."
    sudo cp /home/$user/RabbitMQ/testRabbitMQServer.service /etc/systemd/system/
    echo "Reloading daemon-service..."
    sudo systemctl daemon-reload
    echo "Enabling service..."
    sudo systemctl enable testRabbitMQServer.service
    echo "Starting service..."
    sudo systemctl start testRabbitMQServer.service
    echo "Checking status..."
    sudo systemctl status testRabbitMQServer.service --no-pager
    echo "RabbitMQ daemon service complete"
    echo "Done."
}

# Setup apache2
# Third infinity stone... The kidney stone.
setup_apache2() {
    echo "Setting up apache2"
    # sudo ./apache2.sh
    # status=$?
    status=0 # testing purposes
    if [ "$status" -eq 0 ]; then
        user=$(awk -F: '$3 == 1000 {print $1}' /etc/passwd)
        if [ ! -d NJIT ]; then
            sudo -u $user $0 -git-clone
        else
            echo "Directory NJIT already exists!"
            echo "Skipping git clone..."
        fi
        if [ -d /var/www/html ]; then
            read -p "Script will overwrite directory /var/www/html.. Do you want to continue? [y/n] " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                sudo rm -rf /var/www/html
                sudo mkdir /var/www/html
                sudo cp NJIT/IT490/Web/index.html /var/www/html
                sudo cp -r NJIT/IT490/Web/php /var/www/html
                sudo cp -r NJIT/IT490/Web/media /var/www/html
                echo "Copied Web directory to /var/www/html"
                echo "Restarting apache2 services"
                sudo systemctl restart apache2
            else
                echo "Exiting."
                exit 1
            fi
        else
            echo "Directory /var/www/html does not exist."
            echo "Exiting."
            exit 1
        fi
        # Ask user if they would like to load localhost/index.html now
        read -p "Would you like to load localhost/index.html now? [y/n] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            sudo -u "$user" xdg-open http://localhost/index.html > /dev/null 2>&1 &
            exit 0
        else
            echo "Open http://localhost/index.html in browser to view web page"
            exit 1
        fi
    else
        echo "Failed to setup Apache2 server (exit code: $status)"
    fi
}


# Main
case "$1" in
    -details)
        show_details
        ;;
    -git-clone)
        if [ "$EUID" -eq 0 ]; then
            echo "Detected running with sudo privileges."
            echo "Please run this -git-clone as a regular user to avoid issues."
            exit 1
        fi
        clone_repository
        ;;
    -install-packages)
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
        install_packages
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
        chmod 755 rabbitmq.sh
        setup_rabbitmq
        ;;
    -apache2)
        if [ "$EUID" -ne 0 ]; then
            echo "Need sudo privileges to run -apache2."
            exit 1
        fi
        sudo -v
        while true; do 
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2>/dev/null &
        chmod 755 apache2.sh
        setup_apache2
        ;;
    *)
        echo "Usage: $0 -details | -git-clone | -mysql | -install-packages"
        ;;
esac
