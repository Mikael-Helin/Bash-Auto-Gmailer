#!/bin/bash

# Enable debugging (optional, can be removed later)
set -x

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

# Check if the email address file exists
mkdir -p ~/.myip
if [ ! -f ~/.myip/email.txt ]; then
    echo "Email address file not found. Please create a file named 'email.txt' in the '~/.myip' directory with your email address." >&2
    exit 1
fi

# Check if /etc/ssmtp/ssmtp.conf exists
if [ ! -f /etc/ssmtp/ssmtp.conf ]; then
    echo "Please use template.ssmtp.conf to create the /etc/ssmtp/ssmtp.conf file." >&2
    exit 1
fi

# File to store the last known IP
IP_FILE="$HOME/.myip/last_ip.txt"

# If IP_FILE does not exist, create it
if [ ! -f "$IP_FILE" ]; then
    echo "Creating $IP_FILE"
    touch "$IP_FILE" || { echo "Failed to create $IP_FILE"; exit 1; }
fi

# Get the hostname
HOSTNAME=$(hostname -f)

# Read the target email address
EMAIL=$(cat ~/.myip/email.txt)

while true; do
    # Get current public IP
    CURRENT_IP=$(curl -s https://api.ipify.org)
    echo "Current IP: $CURRENT_IP"

    # Trim any extra whitespace (just in case)
    CURRENT_IP=$(echo "$CURRENT_IP" | tr -d '[:space:]')

    # Read the last known IP, trimming whitespace
    LAST_IP=$(cat "$IP_FILE" | tr -d '\n\r[:space:]')
    echo "Last IP: $LAST_IP"

    # Compare IPs
    if [ "$CURRENT_IP" != "$LAST_IP" ]; then
        echo "IP has changed. Updating $IP_FILE"
        # Save the new IP
        echo "$CURRENT_IP" > "$IP_FILE" || { echo "Failed to write to $IP_FILE"; exit 1; }

        # Send an email notification
        echo -e "Subject: IP Address for $HOSTNAME has changed\n\nThe new IP address is: $CURRENT_IP" | ssmtp -v "$EMAIL"
    else
        echo "IP has not changed"
    fi

    # Sleep for 60 minutes before checking again
    sleep 3600
done
