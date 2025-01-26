#!/bin/bash
if [[ -f "$1" && "$1" =~ \.java$ ]]; then
    javac "$1" && java "${1%.*}"
else
    echo "not a valid .java file."
fi

