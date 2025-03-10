#!/bin/bash

# Use the current working directory as the project directory.
PROJECT_DIR="$(pwd)"

# Check if CMakeLists.txt exists in the current directory.
if [[ ! -f "$PROJECT_DIR/CMakeLists.txt" ]]; then
    echo "Error: No CMake project found in $PROJECT_DIR (CMakeLists.txt missing)"
    exit 1
fi

# Create a build directory if it doesn't exist.
if [[ ! -d "$PROJECT_DIR/build" ]]; then
    mkdir "$PROJECT_DIR/build"
fi

echo "Building the project..."

# Navigate to the build directory.
cd "$PROJECT_DIR/build" || { echo "Failed to change directory to build."; exit 1; }

# Run CMake to generate build files.
cmake .. || { echo "CMake configuration failed."; exit 1; }

# Build the project.
cmake --build . || { echo "Build failed."; exit 1; }

# Find all executables in the build directory.
EXECUTABLES=($(find . -maxdepth 1 -type f -executable))

# If no executables were found.
if [[ ${#EXECUTABLES[@]} -eq 0 ]]; then
    echo "No executable found in the build directory."
    exit 1
fi

# ✅ CASE 1: If only one executable, just run it.
if [[ ${#EXECUTABLES[@]} -eq 1 ]]; then
    echo "Build successful."
    echo "Running executable: ${EXECUTABLES[0]}"
    ./"${EXECUTABLES[0]}"
    exit 0
fi

# ✅ CASE 2: If multiple executables, show a selection menu.
echo "Build successful."
echo "Multiple executables found:"
for i in "${!EXECUTABLES[@]}"; do
    echo "[$((i+1))] ${EXECUTABLES[$i]}"
done

# Ask the user to choose which executable to run.
read -p "Choose an executable to run [1-${#EXECUTABLES[@]}]: " CHOICE

# Validate the choice
if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#EXECUTABLES[@]} )); then
    EXE="${EXECUTABLES[$((CHOICE-1))]}"
    echo "Running: $EXE"
    ./"$EXE"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

