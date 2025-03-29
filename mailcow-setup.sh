#!/bin/bash

# Ask for FQDN (mail.yourdomain.com)
read -p "Enter FQDN for Mailcow (e.g. mail.example.com): " FQDN

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl wget sudo gnupg2 apt-transport-https software-properties-common net-tools lsb-release ca-certificates git

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    newgrp docker
else
    echo "Docker is already installed."
fi

# Check for Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."
    LATEST_COMPOSE=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url | grep "docker-compose-$(uname -s)-$(uname -m)" | cut -d '"' -f 4)
    sudo curl -L "$LATEST_COMPOSE" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Clone mailcow repo
cd /opt
sudo git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized

# Generate config
sudo cp mailcow.conf.example mailcow.conf
sudo sed -i "s/^MAILCOW_HOSTNAME=.*/MAILCOW_HOSTNAME=$FQDN/" mailcow.conf

# Pull Mailcow Docker images
sudo ./generate_config.sh
sudo docker compose pull

# Start Mailcow
sudo docker compose up -d

# Show success message
echo -e "\n✅ Mailcow is being set up."
echo "Access the web UI at: https://$FQDN (admin login created during first web login)"
echo "Make sure DNS A + MX records point to: $FQDN"
