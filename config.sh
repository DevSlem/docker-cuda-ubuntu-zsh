#!/bin/bash

read -p "Enter user name (empty is $USER): " USER_NAME
USER_NAME=${USER_NAME:-$USER}

read -p "Enter SSH port for Docker container: " SSH_PORT
# Check whether the port is already in use
while ss -tuln | grep ":$SSH_PORT" > /dev/null; do
    echo "Port $SSH_PORT is already in use. Please choose a different port."
    read -p "Enter SSH port for Docker container: " SSH_PORT
done

VERSION=$(cat .version | tr -d ' \t\n\r')

echo "User name: $USER_NAME, SSH port: $SSH_PORT, Version: $VERSION"
read -p "Is this correct? (y/n): " REPLY

if [[ "$REPLY" == "n" || "$REPLY" == "N" ]]; then
    echo "Exiting."
    exit 1
fi

mkdir -p ~/workspace
cp docker-compose-template.yml docker-compose.yml

sed -i "s/<USER_NAME>/$USER_NAME/g" docker-compose.yml
sed -i "s/<HOST_PORT>/$SSH_PORT/g" docker-compose.yml
sed -i "s/<VERSION>/$VERSION/g" docker-compose.yml

echo "Configuration complete. You can now start the $USER_NAME.ai-dev-env-base container by following commands:"
echo
echo "export SSH_PUBLIC_KEY=\"<YOUR_SSH_PUBLIC_KEYS>\""
echo "docker compose up --build -d"
echo