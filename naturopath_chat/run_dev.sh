#!/bin/bash
echo "Starting the Naturopath Chat Flask development server..."
echo "Access the application at http://127.0.0.1:5000"

# Check if python3 is available, otherwise use python
PYTHON_CMD=python3
if ! command -v python3 &> /dev/null
then
    PYTHON_CMD=python
fi

# Assuming app.py is in the same directory as the script
# or adjust path accordingly if run from project root.
# This script is intended to be in the naturopath_chat directory.
"$PYTHON_CMD" app.py
