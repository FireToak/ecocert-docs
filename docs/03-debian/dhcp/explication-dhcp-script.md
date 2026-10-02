---
description: Automatisation de la génération des pools DHCP pour Kea via un script Bash interactif.
---

# Automatisation de la configuration Kea DHCP

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** Amine KADA
    - **Date :** 28/09/2026
    - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Création du fichier d'adressage (Source)](#3-creation-du-fichier-dadressage-source)
- [4. Déploiement du script d'automatisation](#4-deploiement-du-script-dautomatisation)
- [5. Exécution et intégration de la configuration](#5-execution-et-integration-de-la-configuration)

## 2. Contexte

Dans le cadre de la réorganisation du réseau d'ECOCERT et de la remédiation (SP2), cette procédure vise à automatiser la configuration du serveur Kea-dhcp4. Un script d'automatisation Bash analyse le plan d'adressage (format texte) et génère interactivement la configuration associée au format JSON stricte requis par Kea. Cette approche Infrastructure as Code (IaC) minimise les erreurs de syntaxe manuelles et accélère le déploiement de nouveaux VLANs.

📄 **Document de référence :** [Contexte ECOCERT SP2](./assets/context-script/Situation%20-%20REMEDIATION%20SP2%20-%20Automatisation%20de%20la%20configuration%20du%20DHCP.pdf)

## 3. Création du fichier d'adressage (Source)

3.1. **Définition des sous-réseaux ECOCERT.** Création du fichier de base de données contenant le plan d'adressage (VLSM) qui sera traité par le script d'automatisation.

```text title="SP2planadressage.txt"
# VLAN 11 - ADMINISTRATION
sr:192.168.4.0
masque:255.255.255.192
diff:192.168.4.63

# VLAN 21 - CERTIFICATION
sr:192.168.4.64
masque:255.255.255.224
diff:192.168.4.95

# VLAN 81 - WIFI-VISITEURS
sr:192.168.4.96
masque:255.255.255.224
diff:192.168.4.127

# VLAN 61 - CONSEIL TECH
sr:192.168.4.128
masque:255.255.255.224
diff:192.168.4.159

# VLAN 31 - REFERENTIELS
sr:192.168.4.160
masque:255.255.255.224
diff:192.168.4.191

# VLAN 71 - TECHNIQUES
sr:192.168.4.192
masque:255.255.255.240
diff:192.168.4.207

# VLAN 41 - FORMA PRO
sr:192.168.4.208
masque:255.255.255.240
diff:192.168.4.223
```

- `sr` : Adresse réseau du sous-réseau (Subnet).
- `masque` : Masque de sous-réseau en notation décimale pointée.
- `diff` : Adresse de diffusion (Broadcast) du sous-réseau.

## 4. Déploiement du script d'automatisation

4.1. **Création du script Bash.** Écriture du programme chargé de convertir les masques en CIDR, d'interroger l'administrateur pour les plages d'adresses et de formater la sortie en JSON.

```bash title="config_dhcp.sh" hl_lines="15 16 23 24 64 65"
#!/bin/bash
# La ligne au-dessus (le shebang) indique à Linux d'utiliser l'interpréteur Bash pour lire ce fichier.

# ==========================================
# 1. DÉCLARATION DES VARIABLES ET SAUVEGARDE
# ==========================================
FICHIER_SOURCE="SP2planadressage.txt"
FICHIER_RESULTAT="/etc/kea/blocs_sous_reseaux.json"

echo "=== GÉNÉRATION DES SOUS-RÉSEAUX POUR KEA DHCP ==="

# Sauvegarde automatique du fichier de configuration initial
if [ -f /etc/kea/kea-dhcp4.conf ]; then
    cp /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.backup_$(date +%F_%H%M%S)
    echo "Sauvegarde du fichier initial effectuée."
fi

# Configuration des requêtes interactives globales
read -p "Entrez les serveurs DNS (172.16.54.1, 9.9.9.9) : " serveurs_dns < /dev/tty
read -p "Entrez le nom de domaine (local.ecocert4.fr) : " nom_domaine < /dev/tty

echo "Les blocs JSON seront créés dans $FICHIER_RESULTAT"

# Le chevron simple ">" écrase le fichier résultat s'il existe déjà
echo "" > "$FICHIER_RESULTAT"

# ==========================================
# 2. BOUCLE DE LECTURE DU FICHIER TEXTE
# ==========================================
while IFS= read -r ligne || [[ -n "$ligne" ]]; do
    
    if [[ -z "$ligne" ]]; then continue; fi
    
    # --- DÉCOUPAGE DE LA LIGNE ---
    cle=$(echo "$ligne" | cut -d':' -f1 | tr -d ' \t')
    valeur=$(echo "$ligne" | cut -d':' -f2 | tr -d ' \t')
    
    # --- ANALYSE DES MOTS-CLÉS ---
    if [[ "$cle" == "sr" ]]; then
        sr="$valeur"
        
    elif [[ "$cle" == "masque" ]]; then
        masque="$valeur"
        case "$masque" in
            "255.255.255.192") cidr="26" ;;
            "255.255.255.224") cidr="27" ;;
            "255.255.255.240") cidr="28" ;;
            *) cidr="24" ;;
        esac
        
    elif [[ "$cle" == "diff" ]]; then
        diff="$valeur"
        
        echo "----------------------------------------"
        echo "Réseau détecté : $sr/$cidr (Masque : $masque | Broadcast : $diff)"
        
        # --- INTERVENTION HUMAINE ---
        # Configuration des requêtes interactives spécifiques
        read -p "Entrez l'IP de début de plage : " ip_debut < /dev/tty
        read -p "Entrez l'IP de fin de plage : " ip_fin < /dev/tty
        read -p "Entrez l'IP de la passerelle : " passerelle < /dev/tty
        
        # --- ÉCRITURE DU BLOC JSON ---
        cat <<EOF >> "$FICHIER_RESULTAT"
        {
            "subnet": "$sr/$cidr",
            "pools": [ { "pool": "$ip_debut - $ip_fin" } ],
            "option-data": [
                { "name": "routers", "data": "$passerelle" },
                { "name": "domain-name-servers", "data": "$serveurs_dns" },
                { "name": "domain-name", "data": "$nom_domaine" }
            ]
        },
EOF
        
        echo "=> Bloc JSON généré pour le réseau $sr !"
    fi
    
done < "$FICHIER_SOURCE"

echo "----------------------------------------"
echo "Succès ! Ouvrez $FICHIER_RESULTAT pour copier son contenu dans /etc/kea/kea-dhcp4.conf."
```

- `FICHIER_SOURCE` : Variable définissant le fichier texte d'adressage à analyser.
- `FICHIER_RESULTAT` : Variable définissant le fichier JSON de sortie à générer.
- `< /dev/tty` : Paramètre forçant la commande `read` à écouter l'entrée standard du clavier (terminal) plutôt que la boucle de lecture du fichier texte.

## 5. Exécution et intégration de la configuration

5.1. **Attribution des permissions.** Configuration des droits sur le fichier du script pour autoriser son exécution par le système.

```bash
chmod +x config_dhcp.sh
```

- `+x` : Attribut de permission ajoutant le droit d'exécution (eXecute) au fichier cible.

5.2. **Exécution du processus.** Lancement de l'outil avec élévation de privilèges pour garantir l'autorisation d'écriture dans l'arborescence `/etc/kea/`.

```bash
sudo ./config_dhcp.sh
```

- `sudo` : Exécute la commande en tant que superutilisateur (root).
- `./` : Indique au terminal de chercher l'exécutable dans le répertoire courant.

5.3. **Intégration à Kea DHCP.** Intégration de la configuration générée dans le fichier principal du service.

```bash
cat /etc/kea/blocs_sous_reseaux.json >> /etc/kea/kea-dhcp4.conf
```

- `cat` : Affiche le contenu intégral du fichier de résultats JSON.
- `>>` : Opérateur de redirection qui concatène la sortie standard à la fin du fichier cible, sans écraser la configuration existante de Kea.