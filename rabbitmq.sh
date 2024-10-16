#!/bin/bash

# Load variables from the .env file
if [ ! -f rabbitMQ.env ]; then
    echo "Error: rabbitMQ.env not found."
    exit 1  # Exit with failure if .env file is missing
fi

# Load variables from the .env file
source rabbitMQ.env

# Enable and start rabbitmq-server
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# Configure RabbitMQ
rabbitmqctl add_user "$USER" "$PASSWORD"
rabbitmqctl set_user_tags "$USER" administrator
rabbitmqctl add_vhost "$VHOST"
rabbitmqctl set_permissions -p "$VHOST" "$USER" ".*" ".*" ".*"

# Enable RabbitMQ Management Plugin
rabbitmq-plugins enable rabbitmq_management
systemctl restart rabbitmq-server

echo "RabbitMQ setup completed for user '$USER' and vhost '$VHOST'."
exit 0