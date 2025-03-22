#!/bin/bash

# run-python
# Script to automatically source a Python virtual environment and run a Python script
# Usage: run-python <python_file.py> [arguments]

# Configuration - modify this to match your virtual environment path
VENV_PATH="$HOME/my-venv"

# Function to show script usage
show_usage() {
    echo "Usage: $0 <python_file.py> [arguments]"
    echo "Runs a Python script within the virtual environment at $VENV_PATH"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -e, --env PATH Specify a different virtual environment path"
    echo ""
    echo "Examples:"
    echo "  $0 script.py"
    echo "  $0 script.py arg1 arg2"
    echo "  $0 -e ~/other-venv script.py"
}

# Process command line arguments for help and environment options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -e|--env)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: Missing virtual environment path after $1 option"
                exit 1
            fi
            VENV_PATH="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Check if a Python file was provided
if [[ $# -eq 0 ]]; then
    echo "Error: No Python file specified"
    show_usage
    exit 1
fi

PYTHON_FILE="$1"
shift  # Remove the Python file from the arguments list

# Check if the Python file exists
if [[ ! -f "$PYTHON_FILE" ]]; then
    echo "Error: Python file '$PYTHON_FILE' not found"
    exit 1
fi

# Check if the virtual environment exists
if [[ ! -d "$VENV_PATH" ]]; then
    echo "Error: Virtual environment directory '$VENV_PATH' not found"
    exit 1
fi

# Check if the activation script exists
ACTIVATE_SCRIPT="$VENV_PATH/bin/activate"
if [[ ! -f "$ACTIVATE_SCRIPT" ]]; then
    echo "Error: Activation script not found at '$ACTIVATE_SCRIPT'"
    exit 1
fi

# Source the virtual environment and run the Python file
echo "Activating virtual environment: $VENV_PATH"
source "$ACTIVATE_SCRIPT"

# Check if activation was successful
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "Error: Failed to activate virtual environment"
    exit 1
fi

echo "Running: python $PYTHON_FILE $@"
python "$PYTHON_FILE" "$@"

# Store the exit status
EXIT_STATUS=$?

# Deactivate the virtual environment
deactivate 2>/dev/null

echo "Python script completed with exit status: $EXIT_STATUS"
exit $EXIT_STATUS
