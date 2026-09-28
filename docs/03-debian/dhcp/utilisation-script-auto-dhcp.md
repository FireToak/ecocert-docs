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

```bash title="config_dhcp.sh" hl_lines="23 24 25"
#!/bin/bash
# La ligne au-dessus (le shebang) indique à Linux d'utiliser l'interpréteur Bash pour lire ce fichier.

# ==========================================
# 1. DÉCLARATION DES VARIABLES
# ==========================================
# On stocke les noms des fichiers dans des variables. 
# Si un jour tu déplaces tes fichiers, tu n'auras qu'à modifier ces deux lignes.
FICHIER_SOURCE="SP2planadressage.txt"
FICHIER_RESULTAT="/etc/kea/blocs_sous_reseaux.json"

echo "=== GÉNÉRATION DES SOUS-RÉSEAUX POUR KEA DHCP ==="
echo "Les blocs JSON seront créés dans $FICHIER_RESULTAT"

# Le chevron simple ">" écrase le fichier résultat s'il existe déjà, ou le crée s'il n'existe pas. 
# Cela permet de repartir sur un fichier vierge à chaque exécution du script.
echo "" > "$FICHIER_RESULTAT"


# ==========================================
# 2. BOUCLE DE LECTURE DU FICHIER TEXTE
# ==========================================
# "while read ligne" lit le fichier $FICHIER_SOURCE ligne par ligne jusqu'à la fin.
# IFS= empêche Bash de supprimer les espaces au début des lignes.
# || [[ -n "$ligne" ]] permet de lire la toute dernière ligne même s'il manque un saut de ligne à la fin du fichier.
while IFS= read -r ligne || [[ -n "$ligne" ]]; do
    
    # Si la ligne est totalement vide (-z), on passe directement à la ligne suivante (continue)
    if [[ -z "$ligne" ]]; then continue; fi
    
    # --- DÉCOUPAGE DE LA LIGNE ---
    # Exemple de ligne lue : "sr:192.168.4.0"
    # cut -d':' -f1 -> Coupe la ligne au niveau du ":" et garde le champ 1 ("sr")
    # cut -d':' -f2 -> Coupe la ligne au niveau du ":" et garde le champ 2 ("192.168.4.0")
    # tr -d ' \t' -> Nettoie la chaîne en supprimant les espaces ou tabulations invisibles
    cle=$(echo "$ligne" | cut -d':' -f1 | tr -d ' \t')
    valeur=$(echo "$ligne" | cut -d':' -f2 | tr -d ' \t')
    
    # --- ANALYSE DES MOTS-CLÉS ---
    # On vérifie ce que contient la variable "cle" (sr, masque, ou diff)
    
    if [[ "$cle" == "sr" ]]; then
        # Si la clé est "sr", on mémorise simplement l'adresse IP dans la variable $sr
        sr="$valeur"
        
    elif [[ "$cle" == "masque" ]]; then
        # Si la clé est "masque", on mémorise le masque classique
        masque="$valeur"
        
        # Kea DHCP n'accepte pas les masques classiques (255.255.255.X), il veut du CIDR (/24, /26...).
        # L'instruction "case" fait la traduction automatique pour ton plan d'adressage.
        case "$masque" in
            "255.255.255.192") cidr="26" ;;
            "255.255.255.224") cidr="27" ;;
            "255.255.255.240") cidr="28" ;;
            *) cidr="24" ;; # Valeur de sécurité par défaut si le masque n'est pas reconnu
        esac
        
    elif [[ "$cle" == "diff" ]]; then
        # Si la clé est "diff", c'est qu'on a fini de lire les 3 lignes d'un réseau.
        # On a donc toutes les infos en mémoire ($sr, $masque, $cidr, $diff) pour agir.
        diff="$valeur"
        
        echo "----------------------------------------"
        echo "Réseau détecté : $sr/$cidr (Masque : $masque | Broadcast : $diff)"
        
        # --- INTERVENTION HUMAINE ---
        # Le script met le fichier texte en pause et te demande de taper les adresses.
        # "< /dev/tty" est obligatoire : ça force l'ordinateur à écouter ton clavier physique. 
        # Sans ça, la commande "read" essaierait de lire la suite du fichier texte.
        read -p "Entrez l'IP de début de plage : " ip_debut < /dev/tty
        read -p "Entrez l'IP de fin de plage : " ip_fin < /dev/tty
        read -p "Entrez l'IP de la passerelle : " passerelle < /dev/tty
        
        # --- ÉCRITURE DU BLOC JSON ---
        # "cat <<EOF >> fichier" est une technique appelée "Heredoc". 
        # Elle permet d'écrire tout un bloc de texte multi-lignes exactement tel qu'il est dessiné ici.
        # Le chevron double ">>" ajoute le bloc à la fin du fichier sans écraser ce qu'il y a déjà.
        # Les variables ($sr, $cidr...) sont remplacées par leurs vraies valeurs au moment de l'écriture.
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
        # Le mot EOF signale la fin du bloc à écrire.
        
        echo "=> Bloc JSON généré pour le réseau $sr !"
    fi
    # Fin de l'analyse du bloc, la boucle remonte au début pour lire la ligne suivante du fichier.
    
done < "$FICHIER_SOURCE" # C'est ici qu'on "injecte" le fichier texte dans la boucle while.

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