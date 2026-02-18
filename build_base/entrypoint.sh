#!/bin/bash

# SSH key authentication for the container executer
mkdir -p /root/.ssh
echo "${SSH_PUBLIC_KEY}" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh

# Start SSH server   
/usr/sbin/sshd -D &
zsh
exec "$@"