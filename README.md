# Docker for CUDA Available Ubuntu with ZSH Shell

This repository provides Docker files for CUDA availalbe Ubuntu OS with ZSH shell.

For each version of Ubuntu, there are two Dockerfiles with different dependencies:

1. `cuda12.8.1-ubuntu22.04-zsh/Dockerfile`
2. `cuda11.3.1-ubuntu20.04-zsh/Dockerfile`

These Dockerfiles provide the following environments:

* **Deep learning**:
  * CUDA
  * CUDNN
  * Anaconda
* **ZSH shell**:
  * Oh My Zsh
  * Powerlevel10k theme
  * Autosuggestions plugin
  * Syntax-highlighting plugin
* **Essential packages**:
  * build-essential
  * wget
  * vim
  * curl
  * git
  * tmux
  * openssh-server
  * Github CLI
  * colorls (only Ubuntu 22.04)
  * and so on...

Build a Docker image by:

```bash
docker build -t cuda12.8.1-ubuntu22.04-zsh:v1 ./cuda12.8.1-ubuntu22.04-zsh
```

Run the container by:

```bash
docker run --rm -it --gpus all --name ai-dev-env cuda12.8.1-ubuntu22.04-zsh:v1
```

Also, this repository provides `docker-compose.yml` for handling multiple containers:

```yaml
services:
  <USER_NAME>.base-ai-dev-env: # <USER_NAME> as your user name
    build:
      context: ./cuda12.8.1-ubuntu22.04-zsh # Dockerfile path
      args:
        SSH_PUBLIC_KEY: "${SSH_PUBLIC_KEY}" # SSH public key
    image: cuda12.8.1-ubuntu22.04-zsh:v1
    container_name: <USER_NAME>.base-ai-dev-env-cuda12.8.1 # <USER_NAME> as your user name
    runtime: nvidia
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
    ports:
      - "<HOST_PORT>:22" # <HOST_PORT> as your host port for SSH port forwarding (host:container), 
    volumes:
      - /home/<USER_NAME>/workspace:/root/workspace # <USER_NAME> as your host user name for binding host workspace to container workspace for persistency
      # - external-disk1:/mnt/data1 # bind external disk to container
    environment:
      - NVIDIA_VISIBLE_DEVICES=all # visible all GPUs
    stdin_open: true
    tty: true
```

Change `<USER_NAME>` as your host user name or remove them and `<HOST_PORT>` as your host port for SSH port forwarding. Then, set environment variable `SSH_PUBLIC_KEY` by:

```bash
export SSH_PUBLIC_KEY="<YOUR_SSH_PUBLIC_KEYS>"
```

Finally, run the below command:

```bash
docker compose up --build
```

Install nvidia-docker-smi shell script:

```bash
chmod +x nvidia-docker-smi.sh
sudo mv nvidia-docker-smi.sh /usr/local/bin/nvidia-docker-smi
```

Run the command:

```bash
nvidia-docker-smi
```
