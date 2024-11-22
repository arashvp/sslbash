#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Step 1: Ask for the domain name
echo "Enter your domain name (e.g., example.com):"
read DOMAIN

echo "Include www.$DOMAIN in the certificate? (y/n):"
read INCLUDE_WWW

# Configure domains for Certbot
if [ "$INCLUDE_WWW" == "y" ]; then
  DOMAINS="-d $DOMAIN -d www.$DOMAIN"
else
  DOMAINS="-d $DOMAIN"
fi

# Step 2: Update and install required packages
echo "Installing Certbot and dependencies..."
if [ -x "$(command -v apt)" ]; then
  apt update
  apt install -y certbot python3-certbot-apache
else
  echo "This script supports only Debian/Ubuntu systems with apt package manager."
  exit 1
fi

# Step 3: Check if Apache2 is installed
if ! [ -x "$(command -v apache2)" ]; then
  echo "Apache2 is not installed. Installing Apache2..."
  apt install -y apache2
  systemctl start apache2
  systemctl enable apache2
fi

# Step 4: Obtain SSL certificate
echo "Obtaining SSL certificate for $DOMAIN..."
certbot --apache $DOMAINS --non-interactive --agree-tos -m admin@$DOMAIN

# Step 5: Verify SSL installation
if [ $? -eq 0 ]; then
  echo "SSL certificate installed successfully for $DOMAIN."
else
  echo "Failed to install SSL certificate. Please check the Certbot output for errors."
  exit 1
fi

# Step 6: Set up automatic SSL renewal
echo "Setting up automatic SSL renewal..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --apache") | crontab -

# Step 7: Restart Apache2 to apply changes
echo "Restarting Apache2 to apply SSL configuration..."
systemctl restart apache2

# Final message
echo "SSL setup is complete. Visit your site at https://$DOMAIN to verify."
