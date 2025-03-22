#!/bin/bash

# Secure File Exchange Script for Arch Linux
# This script allows secure file transfer within the same network using different methods

# Configuration
PORT=8888
TRANSFER_DIR="$HOME/secure_transfer"
LOG_FILE="$TRANSFER_DIR/transfer.log"

# Check for dependencies
check_dependencies() {
    local deps=("netcat" "openssl" "python" "rsync" "ssh")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "Missing dependencies: ${missing[*]}"
        echo "Install them with: sudo pacman -S ${missing[*]}"
        exit 1
    fi
}

# Create transfer directory if it doesn't exist
setup_environment() {
    mkdir -p "$TRANSFER_DIR"
    chmod 700 "$TRANSFER_DIR"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
    echo "$(date): Secure file exchange initialized" >> "$LOG_FILE"
}

# Log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
    echo "$1"
}

# Simple HTTP server with Python
start_python_server() {
    cd "$TRANSFER_DIR" || exit 1
    log_message "Starting Python HTTP server on port $PORT"
    log_message "Access files at http://$(hostname -I | awk '{print $1}'):$PORT"
    python -m http.server "$PORT"
}

# Secure file sending with Netcat and OpenSSL
send_file_nc() {
    if [ $# -lt 2 ]; then
        echo "Usage: $0 send_nc <target_ip> <file_path>"
        return 1
    fi
    
    local target="$1"
    local file="$2"
    
    if [ ! -f "$file" ]; then
        log_message "Error: File not found: $file"
        return 1
    fi
    
    local filename=$(basename "$file")
    log_message "Sending file $filename to $target:$PORT using Netcat+OpenSSL"
    
    # Generate a random password for encryption
    local password=$(openssl rand -base64 32)
    echo "Encryption password: $password"
    echo "Share this password with the recipient via a secure channel!"
    
    # Encrypt and send the file
    openssl enc -aes-256-cbc -salt -pass pass:"$password" -in "$file" | nc -N "$target" "$PORT"
    
    log_message "File $filename sent to $target:$PORT"
}

# Receive file with Netcat and OpenSSL
receive_file_nc() {
    if [ $# -lt 2 ]; then
        echo "Usage: $0 receive_nc <output_file> <password>"
        return 1
    fi
    
    local output="$1"
    local password="$2"
    
    log_message "Waiting to receive encrypted file on port $PORT"
    echo "Listening on port $PORT... Press Ctrl+C to cancel"
    
    nc -l -p "$PORT" | openssl enc -aes-256-cbc -d -salt -pass pass:"$password" > "$TRANSFER_DIR/$output"
    
    log_message "File received and saved as $TRANSFER_DIR/$output"
}

# Send files using rsync over SSH
send_rsync_ssh() {
    if [ $# -lt 3 ]; then
        echo "Usage: $0 send_rsync <user> <target_ip> <file_path>"
        return 1
    fi
    
    local user="$1"
    local target="$2"
    local file="$3"
    
    if [ ! -e "$file" ]; then
        log_message "Error: File or directory not found: $file"
        return 1
    fi
    
    log_message "Sending $file to $user@$target:$TRANSFER_DIR using rsync+ssh"
    rsync -avz --progress -e ssh "$file" "$user@$target:$TRANSFER_DIR"
    
    log_message "Transfer to $user@$target completed"
}

# Show local IP address
show_ip() {
    echo "Your local IP address:"
    ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1
}

# Display usage instructions
show_help() {
    echo "Secure File Exchange Script for Arch Linux"
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  server          - Start a simple HTTP server for downloading files"
    echo "  send_nc <ip> <file>        - Send file using Netcat+OpenSSL"
    echo "  receive_nc <outfile> <password> - Receive file using Netcat+OpenSSL"
    echo "  send_rsync <user> <ip> <file>   - Send file using rsync+ssh"
    echo "  ip              - Show your local IP address"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 server              # Start file server"
    echo "  $0 send_nc 192.168.1.5 ~/document.pdf"
    echo "  $0 receive_nc received_file.pdf \"your_password\""
    echo "  $0 send_rsync john 192.168.1.5 ~/documents/"
}

# Main execution
check_dependencies
setup_environment

case "$1" in
    server)
        start_python_server
        ;;
    send_nc)
        send_file_nc "$2" "$3"
        ;;
    receive_nc)
        receive_file_nc "$2" "$3"
        ;;
    send_rsync)
        send_rsync_ssh "$2" "$3" "$4"
        ;;
    ip)
        show_ip
        ;;
    help|*)
        show_help
        ;;
esac
