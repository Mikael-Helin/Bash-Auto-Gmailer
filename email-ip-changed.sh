#!/bin/bash

# Enable debugging (optional, can be removed later)
# set -x

# Set the data directory and files
DATA_DIR="/opt/myip/data"
DATA_FILE="$DATA_DIR/last_ip.txt"
EMAIL_FILE="$DATA_DIR/email.txt"

mkdir -p $DATA_DIR

# Check if the /usr/sbin/ssmtp package is installed
if ! command -v /usr/sbin/ssmtp &> /dev/null; then
    echo "/usr/sbin/ssmtp is not installed. Please install it using 'sudo apt install /usr/sbin/ssmtp'." >&2
    exit 1
fi

# Check if the curl package is installed
if ! command -v /usr/bin/curl &> /dev/null; then
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
    S="$1"
    S=$(echo "$S" | tr -d '[:space:]')
    S=$(echo "$S" | tr -d '\n')
    S=$(echo "$S" | tr -d '\r')
    echo "$S"
}

# Check if the email address file exists
if [ ! -f $EMAIL_FILE ]; then
    echo "Email address file not found. Please create the file $EMAIL_FILE containing your email address." >&2
    exit 1
fi
EMAIL=$(cat "$EMAIL_FILE")
EMAIL=$(trim "$EMAIL")

# Get the hostname
HOSTNAME=$(hostname -f)

# Function to get the current public IP
get_current_ip() {
    IP=$(/usr/bin/curl -s https://api.ipify.org)
    IP=$(trim "$IP")
    echo "$IP"
}

# Function to read the last known IP
get_last_ip() {
    IP=$(cat "$DATA_FILE")
    IP=$(trim "$IP")
    echo "$IP"
}

# If last IP file does not exist then create it
if [ ! -f "$DATA_FILE" ]; then
    echo "Creating $DATA_FILE"
    LAST_IP=$(get_current_ip)
    LAST_IP=$(trim "$LAST_IP")
    echo "$LAST_IP" > "$DATA_FILE" || { echo "Failed to create $DATA_FILE"; exit 1; }
fi

while true; do
    # Get the current IP, if it is empty then wait for 1 hour and try again
    CURRENT_IP=$(get_current_ip)
    if [ -z "$CURRENT_IP" ]; then
        sleep 3600
        continue
    fi
    # Get the last IP, if it is empty then insert the current IP and wait for 1 hour
    LAST_IP=$(get_last_ip)
    if [ -z "$LAST_IP" ]; then
        echo "Inserting current IP into $DATA_FILE"
        echo "$CURRENT_IP" > "$DATA_FILE" || { echo "Failed to write to $DATA_FILE"; exit 1; }
        sleep 3600
        continue
    fi
    # If the current IP is different from the last IP, then update the last IP and send an email
    if [ "$CURRENT_IP" != "$LAST_IP" ]; then
        echo "IP has changed. Updating $DATA_FILE"
        echo "$CURRENT_IP" > "$DATA_FILE" || { echo "Failed to write to $DATA_FILE"; exit 1; }

        echo -e "Subject: IP Address for $HOSTNAME has changed\n\nThe new IP address is: $CURRENT_IP" | /usr/sbin/ssmtp -v "$EMAIL"
        if [ $? -ne 0 ]; then
            echo "Failed to send email"
            exit 1
        fi
    fi
    sleep 3600
done
