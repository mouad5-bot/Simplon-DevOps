#!/bin/bash
# lib/network_utils.sh - Utilitaires réseau (Version Débutant)

check_network_connectivity() {
    echo "   Test de Connectivité Internet"
    
    # Liste des serveurs à tester
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")
    local echecs=0
    
    for host in "${test_hosts[@]}"; do
        echo ""
        echo "Test vers: $host"
        echo "--------------------"
        
        # Ping avec timeout de 3 secondes
        if ping -c 3 -W 3 "$host" &>/dev/null; then
            # Calculer le temps de réponse
            local temps=$(ping -c 3 -W 3 "$host" 2>/dev/null | grep 'avg' | awk -F'/' '{print $5}')
            echo " Connectivité OK - Temps: ${temps}ms"
            break  # Si un test réussit, pas besoin de continuer
        else
            echo " Échec de connexion"
            echecs=$((echecs + 1))
        fi
    done
    
    # Test DNS
    echo ""
    echo "Test DNS:"
    echo "--------------------"
    if nslookup google.com &>/dev/null; then
        echo " Résolution DNS fonctionnelle"
    else
        echo " Problème de résolution DNS"
        echecs=$((echecs + 1))
    fi
    
    # Résumé
    echo ""
    if [ $echecs -eq 0 ]; then
        echo " Connectivité réseau: OK"
        return 0
    else
        echo " Problèmes de connectivité détectés"
        return 1
    fi
}

monitor_network_interfaces() {
    echo "   État des Interfaces Réseau"
    echo ""
    
    # Afficher toutes les interfaces avec ip
    echo "Liste des interfaces:"
    echo "--------------------"
    ip -br addr show
    
    echo ""
    echo "Détails par interface:"
    echo "======================"
    
    # Analyser chaque interface (sauf loopback)
    for interface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo'); do
        echo ""
        echo "Interface: $interface"
        echo "--------------------"
        
        # État de l'interface
        local etat=$(ip link show "$interface" | grep -o 'state [A-Z]*' | awk '{print $2}')
        
        if [ "$etat" = "UP" ]; then
            echo "✓ État: ACTIF"
            
            # Adresse IP
            local ip_addr=$(ip addr show "$interface" | grep 'inet ' | awk '{print $2}')
            if [ -n "$ip_addr" ]; then
                echo "  IP: $ip_addr"
            else
                echo "  IP: Non configurée"
            fi
            
            # Statistiques (si disponibles)
            if [ -f "/sys/class/net/${interface}/statistics/rx_bytes" ]; then
                local rx_bytes=$(cat "/sys/class/net/${interface}/statistics/rx_bytes")
                local tx_bytes=$(cat "/sys/class/net/${interface}/statistics/tx_bytes")
                local rx_mb=$(awk "BEGIN {printf \"%.2f\", $rx_bytes/1024/1024}")
                local tx_mb=$(awk "BEGIN {printf \"%.2f\", $tx_bytes/1024/1024}")
                
                echo "  Reçu: ${rx_mb} MB"
                echo "  Envoyé: ${tx_mb} MB"
            fi
            
        else
            echo "✗ État: INACTIF"
        fi
    done
    
    echo ""
    echo "✓ Analyse des interfaces terminée"
}

