#!/bin/bash

intro="I... AM... INEVITABLE"

for (( i=0; i<${#intro}; i++ )); do
    echo -n "${intro:$i:1}"
    sleep 0.2
done
exit 0