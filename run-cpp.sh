#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <filename.cpp>"
    exit 1
fi

filename="${1%.cpp}"

# Compile the C++ file
g++ "$1" -o "$filename"
if [ $? -eq 0 ]; then
    echo "Compilation successful. Running program..."
    ./"$filename"
else
    echo "Compilation failed."
fi

