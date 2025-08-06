#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SCRIPT_SELF="$(realpath "$0")"

# Execute each script (except the runner itself)
for script in "$SCRIPT_DIR"/*.sh; do
    SCRIPT_PATH="$(realpath "$script")"

    # Skip this script
    [ "$SCRIPT_PATH" == "$SCRIPT_SELF" ] && continue
    # Skip if not executable
    if [ ! -x "$SCRIPT_PATH" ]; then
        continue
    fi
    "$SCRIPT_PATH"
done
