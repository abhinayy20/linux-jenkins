#!/bin/bash

# Configuration
THRESHOLD=80
LOG_DIR="/var/log"
TMP_DIR="/tmp"

# Function to check disk usage
# Returns 0 if all partitions are SAFE (below threshold)
# Returns 1 if any partition EXCEEDS the threshold
check_partitions() {
    local found_alert=0
    echo "Scanning partitions for usage above ${THRESHOLD}%..."
    
    while read -r line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local partition=$(echo "$line" | awk '{print $6}')
        
        if [ "$usage" -ge "$THRESHOLD" ]; then
            echo "[ALERT] Partition $partition is at ${usage}%"
            found_alert=1
        fi
    done < <(df -Ph | grep -vE '^Filesystem|tmpfs|cdrom|udev|loop' | grep '/')

    # Return 0 if safe (no alert found), 1 if alert found
    return $found_alert
}

perform_cleanup() {
    echo "---------------------------------------------------"
    echo "Initiating Emergency Cleanup Operations..."
    echo "---------------------------------------------------"

    # Task 1: Delete all files in /tmp
    echo "[1/2] Clearing $TMP_DIR..."
    sudo find "$TMP_DIR" -mindepth 1 -delete 2>/dev/null
    
    # Task 2: Compress logs older than 30 days
    echo "[2/2] Compressing logs older than 30 days in $LOG_DIR..."
    sudo find "$LOG_DIR" -type f -name "*.log" -mtime +30 -exec gzip -v {} \; 2>/dev/null
    echo "---------------------------------------------------"
}

# Main Execution Flow
echo "Disk Monitoring Service started at $(date)"

# If check_partitions returns 0 (Safe)
if check_partitions; then
    echo "[OK] All partitions are within safe limits."
    exit 0
else
    # If check_partitions returns 1 (Alert)
    perform_cleanup

    echo "Verifying disk usage after cleanup..."
    if check_partitions; then
        echo "[SUCCESS] Cleanup successful. Disk usage is now below threshold."
        exit 0
    else
        echo "[CRITICAL] Cleanup insufficient. Disk usage STILL above ${THRESHOLD}%."
        exit 1
    fi
fi
