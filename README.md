# CUDA Docker Builder

Docker images for CUDA-enabled Ubuntu with a pre-configured ZSH environment.
Build and manage multiple CUDA / Ubuntu version combinations side by side.

---

## What's Inside

| Category | Packages |
|----------|----------|
| **Deep Learning** | CUDA, cuDNN, Miniconda |
| **Shell** | ZSH, Oh My Zsh, Powerlevel10k, Autosuggestions, Syntax-highlighting |
| **Dev Tools** | build-essential, vim, git, tmux, GitHub CLI, lsd, uv, Claude Code |
| **Infra** | openssh-server, SSH key auth |

## Project Structure

```
.
├── build.sh                       # Interactive build & configure script
├── build_base/                    # Template (Dockerfile + shared configs)
│   ├── Dockerfile                 #   FROM nvidia/cuda:<BASE_IMAGE_TAG>
│   ├── .p10k.zsh
│   ├── entrypoint.sh
│   └── torch_test.py
├── docker-compose-template.yml    # Compose template with placeholders
├── cuda*-ubuntu*-zsh/             # ← Generated version directories
└── nvidia-docker-smi.sh           # GPU process viewer for containers
```

## Quick Start

```bash
bash build.sh
```

```
========================================================
  CUDA Docker Builder
========================================================
  1) Search    - Browse nvidia/cuda tags from Docker Hub
  2) Build     - Generate a version directory from template
  3) Configure - Generate docker-compose.yml
  0) Exit
========================================================
```

### 1. Search

Browse available `nvidia/cuda` image tags from Docker Hub.
Supports prefix matching for both CUDA and Ubuntu version filters.

```
CUDA version filter (e.g. 12, 12.8, leave empty for all): 12.8
Ubuntu version filter (e.g. 22, 24.04, leave empty for all): 22

Available nvidia/cuda tags:
----------------------------
  12.8.1-cudnn-devel-ubuntu22.04
  12.8.0-cudnn-devel-ubuntu22.04
```

### 2. Build

Enter a full tag to generate a version directory from the `build_base/` template.
Press Enter to use the latest tag as default.

```
Enter full tag (default: 13.1.1-cudnn-devel-ubuntu24.04): 12.8.1-cudnn-devel-ubuntu22.04

  Tag           : 12.8.1-cudnn-devel-ubuntu22.04
  Directory     : cuda12.8.1-ubuntu22.04-zsh
Is this correct? (y/N): y

Done! Created 'cuda12.8.1-ubuntu22.04-zsh/' with FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04
```

### 3. Configure

Select a built version directory and generate `docker-compose.yml`.
Configures user name, SSH port, and optional external volume bindings.

```
Available version directories:
  cuda12.8.1-ubuntu22.04-zsh

Enter version directory name (default: cuda12.8.1-ubuntu22.04-zsh):
Enter user name (default: user): devslem
Enter SSH port for Docker container: 2222
```

### 4. Start

```bash
export SSH_PUBLIC_KEY="<YOUR_SSH_PUBLIC_KEYS>"
docker compose up --build -d
```

> **Manual build** (without docker-compose):
> ```bash
> docker build -t cuda12.8.1-ubuntu22.04-zsh:v1 ./cuda12.8.1-ubuntu22.04-zsh
> docker run --rm -it --gpus all --name ai-dev-env cuda12.8.1-ubuntu22.04-zsh:v1
> ```

---

## Troubleshooting

### `Failed to initialize NVML: Unknown Error`

When a Docker container runs for a long time, `nvidia-smi` inside the container may fail with this error. This is caused by a cgroup driver mismatch between Docker and the NVIDIA container runtime.

**Fix:**

1. Edit `/etc/nvidia-container-runtime/config.toml`:

```toml
no-cgroups = false
```

2. Edit `/etc/docker/daemon.json`:

```json
{
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    },
    "exec-opts": ["native.cgroupdriver=cgroupfs"]
}
```

3. Restart Docker:

```bash
sudo systemctl restart docker
```

---

## nvidia-docker-smi

`nvidia-smi` doesn't show which Docker container a GPU process belongs to.
This script maps GPU processes to their containers.

**Install:**

```bash
chmod +x nvidia-docker-smi.sh
sudo mv nvidia-docker-smi.sh /usr/local/bin/nvidia-docker-smi
```

**Usage:**

```bash
nvidia-docker-smi
```

```
GPU  Container ID  Container Name             PID     Process  GPU Memory Usage (MiB)
=====================================================================================
1    abcdefg12345  testuser.ai-dev-env-base   884311  python   280
2    hijklmn67890  otheruser.ai-dev-env-base  866294  python   6316
```
