#!/bin/bash

systemctl status corekeeper-server.service --no-pager > /var/www/html/service-status.txt
