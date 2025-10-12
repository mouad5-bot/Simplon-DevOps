#!/bin/bash
set -euo pipefail

# Load configuration and libraries
source "$(dirname "$0")/config/settings.conf"
source "$(dirname "$0")/config/thresholds.conf"
source "$(dirname "$0")/lib/system_monitor.sh"
source "$(dirname "$0")/lib/logger.sh"
source "$(dirname "$0")/lib/rapport.sh"
source "$(dirname "$0")/lib/process_manager.sh"
source "$(dirname "$0")/lib/service_checker.sh"
source "$(dirname "$0")/lib/network_utils.sh"
source "$(dirname "$0")/lib/validation.sh"

main() {

    log_info "Début monitoring SysMonitor Pro"

    ensure_directories_exist
    validate_prerequisites || exit 1


    run_system_monitoring    
#    run_process_monitoring
    run_service_monitoring
    run_network_monitoring


    generate_system_report

    log_success "Monitoring terminé avec succès"
}

cleanup() {
    log_info "Nettoyage en cours..."
    [[ -n "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR"
    exit $?
}
trap cleanup EXIT INT TERM

main "$@"

