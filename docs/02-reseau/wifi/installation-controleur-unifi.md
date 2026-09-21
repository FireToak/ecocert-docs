---
description: Procédure d'installation et de configuration du contrôleur UniFi OS Server sur un environnement Debian.
---

# Installation du controleur Unifi sur Debian

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"
    - **Auteur :** Louis MEDO
    - **Date :** 21/09/2026
    - **Domaine :** Réseau

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Installation des dépendances](#3-installation-des-dependances)
- [4. Téléchargement de l'installeur](#4-telechargement-de-linstalleur)
- [5. Exécution de l'installeur](#5-execution-de-linstalleur)

## 2. Contexte

Le contrôleur UniFi OS centralise la gestion et le monitoring des équipements réseaux Ubiquiti (points d'accès, switchs). Déployé sur Debian, il repose sur Podman pour conteneuriser ses services, assurant ainsi une isolation sécurisée et facilitant les mises à jour sans impacter l'OS hôte.

## 3. Installation des dépendances {#3-installation-des-dependances}

3.1. **Mise à jour et installation des paquets requis.** Actualise les dépôts et installe les composants nécessaires à la conteneurisation du service.

```bash
sudo apt-get update && sudo apt-get install podman slirp4netns
```

- `sudo` : Exécute la commande avec les privilèges administrateur (root).
- `apt-get update` : Met à jour la liste locale des paquets disponibles depuis les dépôts.
- `apt-get install` : Installe les paquets spécifiés en argument.
- `podman` : Moteur de conteneurs sans démon central (daemonless), utilisé ici pour isoler UniFi OS.
- `slirp4netns` : Outil gérant la mise en réseau des conteneurs Podman lancés dans l'espace utilisateur (rootless).

## 4. Téléchargement de l'installeur {#4-telechargement-de-linstalleur}

4.1. **Récupération du binaire.** Télécharge l'archive exécutable du serveur UniFi OS depuis les serveurs officiels. [Lien vers UNIFI RELEASE](https://ui.com/download).

```bash
cd /tmp
curl -O https://fw-download.ubnt.com/data/unifi-os-server/5172-linux-x64-5.1.42-12e9e3cf-8f8b-4e54-928c-76b80a10c8a4.42-x64
```

- `curl` : Outil en ligne de commande de transfert de données réseau.
- `-O` : Option (majuscule) ordonnant à curl de sauvegarder le fichier avec le même nom que sur le serveur distant.

## 5. Exécution de l'installeur {#5-execution-de-linstalleur}

5.1. **Ajout des droits et lancement.** Rend le binaire téléchargé exécutable, puis initie le processus de déploiement.

```bash
chmod +x 5172-linux-x64-5.1.42-12e9e3cf-8f8b-4e54-928c-76b80a10c8a4.42-x64
sudo ./5172-linux-x64-5.1.42-12e9e3cf-8f8b-4e54-928c-76b80a10c8a4.42-x64
```

- `chmod` : Commande Unix permettant de modifier les permissions d'un fichier.
- `+x` : Ajoute le droit d'exécution au fichier ciblé.
- `./` : Spécifie au shell d'exécuter le fichier présent dans le répertoire courant.

## 6. Post-installation

6.1. **Connexion à l'interface** Finalisation de l'intégration dans l'infrastructure via l'interface UI `https://<votre-ip>:11443`.

> [!note] Administration et équipements
> Une fois installé, créez un compte UI (ou connectez-vous avec un existant) via l'interface web pour activer la gestion à distance (*Site Manager*). Procédez ensuite à l'adoption de vos équipements (APs, Switchs) en suivant les instructions d'adoption *UniFi Device Adoption*.

## 6. Ressources

- [Self-Hosting UniFi](https://help.ui.com/hc/en-us/articles/34210126298775-Self-Hosting-UniFi)
