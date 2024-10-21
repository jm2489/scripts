#!/bin/bash

# Set current directory as global variable
CURRENT_DIR=$(dirname "$(readlink -f "$0")")

# Check to see if .env file exist
# Load variables from the .env file
if [ ! -f $CURRENT_DIR/rabbitMQClient.env ]; then
    echo "Error: rabbitMQClient.env not found."
    exit 1
fi

source $CURRENT_DIR/rabbitMQClient.env

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
echo "Restarting rabbitmq-server.service."
echo "This will take a while..."
systemctl restart rabbitmq-server

# Using direct API calls to rabbitmq management
# This Grabs the api information overview of rabbitmq web management interface
# Pipe it to the jq command to make the output look pretty for user readability
# Although, it requires the jq command to be installed so I won't include that here.
echo "RabbitMQ API overview"
curl -u "$USER":"$PASSWORD" -X GET http://localhost:15672/api/overview | jq

# Create Exchange
echo "Creating Exchange"
curl -u "$USER:$PASSWORD" -H "content-type:application/json" \
    -X PUT "http://$BROKER_HOST:15672/api/exchanges/$VHOST/$EXCHANGE" \
    -d '{"type":"'"$EXCHANGE_TYPE"'","durable":true}'

# Create Queue
echo "Creating Queue"
curl -u "$USER:$PASSWORD" -H "content-type:application/json" \
    -X PUT "http://$BROKER_HOST:15672/api/queues/$VHOST/$QUEUE" \
    -d '{"durable":true}'

# Bind Queue to Exchange
echo "Binding Queue to Exchange"
curl -u "$USER:$PASSWORD" -H "content-type:application/json" \
    -X POST "http://$BROKER_HOST:15672/api/bindings/$VHOST/e/$EXCHANGE/q/$QUEUE" \
    -d '{"routing_key":"*"}'

# Show Exchange
echo "Showing Exchange: $EXCHANGE"
curl -u "$USER:$PASSWORD" -X GET "http://$BROKER_HOST:15672/api/exchanges/$VHOST/$EXCHANGE" | jq

# Show Queue
echo "Showing Queue: $QUEUE"
curl -u "$USER:$PASSWORD" -X GET "http://$BROKER_HOST:15672/api/queues/$VHOST/$QUEUE" | jq

echo "RabbitMQ setup completed for user '$USER' and vhost '$VHOST'."
exit 0