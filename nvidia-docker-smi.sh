#!/bin/bash

nvidia-docker-smi() {
    GPU_PROCESS_INFO=$(nvidia-smi --query-compute-apps=pid,name,used_memory,gpu_bus_id --format=csv,noheader)

    # If there is no info, exit
    if [ -z "$GPU_PROCESS_INFO" ]; then
        echo "No GPU processes found."
        exit 0
    fi

    GPU_INFO=$(nvidia-smi --query-gpu=index,gpu_bus_id --format=csv,noheader)

    # Docker processes
    DOCKER_PROCESS_INFO=$(ps -e -o pid,cgroup | grep docker)

    # Docker gpu process csv variable
    # Header: container_id,pid,name,used_memory,gpu_index
    # DOCKER_GPU_PROCESS_CSV=""
    DOCKER_GPU_PROCESS_LIST=()

    while IFS=',' read -r pid name used_memory bus_id; do
        pid=$(echo "$pid" | xargs)
        # Get the GPU index from the GPU_INFO using the bus_id
        gpu_index=$(echo "$GPU_INFO" | grep "$bus_id" | awk -F ',' '{print $1}' | xargs)

        docker_gpu_process=$(echo "$DOCKER_PROCESS_INFO" | grep "$pid")
        
        # IF the PID is not in the Docker process list, skip
        if [ -z "$docker_gpu_process" ]; then
            continue
        fi

        # Append the process info to the CSV variable
        used_memory=$(echo "$used_memory" | sed 's/ MiB//g' | xargs)
        # Strip below elements via xargs
        name=$(echo "$name" | xargs)

        # Get the container ID from the cgroup
        container_id=$(echo "$docker_gpu_process" | awk '{print $2}' | cut -d '-' -f 2 | cut -d '.' -f 1 | xargs)
        # Get the container name
        container_name=$(docker ps --filter "id=$container_id" --format "{{.Names}}")
        container_id=${container_id:0:12}

        DOCKER_GPU_PROCESS_LIST+=("$gpu_index,$container_id,$container_name,$pid,$name,$used_memory")

    done <<< "$GPU_PROCESS_INFO"

    DOCKER_GPU_PROCESS_CSV="GPU,Container ID,Container Name,PID,Process,GPU Memory Usage (MiB)
"
    DOCKER_GPU_PROCESS_CSV+=$(echo "${DOCKER_GPU_PROCESS_LIST[@]}" | tr ' ' '\n' | sort -t ',' -k1,1n -k6,6r -k2,2)

    # Print header with a separator line below it
    DOCKER_GPU_PROCESS_CSV_PRINT=$(echo -e "$DOCKER_GPU_PROCESS_CSV" | column -t -s ',')

    # Calculate the header length dynamically
    header=$(echo "$DOCKER_GPU_PROCESS_CSV_PRINT" | head -n 1)
    header_length=${#header}

    # Print the header
    echo "$header"

    # Print a line of dashes matching the header length
    printf '=%.0s' $(seq 1 $header_length)
    echo

    # Print the rows below the header
    echo "$(echo "$DOCKER_GPU_PROCESS_CSV_PRINT" | tail -n +2)"
}

nvidia-docker-smi