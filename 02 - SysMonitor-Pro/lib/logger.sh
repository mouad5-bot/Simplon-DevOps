#!/bin/bash

log_with_level() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_DIR}/sysmonitor.log"

    echo "[$timestamp] [$level] $message" | tee -a "$log_file"

    if [[ "$level" == "CRITICAL" ]]; then
        logger -p local0.err "SysMonitor: $message"
    fi
}

log_info()      { log_with_level "INFO" "$1"; }
log_warning()   { log_with_level "WARNING" "$1"; }
log_error()     { log_with_level "ERROR" "$1"; }
log_critical()  { log_with_level "CRITICAL" "$1"; }
log_success()   { log_with_level "SUCCESS" "$1"; }

