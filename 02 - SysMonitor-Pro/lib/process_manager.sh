#!/bin/bash

# ============================
# PROCESS MANAGER MODULE
# ============================

# List top 10 CPU-consuming processes
list_top_processes() {
    log_info "Liste des 10 processus les plus consommateurs (CPU)"
    ps -eo pid,user,pcpu,pmem,stat,comm --sort=-pcpu | head -n 11 | tee -a "${LOG_DIR}/sysmonitor.log"
}

# Find zombie processes in the system
find_zombie_processes() {
    local zombies
    zombies=$(ps -eo stat,pid,ppid,cmd | awk '$1 ~ /Z/')

    if [[ -n "$zombies" ]]; then
        log_warning "Processus zombies détectés:"
        echo "$zombies" | tee -a "${LOG_DIR}/sysmonitor.log"
    else
        log_info "Aucun processus zombie détecté."
    fi
}

# Monitor a specific critical process by name or PID
# Usage: monitor_specific_process <process_name_or_pid>
monitor_specific_process() {
    local target="${1:-}"
    local pid

    if [[ -z "$target" ]]; then
        log_error "Aucun processus spécifié pour la surveillance."
        return 1
    fi

    if [[ "$target" =~ ^[0-9]+$ ]]; then
        pid="$target"
    else
        pid=$(pgrep -x "$target")
    fi

    if [[ -z "$pid" ]]; then
        log_error "Processus critique '$target' non trouvé."
        return 1
    fi

    for p in $pid; do
        local state
        state=$(ps -o stat= -p "$p")
        log_info "Processus critique: PID=$p, état=$state"
    done
}


# kill a problematic process safely
# Usage: kill_problematic_process <pid> [signal]
# Default signal SIGTERM, fallback to SIGKILL if needed
kill_problematic_process() {
    local pid="$1"
    local signal="${2:-TERM}"

    if ! kill -$signal "$pid" &> /dev/null; then
        log_error "Échec de l’envoi du signal $signal à PID $pid"
        return 1
    fi

    log_info "Signal $signal envoyé à PID $pid, attente de la terminaison..."

    # Wait 5 seconds, then SIGKILL if process still alive
    for i in {1..5}; do
        if ! ps -p "$pid" > /dev/null; then
            log_info "Processus $pid arrêté proprement."
            return 0
        fi
        sleep 1
    done

    log_warning "Processus $pid non terminé après SIGTERM, envoi SIGKILL..."
    kill -KILL "$pid" &> /dev/null

    if ps -p "$pid" > /dev/null; then
        log_critical "Impossible de tuer le processus $pid."
        return 1
    else
        log_info "Processus $pid tué avec SIGKILL."
    fi
}

run_process_monitoring() {
    log_info "=== Gestion des processus ==="
    list_top_processes
    find_zombie_processes
    monitor_specific_process
    kill_problematic_process
}
