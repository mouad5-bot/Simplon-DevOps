generate_system_report() {
    local report_file="reports/system_report_$(date +%Y%m%d_%H%M%S).html"

    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>SysMonitor Pro - Rapport Système</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; }
        .critical { background: #e74c3c; color: white; }
        .warning { background: #f39c12; color: white; }
        .success { background: #27ae60; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Rapport SysMonitor Pro</h1>
        <p>Généré le: $(date)</p>
        <p>Serveur: $(hostname)</p>
    </div>
EOF

    # Ajout des sections de monitoring
    #add_system_metrics_section >> "$report_file"
    #add_process_analysis_section >> "$report_file"
    #add_service_status_section >> "$report_file"
    #add_network_analysis_section >> "$report_file"

    echo "</body></html>" >> "$report_file"
    log_info "Rapport généré: $report_file"
}
