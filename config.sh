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

# Automatically mount external disks if available
# Get volume list from docker volume ls
volume_name_list=()
volume_device_list=()
read -p "Do you want to bind volumes to the container? (y/n): " REPLY
if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
    volume_list=$(docker volume ls --format '{{.Name}}')
    for vol in $volume_list; do
        device_path=$(docker volume inspect "$vol" --format '{{.Options.device}}')
        # <no value> means the volume is not binded to any device
        if [[ "$device_path" != "<no value>" ]]; then
            read -p "volume: '$vol', mount point: '$device_path', bind to container? (y/n): " REPLY
            if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
                volume_name_list+=("$vol")
                volume_device_list+=("$device_path")
            fi
        fi
    done
fi

mkdir -p ~/workspace
cp docker-compose-template.yml docker-compose.yml

sed -i "s/<USER_NAME>/$USER_NAME/g" docker-compose.yml
sed -i "s/<HOST_PORT>/$SSH_PORT/g" docker-compose.yml
sed -i "s/<VERSION>/$VERSION/g" docker-compose.yml

if [ ${#volume_name_list[@]} -gt 0 ]; then
    sed -i "\$a volumes:" docker-compose.yml
    for i in "${!volume_name_list[@]}"; do
        vol_name=${volume_name_list[$i]}
        vol_device=${volume_device_list[$i]}
        sed -i "/# - external-disk1:\/mnt\/data1 # bind external disk to container/a \      - $vol_name:$vol_device" docker-compose.yml
        sed -i "\$a \  $vol_name:" docker-compose.yml
        sed -i "\$a \    external: true" docker-compose.yml
    done
    echo "${#volume_name_list[@]} external disks will be bound to the container."
else
    echo "No external disks to bind."
fi

echo
echo "Configuration complete. You can now start the $USER_NAME.ai-dev-env-base container by following commands:"
echo
echo "export SSH_PUBLIC_KEY=\"<YOUR_SSH_PUBLIC_KEYS>\""
echo "docker compose up --build -d"
echo