#!/bin/bash

# Check for root access
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Prompt for domain information
echo "Enter your domain (e.g., example.com, without www):"
read DOMAIN

echo "Include www.$DOMAIN in the certificate? (y/n):"
read WWW_CONFIRM

if [ "$WWW_CONFIRM" == "y" ]; then
  DOMAINS="-d $DOMAIN -d www.$DOMAIN"
else
  DOMAINS="-d $DOMAIN"
fi

# Install Certbot and dependencies
echo "Installing Certbot and required dependencies..."
if [ -x "$(command -v apt)" ]; then
  apt update && apt install -y certbot python3-certbot-nginx
elif [ -x "$(command -v yum)" ]; then
  yum install -y epel-release && yum install -y certbot python3-certbot-nginx
else
  echo "Unsupported package manager. Please install Certbot manually."
  exit 1
fi

# Detect web server
if [ -x "$(command -v nginx)" ]; then
  WEBSERVER="nginx"
elif [ -x "$(command -v apache2)" ]; then
  WEBSERVER="apache"
else
  echo "Web server not detected. Please install Nginx or Apache."
  exit 1
fi

# Issue SSL certificate
echo "Issuing SSL certificate for $DOMAIN..."
if [ "$WEBSERVER" == "nginx" ]; then
  certbot --nginx $DOMAINS --non-interactive --agree-tos -m admin@$DOMAIN
elif [ "$WEBSERVER" == "apache" ]; then
  certbot --apache $DOMAINS --non-interactive --agree-tos -m admin@$DOMAIN
fi

# Check if Certbot succeeded
if [ $? -ne 0 ]; then
  echo "Certbot failed to issue the certificate. Please check your domain's DNS settings or web server configuration."
  exit 1
fi

# Add Cron Job for auto-renewal
echo "Setting up auto-renewal..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet") | crontab -

# Final message
echo "SSL certificate successfully installed and configured for $DOMAIN."
echo "You can now visit your site at https://$DOMAIN."
