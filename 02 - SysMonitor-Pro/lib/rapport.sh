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

add_system_metrics_section() {
    echo "<div class='section'>"
    echo "<h2>Utilisation du Système</h2>"
    echo "<p><strong>CPU :</strong> $(top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}' | cut -d'.' -f1)% utilisé</p>"
    echo "<p><strong>Mémoire :</strong> $(free -m | awk '/Mem/ {printf \"%d/%d MB (%.0f%%)\", \$3, \$2, \$3*100/\$2}') utilisé</p>"
    echo "<p><strong>Espace disque :</strong> $(df -h / | awk 'NR==2 {print $5 \" utilisé sur \" $2}') </p>"
    echo "</div>"
}

add_process_analysis_section() {
    echo "<div class='section'>"
    echo "<h2>Processus</h2>"
    local top_proc
    top_proc=$(ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6)
    echo "<pre>$top_proc</pre>"
    echo "</div>"
}

add_service_status_section() {
    echo "<div class='section'>"
    echo "<h2>Statut des Services Critiques</h2>"
    for service in sshd nginx docker; do
        if systemctl is-active --quiet "$service"; then
            echo "<p class='success'>✔️ $service est actif</p>"
        else
            echo "<p class='critical'>❌ $service est inactif</p>"
        fi
    done
    echo "</div>"
}

add_network_analysis_section() {
    echo "<div class='section'>"
    echo "<h2>Analyse Réseau</h2>"
    echo "<p><strong>Adresse IP :</strong> $(hostname -I | awk '{print $1}')</p>"
    echo "<p><strong>Connexions actives :</strong></p>"
    echo "<pre>$(ss -tuna | head -n 10)</pre>"
    echo "</div>"
}


    # Ajout des sections de monitoring
    add_system_metrics_section >> "$report_file"
    add_process_analysis_section >> "$report_file"
    add_service_status_section >> "$report_file"
    add_network_analysis_section >> "$report_file"

    echo "</body></html>" >> "$report_file"
    log_info "Rapport généré: $report_file"
}
