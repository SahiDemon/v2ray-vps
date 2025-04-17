#!/bin/bash

# VPS-4-V2Ray Automated Installation Script for Ubuntu
echo "Automated Installation Script for Ubuntu"
echo "Made By SahiDemon"
# Request user input for email and domain
echo "Please enter your email address (for SSL certificate registration):"
read email
echo "Please enter your domain (e.g., host.mydomain.com):"
read domain

# Ensure the VPS is up-to-date
echo "Updating system packages..."
apt-get update -y && apt-get upgrade -y

# Restart the VPS
echo "Rebooting system..."
sudo reboot

# Install curl and socat
echo "Installing curl and socat..."
apt install curl socat -y

# Install Acme Script for SSL certificates
echo "Installing Acme.sh script for SSL certificates..."
curl https://get.acme.sh | sh

# Set default CA provider to Let’s Encrypt
echo "Setting default CA provider to Let's Encrypt..."
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# Register for a free SSL certificate
echo "Registering for SSL certificate with your email..."
~/.acme.sh/acme.sh --register-account -m $email

# Obtain SSL certificate
echo "Obtaining SSL certificate for your domain..."
~/.acme.sh/acme.sh --issue -d $domain --standalone

# Install the SSL certificate to permanent location
echo "Installing SSL certificate..."
~/.acme.sh/acme.sh --installcert -d $domain --key-file /root/private.key --fullchain-file /root/cert.crt

# Run X-UI Install Script for V2Ray
echo "Running X-UI install script..."
bash <(curl -Ls https://raw.githubusercontent.com/NidukaAkalanka/x-ui-english/master/install.sh)

# Display certificate locations
echo "SSL certificates installed:"
echo "Private key: /root/private.key"
echo "Certificate: /root/cert.crt"

# Script execution complete
echo "Installation complete! Your VPS is set up with V2Ray and SSL certificate."
