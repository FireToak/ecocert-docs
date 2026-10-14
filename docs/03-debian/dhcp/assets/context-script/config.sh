#!/bin/bash
# ==============================================================================
# Script      : config.sh
# Description : Automatisation de la génération des blocs JSON pour Kea DHCP
# Auteur      : KADA Amine
# Version     : 1.0.0
# Date        : 12/10/2026
# Contexte    : ECOCERT - Situation SP2
# ==============================================================================

# ==========================================
# 1. FICHIERS SOURCE ET DESTINATION
# ==========================================
FICHIER_SOURCE="SP2planadressage.txt"
FICHIER_RESULTAT="/etc/kea/blocs_sous_reseaux.json"

# Réinitialiser le fichier de sortie
> "$FICHIER_RESULTAT"

echo "=== Génération des sous-réseaux pour Kea DHCP ==="

# ==========================================
# 2. LECTURE ET TRAITEMENT DU PLAN D'ADRESSAGE
# ==========================================
while IFS=':' read -r cle valeur || [ -n "$cle" ]; do
    # Nettoyage des espaces et retours chariot
    cle=$(echo "$cle" | tr -d ' \r')
    valeur=$(echo "$valeur" | tr -d ' \r')

    # 1. Récupération de l'adresse réseau
    if [ "$cle" = "sr" ]; then
        sr="$valeur"

    # 2. Conversion du masque décimal en notation CIDR
    elif [ "$cle" = "masque" ]; then
        case "$valeur" in
            "255.255.255.192") cidr="26" ;;
            "255.255.255.224") cidr="27" ;;
            "255.255.255.240") cidr="28" ;;
            *)                 cidr="24" ;;
        esac

    # 3. Traitement à la fin de chaque sous-réseau
    elif [ "$cle" = "diff" ]; then
        echo "----------------------------------------"
        echo "Réseau détecté : $sr/$cidr (Broadcast : $valeur)"

        # Saisie interactive des paramètres de la plage
        read -p "IP début de plage : " ip_debut < /dev/tty
        read -p "IP fin de plage   : " ip_fin < /dev/tty
        read -p "IP passerelle     : " passerelle < /dev/tty

        # Écriture du bloc JSON pour Kea
        cat <<EOF >> "$FICHIER_RESULTAT"
    {
        "subnet": "$sr/$cidr",
        "pools": [ { "pool": "$ip_debut - $ip_fin" } ],
        "option-data": [
            {
                "name": "routers",
                "data": "$passerelle"
            }
        ]
    },
EOF
        echo "=> Bloc JSON généré pour $sr"
    fi

done < "$FICHIER_SOURCE"

echo "----------------------------------------"
echo "Terminé ! Configuration générée dans $FICHIER_RESULTAT"

