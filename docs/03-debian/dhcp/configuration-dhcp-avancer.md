---
description: Configuration modulaire, sécurisée et hautement disponible du serveur Kea DHCPv4 pour l'infrastructure ECOCERT.
---

# Déploiement et Sécurisation de l'Architecture Modulaire Kea DHCPv4

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] Informations
> - **Auteur :** Amine KADA
> - **Date :** 29/09/2026
> - **Domaine :** Infrastructure / Services Réseaux

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Configuration Globale (Fichier Maître)](#3-configuration-globale-fichier-maitre)
- [4. Création de l'Index d'Inclusion](#4-creation-de-lindex-dinclusion)
- [5. Définition des Sous-Réseaux (VLANs)](#5-definition-des-sous-reseaux-vlans)
- [6. Application des Permissions (Moindre Privilège)](#6-application-des-permissions-moindre-privilege)
- [7. Dérogation de sécurité AppArmor](#7-derogation-de-securite-apparmor)
- [8. Validation et Déploiement](#8-validation-et-deploiement)

## 2. Contexte

Le service Kea DHCPv4 est le composant central d'attribution IP de l'infrastructure ECOCERT. Cette procédure documente la transition vers une architecture modulaire en cascade (Top-Down) utilisant un fichier d'indexation. Elle intègre le durcissement du service (mode Authoritative), la redondance DNS, et l'observabilité via la journalisation, conformément aux standards d'ingénierie de production.

## 3. Configuration Globale (Fichier Maître)

3.1. **Définition des paramètres de base et de sécurité.** Édition du fichier maître pour configurer l'interface d'écoute, la redondance DNS, forcer l'autorité du serveur, définir l'inclusion de l'annuaire et activer les journaux d'événements.

```json title="/etc/kea/kea-dhcp4.conf" hl_lines="4 14-17 21 24-32"
{
    "Dhcp4": {
        "interfaces-config": {
            "interfaces": [ "ens18" ]
        },
        "control-socket": {
            "socket-type": "unix",
            "socket-name": "/run/kea/kea-dhcp4-ctrl.sock"
        },
        "lease-database": {
            "type": "memfile",
            "lfc-interval": 3600
        },
        "valid-lifetime": 4000,
        "authoritative": true,
        "option-data": [
            {
                "name": "domain-name-servers",
                "data": "172.16.54.1, 1.1.1.1"
            },
            {
                "name": "domain-name",
                "data": "local.ecocert4.fr"
            }
        ],
        "subnet4": [
            <?include "/etc/kea/subnets/annuaires-reseaux.conf"?>
        ],
        "loggers": [
            {
                "name": "kea-dhcp4",
                "output-options": [
                    { "output": "/var/log/kea/kea-dhcp4.log", "maxsize": 10485760, "maxver": 5 }
                ],
                "severity": "INFO"
            }
        ]
    }
}
```

- `ens33` : Interface réseau d'écoute du service DHCP.
- `authoritative` : Permet au serveur de répondre par un DHCPNAK aux requêtes non valides, assainissant le trafic réseau.
- `domain-name-servers` : Déclaration du contrôleur AD local et d'un résolveur public en secours (Failover).
- `<?include ... ?>` : Directive de préprocesseur ciblant le fichier d'indexation.
- `loggers` : Configuration de la journalisation avec rotation automatique (10 Mo, 5 archives maximum).

## 4. Création de l'Index d'Inclusion

4.1. **Centralisation des configurations réseaux.** Création du fichier annuaire agissant comme unique point d'entrée pour les sous-réseaux.

```text title="/etc/kea/subnets/annuaires-reseaux.conf"
<?include "/etc/kea/subnets/vlan11-admin.conf"?>,
<?include "/etc/kea/subnets/vlan21-certif.conf"?>,
<?include "/etc/kea/subnets/vlan31-referentiels.conf"?>,
<?include "/etc/kea/subnets/vlan41-formapro.conf"?>,
<?include "/etc/kea/subnets/vlan61-conseiltech.conf"?>,
<?include "/etc/kea/subnets/vlan71-techniques.conf"?>,
<?include "/etc/kea/subnets/vlan81-wifi.conf"?>
```

> [!note] Syntaxe stricte
> La dernière ligne du fichier annuaire ne doit **jamais** comporter de virgule finale afin de maintenir l'intégrité de la structure du tableau JSON généré en mémoire.

## 5. Définition des Sous-Réseaux (VLANs)

5.1. **Isolation des périmètres.** Création des fichiers individuels par VLAN avec définition stricte de l'identifiant (ID) et de la passerelle de routage.

```json title="/etc/kea/subnets/vlan11-admin.conf" hl_lines="2 5-7"
{
    "id": 11,
    "subnet": "192.168.4.0/26",
    "pools": [ { "pool": "192.168.4.10 - 192.168.4.50" } ],
    "option-data": [
        { "name": "routers", "data": "192.168.4.62" }
    ]
}
```

- `id` : Identifiant forcé correspondant au numéro du VLAN, essentiel pour le débogage et la future configuration de Haute Disponibilité (HA).
- `routers` : Distribue l'adresse IP de l'interface virtuelle du commutateur L3 (passerelle) aux clients pour permettre le routage inter-VLAN.

*Répéter cette opération pour l'ensemble des fichiers listés dans l'annuaire, en adaptant l'ID, le sous-réseau, le pool et la passerelle associée.*

## 6. Application des Permissions (Moindre Privilège)

6.1. **Sécurisation des accès fichiers (Configuration).** Restreindre les droits de l'arborescence de configuration pour le compte de service système de Kea.

```bash
sudo chown -R root:_kea /etc/kea/subnets
sudo chmod 750 /etc/kea/subnets
sudo chmod 640 /etc/kea/subnets/*
```

6.2. **Création et sécurisation du dossier des journaux.** Assurer les droits d'écriture pour la rotation des logs.

```bash
sudo mkdir -p /var/log/kea
sudo chown _kea:_kea /var/log/kea
sudo chmod 755 /var/log/kea
```

## 7. Dérogation de sécurité AppArmor

7.1. **Mise à jour du profil de sécurité du noyau.** Autoriser le service Kea à créer son fichier de verrouillage (`.sock.lock`) et écrire ses logs personnalisés.

Éditer le fichier d'exceptions locales :
```bash
sudoedit /etc/apparmor.d/local/usr.sbin.kea-dhcp4
```

Ajouter les directives d'autorisation :
```text title="/etc/apparmor.d/local/usr.sbin.kea-dhcp4"
# Autoriser le socket, les fichiers lock et le PID
/run/kea/** rwk,

# Autoriser l'écriture dans le dossier des logs personnalisés
/var/log/kea/** rwk,
```

7.2. **Rechargement du profil.** Appliquer les nouvelles règles de sécurité sans redémarrer le serveur.

```bash
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.kea-dhcp4
```

## 8. Validation et Déploiement

8.1. **Vérification syntaxique.** Test du fichier maître et de l'ensemble de ses inclusions JSON avant redémarrage.

```bash
sudo kea-dhcp4 -t -c /etc/kea/kea-dhcp4.conf
```

- `-t` : Exécute le démon en mode test pour valider l'arbre de configuration sans impacter la production.
- `-c` : Spécifie explicitement le chemin absolu du fichier de configuration à analyser.

8.2. **Redémarrage du service.** Application de la configuration en cas de succès du test.

```bash
sudo systemctl restart kea-dhcp4-server
sudo systemctl status kea-dhcp4-server
sudo tail -f /var/log/kea/kea-dhcp4.log # Voir les logs en live pour la séquence DORA (Discover, Offer, Request, Acknowledge)
```


*[Source - Kea Dhcpv4 Serveur](https://kea.readthedocs.io/en/stable/arm/dhcp4-srv.html)*