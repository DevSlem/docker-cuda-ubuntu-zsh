#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/build_base"
DEFAULT_DIR_NAME="cuda12.8.1-ubuntu22.04-zsh"

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: Template directory '$TEMPLATE_DIR' not found."
    exit 1
fi

# ── 1) Search tags ──────────────────────────────────────────────
fetch_tags() {
    echo "Docker Hub: https://hub.docker.com/r/nvidia/cuda/tags"
    echo ""
    read -rp "CUDA version filter (e.g. 12, 12.8, leave empty for all): " CUDA_FILTER
    read -rp "Ubuntu version filter (e.g. 22, 24.04, leave empty for all): " UBUNTU_FILTER

    echo ""
    echo "Fetching nvidia/cuda tags from Docker Hub..."
    echo ""

    local TAGS=()
    local PAGE_SIZE=100
    local URL="https://hub.docker.com/v2/repositories/nvidia/cuda/tags?page_size=${PAGE_SIZE}&name=cudnn-devel-ubuntu"

    while [ -n "$URL" ] && [ "$URL" != "null" ]; do
        local RESPONSE
        RESPONSE=$(curl -s "$URL")
        local PAGE_TAGS
        PAGE_TAGS=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
cuda_filter = '${CUDA_FILTER}'
ubuntu_filter = '${UBUNTU_FILTER}'
for r in data.get('results', []):
    name = r['name']
    parts = name.split('ubuntu')
    if len(parts) == 2 and parts[1].replace('.', '').isdigit():
        if cuda_filter and not name.startswith(cuda_filter):
            continue
        if ubuntu_filter and not parts[1].startswith(ubuntu_filter):
            continue
        print(name)
" 2>/dev/null || true)

        while IFS= read -r tag; do
            [ -n "$tag" ] && TAGS+=("$tag")
        done <<< "$PAGE_TAGS"

        URL=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('next') or '')
