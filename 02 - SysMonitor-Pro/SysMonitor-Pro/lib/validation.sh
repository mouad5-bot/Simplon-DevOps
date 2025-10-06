# Checks required commands and files exist

ensure_directories_exist() {
    for dir in "$LOG_DIR" "$(dirname "$0")/reports"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "Dossier créé automatiquement : $dir"
        fi
    done
}

validate_prerequisites() {
    local required_cmds=("top" "free" "df" "uptime" "ps" "pgrep" "pkill" "logger" "ping" "ip" "ss")
    local missing=0

    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_critical "Commande manquante : $cmd"
            missing=1
        fi
    done

    # Check log and config directories
    for dir in "$LOG_DIR" "$(dirname "$0")/reports"; do
        if [ ! -d "$dir" ]; then
            log_critical "Dossier requis manquant : $dir"
            missing=1
        fi
    done

    [ $missing -eq 0 ]
}

