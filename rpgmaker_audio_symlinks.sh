#!/bin/bash

# directory to search for audio files
AUDIO_DIR="./audio"

create_case_symlinks() {
    local dir="$1"
    local count=0
    
    # process each file in the directory
    find "$dir" -type f -name "*.rpgmvo" | while read -r file; do
        base_dir=$(dirname "$file")
        filename=$(basename "$file")
        filename_lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
        
        for i in $(seq 0 $((${#filename}-1))); do
            char="${filename:$i:1}"
            if [[ "$char" =~ [a-zA-Z] ]]; then
                if [[ "$char" =~ [a-z] ]]; then
                    # If lowercase, create uppercase variant
                    upper_char=$(echo "$char" | tr '[:lower:]' '[:upper:]')
                    variant="${filename:0:$i}${upper_char}${filename:$(($i+1))}"
                    if [ "$variant" != "$filename" ] && [ ! -f "$base_dir/$variant" ]; then
                        echo "Creating symlink: $base_dir/$variant -> $filename"
                        ln -sf "$filename" "$base_dir/$variant"
                        count=$((count+1))
                    fi
                else
                    # If uppercase, create lowercase variant
                    lower_char=$(echo "$char" | tr '[:upper:]' '[:lower:]')
                    variant="${filename:0:$i}${lower_char}${filename:$(($i+1))}"
                    if [ "$variant" != "$filename" ] && [ ! -f "$base_dir/$variant" ]; then
                        echo "Creating symlink: $base_dir/$variant -> $filename"
                        ln -sf "$filename" "$base_dir/$variant"
                        count=$((count+1))
                    fi
                fi
            fi
        done
    done
    
    echo "Created $count symlinks in $dir"
}

# process all audio directories
echo "Processing BGM directory..."
create_case_symlinks "$AUDIO_DIR/bgm"
echo "Processing BGS directory..."
create_case_symlinks "$AUDIO_DIR/bgs"
echo "Processing ME directory..."
create_case_symlinks "$AUDIO_DIR/me"
echo "Processing SE directory..."
create_case_symlinks "$AUDIO_DIR/se"

echo "Finished!"
