#!/bin/bash

# Start and enable apache2
echo "Starting and enabling Apache2..."
systemctl start apache2
systemctl enable apache2

echo "Checking Apache status..."
systemctl status apache2 --no-pager

# Final configuration test and restart
echo "Testing Apache configuration..."
apache2ctl configtest

echo "Restarting Apache to apply changes..."
systemctl restart apache2

echo "Apache2 setup complete!"
exit 0
