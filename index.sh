#!/bin/bash

# Check if the tree command is installed
if ! command -v tree &> /dev/null
then
    echo "tree command not found. Installing..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install tree
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install tree
    else
        echo "Please install the tree command manually."
        exit 1
    fi
fi

# Get the current directory
REPO_DIR=$(pwd)

# Output the directory structure
echo "Indexing repository at $REPO_DIR"
tree -a -I '.git|node_modules|vendor' > INDEX

# Display the directory structure
cat INDEX
