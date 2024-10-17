#!/bin/bash

# A little intro for the ultimate snap
# Add echo with a loop to read out a string separated by 2 seconds each

intro="I... AM.... INEVITABLE!"

# Loop through the string
for (( i=0; i<${#intro}; i++ )); do
    echo -n "${intro:$i:1}"
    sleep 0.3
done
echo -e "\n"
exit 0