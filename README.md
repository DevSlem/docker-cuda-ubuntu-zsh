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
  * uv
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

Also, this repository provides `docker-compose-template.yml` for handling multiple containers. You can easily create and configure a `docker-compose.yml` file with `<USER_NAME>`, `<HOST_PORT>` and `<VERSION>` by entering the following command:

```bash
bash config.sh
```

Then, Start the container by:

```bash
export SSH_PUBLIC_KEY="<YOUR_SSH_PUBLIC_KEYS>"
docker compose up --build -d
```

`nvidia-smi` doesn't show whether processes using GPU are running in Docker containers or not. To check it, you can use the `nvidia-docker-smi` shell script provided in this repository. Install nvidia-docker-smi shell script:

```bash
chmod +x nvidia-docker-smi.sh
sudo mv nvidia-docker-smi.sh /usr/local/bin/nvidia-docker-smi
```

Run the command:

```bash
nvidia-docker-smi
```

Example output:

```bash
GPU  Container ID  Container Name             PID     Process  GPU Memory Usage (MiB)
=====================================================================================
1    abcdefg12345  testuser.ai-dev-env-base   884311  python   280
2    hijklmn67890  otheruser.ai-dev-env-base  866294  python   6316
```