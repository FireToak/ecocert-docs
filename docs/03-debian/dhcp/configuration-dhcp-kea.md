---
description: Déploiement et configuration du service Kea-dhcp4 multi-VLANs sur Debian 13 avec relais Cisco.
---

# Configuration kea-dhcp4 sur Debian

![Bannière CUB](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** KADA Amine
    - **Date :** 08/09/2026
    - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Préparation et sauvegarde](#3-preparation-et-sauvegarde)
- [4. Configuration du fichier JSON (kea-dhcp4.conf)](#4-configuration-du-fichier-json-kea-dhcp4conf)
- [5. Application et tests](#5-application-et-tests)
- [6. Configuration du relais DHCP (Switch Cisco)](#6-configuration-du-relais-dhcp-switch-cisco)

## 2. Contexte

Ce document détaille la procédure de déploiement et de configuration du service **Kea-dhcp4** sur un système Debian 13 (nœud `pve2`, ID `20804`). Le serveur (nommé `DHCPECOCERT`, adresse IP `172.16.54.2`) fait office de serveur DHCP centralisé et a pour mission d'allouer dynamiquement les adresses IP aux hôtes répartis sur plusieurs VLANs. L'architecture nécessitant des franchissements de domaines de diffusion, l'intégration implique l'activation d'agents relais DHCP sur l'équipement réseau de cœur de réseau (Switch Cisco de niveau 3).

## 3. Préparation et sauvegarde

!!! warning "Stricte conformité JSON"

    Le service Kea s'appuie sur une structure de configuration JSON. Le parsing étant extrêmement strict, une erreur de syntaxe (telle qu'une virgule superflue ou manquante) bloquera l'instanciation du daemon.

3.1.  **Sauvegarde de la configuration d'origine**. Archivage du fichier initial fourni par le gestionnaire de paquets afin de garantir une procédure de rollback rapide.

```bash title="backup_kea_config.sh"
sudo mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bkp
sudo nano /etc/kea/kea-dhcp4.conf
```

- `mv` : Déplace et renomme la configuration active pour l'isoler de l'exécution.
- `nano` : Génère un buffer vide pour la création d'une configuration ex-nihilo.

## 4. Configuration du fichier JSON (kea-dhcp4.conf)

4.1.  **Définition des options DHCP et des sous-réseaux**. Implémentation du mapping réseau (scopes, baux, options de passerelle et résolveurs DNS) requis pour provisionner les différents VLANs depuis le sous-réseau `172.16.54.0/24`.

```json title="/etc/kea/kea-dhcp4.conf"
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "ens18" ]
    },
    
    "valid-lifetime": 691200,
    "renew-timer": 345600,
    "rebind-timer": 604800,
    "authoritative": true,
    
    "lease-database": {
      "type": "memfile",
      "persist": true,
      "name": "/var/lib/kea/kea-leases4.csv",
      "lfc-interval": 3600
    },

    "subnet4": [
      {
        "id": 11,
        "subnet": "192.168.4.0/26",
        "pools": [ { "pool": "192.168.4.10 - 192.168.4.60" } ],
        "option-data": [
          { "name": "routers", "data": "192.168.4.62" },
          { "name": "domain-name-servers", "data": "8.8.8.8" }
        ],
        "user-context": { "description": "VLAN 11 - Administration" }
      },
      {
        "id": 21,
        "subnet": "192.168.4.64/27",
        "pools": [ { "pool": "192.168.4.70 - 192.168.4.90" } ],
        "option-data": [
          { "name": "routers", "data": "192.168.4.94" },
          { "name": "domain-name-servers", "data": "8.8.8.8" }
        ],
        "user-context": { "description": "VLAN 21 - Service de certification" }
      },
      {
        "id": 81,
        "subnet": "192.168.4.96/27",
        "pools": [ { "pool": "192.168.4.100 - 192.168.4.120" } ],
        "option-data": [
          { "name": "routers", "data": "192.168.4.126" },
          { "name": "domain-name-servers", "data": "8.8.8.8" }
        ],
        "user-context": { "description": "VLAN 81 - Wifi-Visiteurs" }
      },
      {
        "id": 61,
        "subnet": "192.168.4.128/27",
        "pools": [ { "pool": "192.168.4.135 - 192.168.4.150" } ],
        "option-data": [
          { "name": "routers", "data": "192.168.4.158" },
          { "name": "domain-name-servers", "data": "8.8.8.8" }
        ],
        "user-context": { "description": "VLAN 61 - Expertise technique & conseil" }
      },
      {
        "id": 31,
        "subnet": "192.168.4.160/27",
        "pools": [ { "pool": "192.168.4.165 - 192.168.4.185" } ],
        "option-data": [
          { "name": "routers", "data": "192.168.4.190" },
          { "name": "domain-name-servers", "data": "8.8.8.8" }
        ],
        "user-context": { "description": "VLAN 31 - Service referentiels" }
      },
      {
        "id": 71,
        "subnet": "192.168.4.192/28",
        "pools": [ { "pool": "192.168.4.195 - 192.168.4.200" } ],
        "option-data": [
          { "name": "routers", "data": "192.168.4.206" },
          { "name": "domain-name-servers", "data": "8.8.8.8" }
        ],
        "user-context": { "description": "VLAN 71 - Services techniques" }
      },
      {
        "id": 41,
        "subnet": "192.168.4.208/28",
        "pools": [ { "pool": "192.168.4.212 - 192.168.4.220" } ],
        "option-data": [
          { "name": "routers", "data": "192.168.4.222" },
          { "name": "domain-name-servers", "data": "8.8.8.8" }
        ],
        "user-context": { "description": "VLAN 41 - Formations professionnelles" }
      }
    ]
  }
}
```

- `interfaces-config` : Paramètre du socket d'écoute définissant l'interface réseau logique sollicitée (adapter `ens18` selon l'hyperviseur).
- `authoritative` : Prévient les dysfonctionnements réseau en autorisant le serveur à révoquer activement les baux invalides ou caduques de son segment.
- `lease-database` : Ordonne le stockage persistant des baux DHCP alloués dans un fichier CSV (memfile), assurant la continuité de service après reboot.
- `subnet4` : Dictionnaire d'objets assignant pour chaque VLAN un ID de sous-réseau, une étendue d'adresses (`pools`) et les directives réseau standards (routeur par défaut, résolveur DNS).

## 5. Application et tests

5.1.  **Rechargement de la configuration via Systemd**. Validation de l'arbre syntaxique du fichier JSON et injection dans le processus applicatif.

```bash title="restart_kea.sh" hl_lines="1"
sudo systemctl restart kea-dhcp4-server
```

- `restart` : Coupe la session en cours et réinstancie le service avec les nouveaux paramètres.

5.2.  **Audit du service (Troubleshooting)**. Vérification de l'état d'exécution et extraction des exceptions ou erreurs de parsing JSON.

```bash title="troubleshoot_kea.sh"
sudo journalctl -xe | grep kea
```

- `journalctl -xe` : Visualise la fin de la file de journaux avec le maximum d'informations de contexte.
- `grep kea` : Applique un filtre regex pour isoler le flux spécifique au processus DHCP.

## 6. Configuration du relais DHCP (Switch Cisco)

!!! tip "Agent Relais"

    Le serveur étant hors des segments locaux des clients, les requêtes `DHCPDISCOVER` (diffusées en broadcast à l'adresse de niveau 2 `FF:FF:FF:FF:FF:FF`) sont naturellement bloquées par les routeurs. La configuration d'un agent de relais IP est indispensable.

6.1.  **Configuration des SVIs (Switch Virtual Interfaces)**. Altération du comportement par défaut des interfaces virtuelles pour rediriger en unicast les paquets de découverte DHCP vers l'IP du serveur Kea.

```bash title="cisco_relay.cli" hl_lines="4 8"
enable
configure terminal

interface vlan 11
 ip helper-address 172.16.54.2
 exit

interface vlan 81
 ip helper-address 172.16.54.2
 exit
```

- `interface vlan [ID]` : Instancie le mode de configuration pour l'interface passerelle du VLAN spécifié.
- `ip helper-address` : Directive Cisco de niveau 3 encapsulant la requête UDP Broadcast entrante et la relayant directement vers le socket du serveur spécifié (`172.16.54.2`).