check_open_ports() {
    echo "   Scan des Ports Ouverts"
    echo ""
    
    # Utiliser ss (moderne) ou netstat (ancien)
    if command -v ss &>/dev/null; then
        echo "Ports en écoute (TCP):"
        echo "--------------------"
        ss -tuln | grep LISTEN
        
        local nb_ports=$(ss -tuln | grep LISTEN | wc -l)
        echo ""
        echo "Total: $nb_ports port(s) en écoute"
        
        echo ""
        echo "Détails des processus:"
        echo "--------------------"
        ss -tulnp | grep LISTEN
        
    elif command -v netstat &>/dev/null; then
        echo "Ports en écoute (TCP):"
        echo "--------------------"
        netstat -tuln | grep LISTEN
        
        local nb_ports=$(netstat -tuln | grep LISTEN | wc -l)
        echo ""
        echo "Total: $nb_ports port(s) en écoute"
        
        echo ""
        echo "Détails des processus:"
        echo "--------------------"
        netstat -tulnp | grep LISTEN
        
    else
        echo "✗ ss et netstat non disponibles"
        return 1
    fi
    
    # Vérifier les ports critiques
    echo ""
    echo "Ports critiques:"
    echo "--------------------"
    local ports_critiques=("22:SSH" "80:HTTP" "443:HTTPS")
    
    for port_info in "${ports_critiques[@]}"; do
        local port=$(echo "$port_info" | cut -d':' -f1)
        local nom=$(echo "$port_info" | cut -d':' -f2)
        
        if ss -tuln 2>/dev/null | grep -q ":${port} " || netstat -tuln 2>/dev/null | grep -q ":${port} "; then
            echo " Port $port ($nom): OUVERT"
        else
            echo "  Port $port ($nom): fermé"
        fi
    done
    
    echo ""
    echo " Scan des ports terminé"
}

monitor_network_traffic() {
    echo "   Analyse du Trafic Réseau"
    echo "   (Échantillon sur 5 secondes)"
    echo ""
    
    # Capturer les stats avant
    declare -A rx_avant tx_avant rx_apres tx_apres
    
    echo "Capture des données en cours..."
    
    for interface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo'); do
        if [ -f "/sys/class/net/${interface}/statistics/rx_bytes" ]; then
            rx_avant[$interface]=$(cat "/sys/class/net/${interface}/statistics/rx_bytes")
            tx_avant[$interface]=$(cat "/sys/class/net/${interface}/statistics/tx_bytes")
        fi
    done
    
    # Attendre 5 secondes
    sleep 5
    
    # Capturer les stats après
    for interface in "${!rx_avant[@]}"; do
        if [ -f "/sys/class/net/${interface}/statistics/rx_bytes" ]; then
            rx_apres[$interface]=$(cat "/sys/class/net/${interface}/statistics/rx_bytes")
            tx_apres[$interface]=$(cat "/sys/class/net/${interface}/statistics/tx_bytes")
        fi
    done
    
    # Calculer et afficher les débits
    echo ""
    echo "Débit par interface (KB/s):"
    echo "--------------------"
    
    for interface in "${!rx_avant[@]}"; do
        local rx_diff=$((rx_apres[$interface] - rx_avant[$interface]))
        local tx_diff=$((tx_apres[$interface] - tx_avant[$interface]))
        local rx_rate=$(awk "BEGIN {printf \"%.2f\", $rx_diff/1024/5}")
        local tx_rate=$(awk "BEGIN {printf \"%.2f\", $tx_diff/1024/5}")
        
        echo "$interface:"
        echo "   Download: ${rx_rate} KB/s"
        echo "   Upload: ${tx_rate} KB/s"
    done
    
    # Connexions actives
    echo ""
    echo "Connexions actives:"
    echo "--------------------"
    
    if command -v ss &>/dev/null; then
        local connexions=$(ss -tan | grep ESTAB | wc -l)
        echo "Connexions établies: $connexions"
        echo ""
        echo "Top 5 connexions:"
        ss -tan state established | head -n 6
    elif command -v netstat &>/dev/null; then
        local connexions=$(netstat -tan | grep ESTABLISHED | wc -l)
        echo "Connexions établies: $connexions"
        echo ""
        echo "Top 5 connexions:"
        netstat -tan | grep ESTABLISHED | head -n 5
    fi
    
    echo ""
    echo " Analyse du trafic terminée"
}

run_network_monitoring() {
    echo ""
    echo "╔════════════════════════════════════╗"
    echo "║   SURVEILLANCE RÉSEAU             ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    log_info "=== SURVEILLANCE RÉSEAU ==="

    check_network_connectivity
    monitor_network_interfaces
    check_open_ports
    monitor_network_traffic
    
    echo ""
    echo "╔════════════════════════════════════╗"
    echo "║   SURVEILLANCE TERMINÉE            ║"
    echo "╚════════════════════════════════════╝"
}


