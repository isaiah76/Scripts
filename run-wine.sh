#!/bin/bash

# Comprehensive Wine game launcher script
# Usage: ./run_wine.sh [executable_name] [options]

# Show help if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [executable_name] [options]"
    echo "Options:"
    echo "  --wine32      Use 32-bit Wine prefix (~/wine32)"
    echo "  --jp    Use Japanese locale"
    echo "  --gamescope   Use gamescope with optimal settings"
    echo ""
    echo "Examples:"
    echo "  $0 Game.exe"
    echo "  $0 Game.exe --wine32 --jp"
    echo "  $0 Game.exe --gamescope"
    echo "  $0 Game.exe --wine32 --jp --gamescope"
    exit 1
fi

# Get executable name from first argument
EXECUTABLE_NAME="$1"
shift

# Look for the executable in the current directory
EXECUTABLE="$(pwd)/$EXECUTABLE_NAME"

# Check if executable exists
if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Executable not found in current directory: $EXECUTABLE_NAME"
    exit 1
fi

# Default settings
USE_WINE32=false
USE_JAPANESE=false
USE_GAMESCOPE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --wine32)
            USE_WINE32=true
            ;;
        --jp)
            USE_JAPANESE=true
            ;;
        --gamescope)
            USE_GAMESCOPE=true
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

# Build command
CMD=""

# Add Wine prefix if needed
if [ "$USE_WINE32" = true ]; then
    CMD="WINEPREFIX=~/wine32 "
fi

# Add Japanese locale if needed
if [ "$USE_JAPANESE" = true ]; then
    CMD="${CMD}LANG=ja_JP.UTF-8 "
fi

# Add gamescope if needed
if [ "$USE_GAMESCOPE" = true ]; then
    CMD="${CMD}gamescope -f -r 60 -S integer -F nearest -- "
fi

# Add wine command with the executable
CMD="${CMD}wine \"$EXECUTABLE\""

# Print and execute command
echo "Executing: $CMD"
eval "$CMD"
