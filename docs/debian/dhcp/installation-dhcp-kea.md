---
description: Déploiement et vérification du serveur ISC Kea DHCP IPv4 sur Debian 13.
---

# Installation kea-dhcp4 sur debian 13

![Bannière CUB](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** KADA Amine
    - **Date :** 07/09/2026
    - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Prérequis et validation réseau](#3-prerequis-et-validation-reseau)
- [4. Installation du service Kea DHCP](#4-installation-du-service-kea-dhcp)
- [5. Vérification du déploiement](#5-verification-du-deploiement)

## 2. Contexte

L'infrastructure nécessite le déploiement d'un service DHCP performant et moderne pour distribuer automatiquement les configurations réseaux (Adresses IP, masques, passerelles, serveurs DNS). **ISC Kea** est la nouvelle génération de serveur DHCP de l'ISC, remplaçant l'ancien *ISC DHCP Server*. Il se distingue par l'utilisation d'une configuration structurée en **JSON** (facilitant la lisibilité et l'automatisation) et par une API permettant des rechargements à chaud sans interruption de service. Ce document standardise l'installation du module IPv4 sur le nœud `pve2` (ID `20804`), machine `DHCPECOCERT` sous Debian 13.

## 3. Prérequis et validation réseau

!!! warning "Exigence d'infrastructure"

    Le serveur DHCP doit obligatoirement posséder une adresse IP statique. Dans ce contexte, l'interface réseau est provisionnée avec l'adresse `172.16.54.2` (Passerelle : `172.16.54.253`).

3.1. **Vérification de la configuration réseau locale.** Identifier l'interface réseau logique (ex: `ens18`) et valider la présence de l'IP statique requise pour l'écoute du service.

```bash title="check_network.sh"
ip a
```

- `a` : Affiche l'ensemble des adresses IP et l'état de la couche liaison pour toutes les interfaces.

3.2. **Test de la résolution et du routage externe.** Confirmer que le système d'exploitation accède à Internet, condition sine qua non pour l'interrogation des dépôts de paquets APT.

```bash title="check_internet.sh"
ping -c 4 8.8.8.8
```

- `-c 4` : Limite la transmission à 4 datagrammes ICMP Echo Request.
- `8.8.8.8` : Cible externe (DNS public) permettant de valider le routage via la passerelle par défaut.

## 4. Installation du service Kea DHCP

4.1. **Synchronisation des dépôts.** Mettre à jour l'index local des paquets pour s'assurer de récupérer la version stable la plus récente du service.

```bash title="apt_update.sh"
sudo apt-get update
```

- `update` : Interroge les miroirs Debian configurés pour reconstruire le catalogue local des paquets disponibles.

4.2. **Déploiement du démon.** Installation du composant applicatif responsable du traitement des requêtes DHCP pour le protocole IPv4.

```bash title="apt_install.sh" hl_lines="1"
sudo apt-get install kea-dhcp4-server -y
```

- `install` : Demande le déploiement du paquet cible et la résolution de ses dépendances.
- `-y` : Force l'acceptation automatique des changements (mode non-interactif adapté à l'automatisation).

## 5. Vérification du déploiement

5.1. **Contrôle de l'état du service système.** Vérifier la bonne création de l'unité `systemd` et le démarrage initial du processus Kea.

```bash title="systemctl_status.sh"
sudo systemctl status kea-dhcp4-server
```

- `status` : Affiche l'état d'exécution actuel du daemon (ex: *active (running)*) ainsi que les derniers événements journalisés (logs).

!!! success "Critère de réussite"

    L'installation est considérée comme valide si la commande précédente indique que le service est actif. Le serveur est alors prêt à recevoir sa configuration JSON spécifique à l'infrastructure.