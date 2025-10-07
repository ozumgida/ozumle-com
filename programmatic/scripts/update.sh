#!/bin/bash

echo "Starting update process..."
echo "Current date and time (UTC): $(date -u '+%Y-%m-%d %H:%M:%S')"
echo "Running as user: $(whoami)"

SCRIPTS=("create-pages.sh" "create-products.sh" "merge-js.sh")

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "Setting executable permissions for $script"
        chmod +x "$script"
    else
        echo "Error: $script not found in current directory."
        exit 1
    fi
done

for script in "${SCRIPTS[@]}"; do
    echo ""
    echo "Running $script..."
    if ./"$script"; then
        echo "$script completed successfully."
    else
        echo "Error: $script failed with exit code $?."
        exit 1
    fi
done

echo ""
echo "Update process completed successfully!"
exit 0