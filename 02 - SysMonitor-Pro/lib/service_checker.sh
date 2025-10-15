#!/bin/bash
# lib/service_checker.sh - Vérification des services (Version Débutant)

#=============================================================================
# VARIABLES GLOBALES - Partagées entre toutes les fonctions
#=============================================================================
SERVICES_CRITIQUES=("ssh" "cron" "rsyslog")

#=============================================================================
# FONCTION 1: Vérifier les services critiques
#=============================================================================
check_critical_services() {
    echo "   Vérification des Services"
    
    local problemes=0
    
    # Utiliser la variable GLOBALE
    for service in "${SERVICES_CRITIQUES[@]}"; do
        echo ""
        echo "Vérification: $service"
        echo "--------------------"
        
        if systemctl is-active --quiet "$service"; then
            echo "✓ $service est ACTIF"
        else
            echo "✗ $service est INACTIF !"
            problemes=$((problemes + 1))
        fi
        
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            echo "  Auto-démarrage: OUI"
        else
            echo "  Auto-démarrage: NON"
        fi
    done
    
    echo ""
    if [ $problemes -eq 0 ]; then
        echo "Tous les services sont OK"
        return 0
    else
        echo "$problemes service(s) en problème"
        return 1
    fi
}

#=============================================================================
# FONCTION 2: Redémarrer les services en panne
#=============================================================================
restart_failed_service() {
    echo ""
    echo "   Redémarrage des services en panne"
    echo "===================================="
    
    local redemarres=0
    
    # Utiliser la variable GLOBALE
    for service in "${SERVICES_CRITIQUES[@]}"; do
        
        if ! systemctl is-active --quiet "$service"; then
            echo ""
            echo "⚠️  Service $service est INACTIF"
            echo "Tentative de redémarrage..."
            
            if systemctl restart "$service" 2>/dev/null; then
                sleep 2
                
                if systemctl is-active --quiet "$service"; then
                    echo "✓ Service $service redémarré avec succès"
                    redemarres=$((redemarres + 1))
                else
                    echo "✗ Le service $service ne démarre pas correctement"
                fi
            else
                echo "✗ Échec du redémarrage de $service"
            fi
        fi
    done
    
    echo ""
    echo "===================================="
    if [ $redemarres -eq 0 ]; then
        echo "Aucun service à redémarrer (tous actifs)"
    else
        echo "✓ $redemarres service(s) redémarré(s)"
    fi
}

#=============================================================================
# FONCTION 3: Analyser les logs d'un service
#=============================================================================
check_service_logs() {
    echo ""
    echo "   Logs des services critiques"
    echo "===================================="
    
    # Utiliser la variable GLOBALE
    for service in "${SERVICES_CRITIQUES[@]}"; do
        echo ""
        echo "--- Service: $service ---"
        
        if command -v journalctl &>/dev/null; then
            # Afficher les 5 dernières lignes
            journalctl -u "$service" -n 5 --no-pager
            
            # Compter les erreurs
            local nb_erreurs=$(journalctl -u "$service" -p err --no-pager 2>/dev/null | wc -l)
            
            if [ "$nb_erreurs" -gt 0 ]; then
                echo "⚠️  $nb_erreurs erreur(s) trouvée(s)"
            else
                echo "✓ Aucune erreur récente"
            fi
        else
            echo "⚠️  journalctl non disponible"
        fi
    done
    
    echo ""
    echo "===================================="
}

#=============================================================================
# FONCTION 4: Valider la configuration des services
#=============================================================================
validate_service_config() {
    echo ""
    echo "   Validation des configurations"
    echo "===================================="
    
    # Utiliser la variable GLOBALE
    for service in "${SERVICES_CRITIQUES[@]}"; do
        echo ""
        echo "--- Service: $service ---"
        
        if systemctl list-unit-files | grep -q "^${service}\.service"; then
            echo "✓ Service existe"
            
            if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                echo "✓ Auto-démarrage: ACTIVÉ"
            else
                echo "⚠️  Auto-démarrage: DÉSACTIVÉ"
            fi
        else
            echo "✗ Service non trouvé"
        fi
    done
    
    echo ""
    echo "===================================="
}


run_service_monitoring() {
        echo ""
    echo "╔════════════════════════════════════╗"
    echo "║   Monitoring des services système  ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    log_info "=== Monitoring des services système ==="
    check_critical_services
    restart_failed_service
    check_service_logs
    validate_service_config

    echo ""
    echo "╔════════════════════════════════════╗"
    echo "║   Monitoring des services système  ║"
    echo "╚════════════════════════════════════╝"
}
