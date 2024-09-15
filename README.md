## Bash Auto Gmailer

Configure a Bash script that takes the public IP, checks if it changed, and if it changed, then emails the IP update.

We assume that Gmail is used for sending the emails.

### **1. Create a Script to Check Public IP Address**

You can use a simple Bash script that:

- Retrieves the current public IP.
- Compares it with the last recorded IP.
- Sends an email if the IP has changed.

**Script:**

Move the email-ip-changed.sh file to /opt/myip/

```bash
mkdir -p /opt/myip/
cp email-ip-changed.sh /opt/myip/email-ip-changed.sh
chmod +x /opt/myip/email-ip-changed.sh
```

### **2. Configure Email Sending via Gmail**

To send emails through your Gmail account, you need to configure an SMTP client like `ssmtp` or `msmtp`.

#### **Install `ssmtp`**

```bash
sudo apt-get update
sudo apt-get install ssmtp curl
```

#### **Configure `ssmtp`**

Edit the configuration file `/etc/ssmtp/ssmtp.conf`:

```ini
root=FROM_EMAIL
mailhub=smtp.gmail.com:587
AuthUser=mikael.gummo@gmail.com
AuthPass=YOUR_APP_PASSWORD
UseSTARTTLS=YES
UseTLS=YES
FromLineOverride=YES
```

**Important:**

- **App Password:** Since Google now requires OAuth 2.0 for authentication, you need to create an **App Password**.

  - Go to [Google Account Security](https://myaccount.google.com/security).
  - Under "Signing in to Google," select **App Passwords**.
  - Generate a new app password for "Mail" or "Other (Custom name)."
  - Use this app password in the `AuthPass` field.

#### **Set Correct Permissions**

Ensure the `ssmtp.conf` file is only readable by root to protect your credentials:

```bash
sudo chmod 640 /etc/ssmtp/ssmtp.conf
```

### **3. Test Email Sending**

Before automating, test if you can send an email:

```bash
echo -e "Subject: Test Email\n\nThis is a test email." | ssmtp -v mikaelhelin@yahoo.com
```

- Check your Yahoo inbox to confirm receipt.
- If there are issues, run the command with `-v` for verbose output to debug.

### **4. Schedule the Script with Cron**

Set up a cron job to run the script daily.

#### **Edit Crontab**

```bash
crontab -e
```

#### **Add Cron Entry**

To run the script every day at 5:00 AM:

```cron
0 5 * * * /opt/myip/email-ip-changed.sh
```

### **5. Optional: Logging**

For debugging and logging purposes, you might want to redirect output to a log file.

Modify the cron entry:

```cron
0 5 * * * /opt/myip/email-ip-changed.sh >> /opt/myip/myip.log 2>&1
```

### **6. Consider Using Duck DNS**

Instead or in addition to emailing yourself the updated IP address, using a Dynamic DNS service can automatically map a domain name to your changing IP address.

    https://www.duckdns.org/domains

### **7. Security Considerations**

- **Protect Credentials:** Never expose your Gmail password. Using an app password mitigates risks.
- **Firewall Settings:** Ensure that outgoing connections to `smtp.gmail.com` on port `587` are allowed.
- **Two-Factor Authentication:** Always enable 2FA on your accounts for added security.

### **8. Troubleshooting**

- **Email Not Sent:**

  - Check internet connectivity.
  - Verify SMTP settings in `ssmtp.conf`.
  - Look into `/var/log/mail.log` or `/var/log/syslog` for errors.

- **Cron Job Issues:**

  - Ensure the script runs properly manually.
  - Check cron logs for any errors.
  - Make sure paths in the script are absolute, not relative.

### **Summary**

- **Script:** Monitors IP changes and triggers email notifications.
- **Email Configuration:** Uses `ssmtp` to send emails via Gmail's SMTP server.
- **Automation:** Cron schedules daily checks.
- **Alternative Solution:** Dynamic DNS offers a more seamless way to handle dynamic IPs.