" 2>/dev/null || true)
    done

    if [ ${#TAGS[@]} -eq 0 ]; then
        echo "No matching tags found."
        return
    fi

    echo "Available nvidia/cuda tags:"
    echo "----------------------------"
    for i in "${!TAGS[@]}"; do
        printf "  %s\n" "${TAGS[$i]}"
    done
    echo ""
}

# ── 2) Build version directory ──────────────────────────────────
build_version() {
    echo "Fetching latest tag..."
    local LATEST
    LATEST=$(curl -s "https://hub.docker.com/v2/repositories/nvidia/cuda/tags?page_size=1&name=cudnn-devel-ubuntu" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('results', []):
    name = r['name']
    parts = name.split('ubuntu')
    if len(parts) == 2 and parts[1].replace('.', '').isdigit():
        print(name); break
" 2>/dev/null || true)

    read -rp "Enter full tag (default: $LATEST): " SELECTED_TAG
    SELECTED_TAG=${SELECTED_TAG:-$LATEST}

    if [ -z "$SELECTED_TAG" ]; then
        echo "Error: Failed to determine tag."
        return
    fi

    # Parse CUDA version and Ubuntu version from tag
    CUDA_VER=$(echo "$SELECTED_TAG" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)-cudnn.*/\1/')
    UBUNTU_VER=$(echo "$SELECTED_TAG" | sed -E 's/.*ubuntu([0-9]+\.[0-9]+)$/\1/')

    if [ -z "$CUDA_VER" ] || [ -z "$UBUNTU_VER" ]; then
        echo "Error: Failed to parse CUDA/Ubuntu version from tag '$SELECTED_TAG'."
        return
    fi

    DIR_NAME="cuda${CUDA_VER}-ubuntu${UBUNTU_VER}-zsh"
    TARGET_DIR="$SCRIPT_DIR/$DIR_NAME"

    echo ""
    echo "  Tag           : $SELECTED_TAG"
    echo "  Directory     : $DIR_NAME"
    read -rp "Is this correct? (y/N): " REPLY
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        echo "Aborted."
        return
    fi

    if [ -d "$TARGET_DIR" ]; then
        read -rp "Directory '$DIR_NAME' already exists. Overwrite? (y/N): " CONFIRM
        if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
            echo "Aborted."
            return
        fi
        rm -rf "$TARGET_DIR"
    fi

    echo "Creating '$DIR_NAME'..."
    cp -r "$TEMPLATE_DIR" "$TARGET_DIR"
    sed -i "s|<BASE_IMAGE_TAG>|${SELECTED_TAG}|g" "$TARGET_DIR/Dockerfile"

    echo "Done! Created '$DIR_NAME/' with FROM nvidia/cuda:${SELECTED_TAG}"
    echo ""
}

# ── 3) Configure docker-compose ─────────────────────────────────
configure() {
    # List available version directories
    echo "Available version directories:"
    for d in "$SCRIPT_DIR"/cuda*-ubuntu*-zsh/; do
        [ -d "$d" ] && echo "  $(basename "$d")"
    done
    echo ""

    # Version directory
    read -rp "Enter version directory name (default: $DEFAULT_DIR_NAME): " DIR_NAME
    DIR_NAME=${DIR_NAME:-$DEFAULT_DIR_NAME}

    if [ ! -d "$SCRIPT_DIR/$DIR_NAME" ]; then
        echo "Warning: Directory '$DIR_NAME' does not exist. Run 'Build' first."
        return
    fi

    # User name
    read -rp "Enter user name (default: $USER): " USER_NAME
    USER_NAME=${USER_NAME:-$USER}

    # SSH port
    read -rp "Enter SSH port for Docker container: " SSH_PORT
    while ss -tuln | grep -q ":$SSH_PORT"; do
        echo "Port $SSH_PORT is already in use. Please choose a different port."
        read -rp "Enter SSH port for Docker container: " SSH_PORT
    done

    VERSION=$(tr -d ' \t\n\r' < "$SCRIPT_DIR/.version")

    # Volume binding
    volume_name_list=()
    volume_device_list=()
    read -rp "Do you want to bind volumes to the container? (y/N): " REPLY
    if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
        volume_list=$(docker volume ls --format '{{.Name}}')
        for vol in $volume_list; do
            device_path=$(docker volume inspect "$vol" --format '{{.Options.device}}')
            if [ "$device_path" != "<no value>" ]; then
                read -rp "volume: '$vol', mount point: '$device_path', bind to container? (y/N): " REPLY
                if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
                    volume_name_list+=("$vol")
                    volume_device_list+=("$device_path")
                fi
            fi
        done
    fi

    # Summary and confirmation
    echo ""
    echo "  Version dir : $DIR_NAME"
    echo "  User name   : $USER_NAME"
    echo "  SSH port    : $SSH_PORT"
    echo "  Version     : $VERSION"
    if [ ${#volume_name_list[@]} -gt 0 ]; then
        echo "  Volumes     :"
        for i in "${!volume_name_list[@]}"; do
            echo "    - ${volume_name_list[$i]} → ${volume_device_list[$i]}"
        done
    else
        echo "  Volumes     : (none)"
    fi
    read -rp "Is this correct? (y/N): " REPLY
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        echo "Aborted."
        return
    fi

    # Generate docker-compose.yml
    mkdir -p ~/workspace
    cp "$SCRIPT_DIR/docker-compose-template.yml" "$SCRIPT_DIR/docker-compose.yml"

    sed -i "s/<USER_NAME>/$USER_NAME/g" "$SCRIPT_DIR/docker-compose.yml"
    sed -i "s/<HOST_PORT>/$SSH_PORT/g" "$SCRIPT_DIR/docker-compose.yml"
    sed -i "s/<VERSION>/$VERSION/g" "$SCRIPT_DIR/docker-compose.yml"
    sed -i "s/<DIR_NAME>/$DIR_NAME/g" "$SCRIPT_DIR/docker-compose.yml"

    if [ ${#volume_name_list[@]} -gt 0 ]; then
        sed -i "\$a volumes:" "$SCRIPT_DIR/docker-compose.yml"
        for i in "${!volume_name_list[@]}"; do
            vol_name=${volume_name_list[$i]}
            vol_device=${volume_device_list[$i]}
            sed -i "/# - external-disk1:\/mnt\/data1 # bind external disk to container/a\\
      - $vol_name:$vol_device" "$SCRIPT_DIR/docker-compose.yml"
            sed -i "\$a\\
  $vol_name:" "$SCRIPT_DIR/docker-compose.yml"
            sed -i "\$a\\
    external: true" "$SCRIPT_DIR/docker-compose.yml"
        done
        echo "${#volume_name_list[@]} external disks will be bound to the container."
    else
        echo "No external disks to bind."
    fi

    echo ""
    echo "Configuration complete. You can now start the $USER_NAME.ai-dev-env-base container by following commands:"
    echo ""
    echo "export SSH_PUBLIC_KEY=\"<YOUR_SSH_PUBLIC_KEYS>\""
    echo "docker compose up --build -d"
    echo ""
}

# ── Main menu ────────────────────────────────────────────────────
while true; do
    echo "========================================================"
    echo "  CUDA Docker Builder"
    echo "========================================================"
    echo "  1) Search    - Browse nvidia/cuda tags from Docker Hub"
    echo "  2) Build     - Generate a version directory from template"
    echo "  3) Configure - Generate docker-compose.yml"
    echo "  0) Exit"
    echo "========================================================"
    read -rp "Select: " CHOICE

    case "$CHOICE" in
        1) fetch_tags ;;
        2) build_version ;;
        3) configure ;;
        0) echo "Bye!"; exit 0 ;;
        *) echo "Invalid selection." ;;
    esac
    echo ""
done
