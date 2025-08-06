#!/bin/bash

apt update -qq

apt list --upgradable 2>/dev/null | tail -n +2 > /var/log/apt-upgrades.log

if [ -s /var/log/apt-upgrades.log ]; then
    sed -i 's/Up to date/Updates Available/' /var/www/html/update-status.txt
else
    sed -i 's/Updates Available/Up to date/' /var/www/html/update-status.txt
fi
