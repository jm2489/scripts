#!/bin/bash

# Load variables from the .env file
source testRabbitMQ.env

# Enable and start rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server

# Configure RabbitMQ
rabbitmqctl add_user "$USER" "$PASSWORD"
rabbitmqctl set_user_tags "$USER" administrator
rabbitmqctl add_vhost "$VHOST"
rabbitmqctl set_permissions -p "$VHOST" "$USER" ".*" ".*" ".*"

# Enable RabbitMQ Management Plugin
rabbitmq-plugins enable rabbitmq_management
systemctl restart rabbitmq-server

echo "RabbitMQ setup completed for user '$USER' and vhost '$VHOST'."
