#!/bin/bash

# ====================
# SYSTEM MONITOR MODULE
# ====================

# Monitor CPU usage (uses average over all cores)
monitor_cpu_usage() {
    local cpu_idle cpu_usage threshold
    # Using top for real-time or /proc/stat for accuracy
    cpu_idle=$(top -bn1 | grep 'Cpu(s)' | awk '{print $8}' | cut -d'.' -f1)
    cpu_usage=$(printf "%.0f" "$cpu_idle")
    threshold=${CPU:-80}

    if (( cpu_usage > threshold )); then
        log_warning "CPU usage élevé: ${cpu_usage}% (seuil: $threshold%)"
    else
        log_info "CPU usage normal: ${cpu_usage}%"
    fi
}

# Monitor Memory and Swap usage
monitor_memory_usage() {
    local mem_total mem_used mem_perc swap_total swap_used swap_perc
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_used=$(( mem_total - $(grep MemAvailable /proc/meminfo | awk '{print $2}') ))
    mem_perc=$(( 100 * mem_used / mem_total ))

    swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    swap_used=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    swap_perc=0
    if (( swap_total > 0 )); then
        swap_used=$(( swap_total - $(grep SwapFree /proc/meminfo | awk '{print $2}') ))
        swap_perc=$(( 100 * swap_used / swap_total ))
    fi

    if (( mem_perc > ${MEM:-90} )); then
        log_warning "Utilisation RAM élevée: $mem_perc%"
    else
        log_info "Utilisation RAM normale: $mem_perc%"
    fi

    if (( swap_total > 0 )); then
        log_info "Utilisation SWAP: $swap_perc%"
    fi
}

# Monitor disk usage by partition
monitor_disk_space() {
    local threshold
    threshold=${DISK:-90}
    while read -r filesystem size used avail perc mount; do
        usage=${perc%%%}
        if [[ "$filesystem" =~ ^/dev/ ]]; then
            if (( usage > threshold )); then
                log_warning "Espace disque élevé ($filesystem $mount): $perc (seuil: $threshold%)"
            else
                log_info "Espace disque ok ($filesystem $mount): $perc"
            fi
        fi
    done < <(df -h --output=source,size,used,avail,pcent,target | tail -n +2)
}

# Monitor system load average and process count
monitor_system_load() {
    local load1 load5 load15 numproc threshold proctotal
    read load1 load5 load15 _ < /proc/loadavg
    proctotal=$(ps -e --no-headers | wc -l)
    threshold=$(nproc)

    if (( $(echo "$load1 > $threshold" | bc -l) )); then
        log_warning "Load average élevé: 1min=$load1 (coeurs dispo: $threshold)"
    else
        log_info "Load average normal: 1min=$load1"
    fi

    log_info "Nombre total de processus: $proctotal"
}

# Helper to run all monitoring
run_system_monitoring() {
    log_info "=== Monitoring Système ==="
    monitor_cpu_usage
    monitor_memory_usage
    monitor_disk_space
    monitor_system_load
}


