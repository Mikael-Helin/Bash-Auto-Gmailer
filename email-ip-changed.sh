#!/bin/bash

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
mkdir ~/.myip
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
mkdir -p ~/.myip
IP_FILE="~/.myip/last_ip.txt"

# Get current public IP
CURRENT_IP=$(curl -s https://api.ipify.org)

# If IP_FILE does not exist, create it
touch "$IP_FILE"

# Read the last known IP
if [ -f "$IP_FILE" ]; then
    LAST_IP=$(cat "$IP_FILE")
else
    LAST_IP=""
fi

# Compare IPs
if [ "$CURRENT_IP" != "$LAST_IP" ]; then
    # Save the new IP
    echo "$CURRENT_IP" > "$IP_FILE"

    # Get the hostname
    HOSTNAME=$(hostname -f)

    # Read the target email address
    EMAIL=$(cat ~/.myip/email.txt)

    # Send an email notification
    echo "Subject: IP Address for $HOSTNAME has changed\n\nThe new IP address is: $CURRENT_IP"
    echo -e "Subject: IP Address for $HOSTNAME has changed\n\nThe new IP address is: $CURRENT_IP" | ssmtp -v "$EMAIL"
fi

# Sleep for 60 minutes and run the script again
sleep 3600
exec "$0"
