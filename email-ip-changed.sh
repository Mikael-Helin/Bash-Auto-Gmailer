#!/bin/bash

# Enable debugging (optional, can be removed later)
# set -x

# Set the data directory and files
DATA_DIR="/opt/myip/data"
DATA_FILE="$DATA_DIR/last_ip.txt"
EMAIL_FILE="$DATA_DIR/email.txt"

mkdir -p "$DATA_DIR" || { echo "Failed to create $DATA_DIR"; exit 1; }

# Check if the ssmtp package is installed
if ! command -v ssmtp &> /dev/null; then
    echo "ssmtp is not installed. Please install it using 'sudo apt install ssmtp'." >&2
    exit 1
fi

# Check if the curl package is installed
if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Please install it using 'sudo apt install curl'." >&2
    exit 1
fi

# Check if /etc/ssmtp/ssmtp.conf exists
if [ ! -f /etc/ssmtp/ssmtp.conf ]; then
    echo "Please use template ssmtp.conf to create the ssmtp.conf file." >&2
    exit 1
fi

# Function to trim a string
trim() {
    echo "$1" | tr -d '[:space:]' | tr -d '\n' | tr -d '\r'
}

# Function for logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if the email address file exists
if [ ! -f "$EMAIL_FILE" ]; then
    log "Email address file not found. Please create the file $EMAIL_FILE containing your email address." >&2
    exit 1
fi

# Read and trim the email
EMAIL=$(cat "$EMAIL_FILE" 2>/dev/null) || { log "Failed to read email file"; exit 1; }
EMAIL=$(trim "$EMAIL")

# Get the hostname
HOSTNAME=$(hostname -f)

# Function to get the current public IP
get_current_ip() {
    IP=$(curl -s https://api.ipify.org)
    echo "$(trim "$IP")"
}

# Function to read the last known IP
get_last_ip() {
    if [ -f "$DATA_FILE" ]; then
        IP=$(cat "$DATA_FILE" 2>/dev/null)
        echo "$(trim "$IP")"
    else
        echo ""
    fi
}

# If last IP file does not exist then create it
if [ ! -f "$DATA_FILE" ]; then
    log "Creating $DATA_FILE"
    LAST_IP=$(get_current_ip)
    echo "$LAST_IP" > "$DATA_FILE" || { log "Failed to create $DATA_FILE"; exit 1; }
fi

# Set up a trap to handle exit
trap "log 'Shutting down...'; exit 0" SIGINT SIGTERM

while true; do
    log "Checking current IP..."
    CURRENT_IP=$(get_current_ip)
    
    if [ -z "$CURRENT_IP" ]; then
        log "Current IP is empty, waiting 1 hour before retry."
        sleep 3600
        continue
    fi

    LAST_IP=$(get_last_ip)
    
    if [ -z "$LAST_IP" ]; then
        log "No last IP found, inserting current IP."
        echo "$CURRENT_IP" > "$DATA_FILE" || { log "Failed to write to $DATA_FILE"; exit 1; }
        sleep 3600
        continue
    fi

    if [ "$CURRENT_IP" != "$LAST_IP" ]; then
        log "IP has changed from $LAST_IP to $CURRENT_IP. Updating $DATA_FILE and sending email."
        echo "$CURRENT_IP" > "$DATA_FILE" || { log "Failed to write to $DATA_FILE"; exit 1; }

        echo -e "Subject: IP Address for $HOSTNAME has changed\n\nThe new IP address is: $CURRENT_IP" | ssmtp -v "$EMAIL"
        
        if [ $? -ne 0 ]; then
            log "Failed to send email"
            exit 1
        fi
    fi
    sleep 3600
done
