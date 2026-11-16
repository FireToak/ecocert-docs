---
description: Déploiement et configuration de step-ca avec ACME (30 jours), PKI locale et compte de service.
---

# Configuration de step-ca

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 09/11/2026
> - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Création du compte de service et des répertoires](#3-creation-du-compte-de-service-et-des-repertoires)
- [4. Configuration de step-ca](#4-configuration-de-step-ca)
- [5. Configuration du provisioner ACME](#5-configuration-du-provisioner-acme)
- [6. Configuration du service systemd](#6-configuration-du-service-systemd)

## 2. Contexte

step-ca (Smallstep) est une autorité de certification (CA) privée permettant l'émission et la gestion automatisée de certificats TLS. Déployé sur Debian, ce composant s'intègre à l'infrastructure d'automatisation (IaC) pour sécuriser les flux internes. Il est configuré avec une PKI complète (autorité racine et autorité intermédiaire) locale, un provisioner ACME (certificats valables 30 jours pour faciliter leur renouvellement) et fonctionne avec un compte de service dédié, conformément au principe du moindre privilège.

## 3. Création du compte de service et des répertoires {#3-creation-du-compte-de-service-et-des-repertoires}

3.1. **Création du compte système non privilégié.** Crée un utilisateur dédié pour exécuter le service sans les droits `root`.

```bash title="Création du compte de service"
sudo useradd --system --user-group --home-dir /etc/step-ca --shell /usr/sbin/nologin step
sudo install --directory --owner=step --group=step --mode=700 /etc/step-ca
```

- `sudo` : Exécute la commande avec les privilèges nécessaires à la création d'un compte système.
- `useradd` : Crée le compte utilisateur `step`.
- `--system` : Crée un compte système destiné à l'exécution d'un service.
- `--user-group` : Crée également un groupe primaire portant le nom `step`.
- `--home-dir /etc/step-ca` : Définit le répertoire de configuration comme répertoire personnel.
- `--shell /usr/sbin/nologin` : Empêche toute connexion interactive avec ce compte.
- `install --directory` : Crée le répertoire et applique ses propriétaires et permissions en une seule commande.
- `--owner=step --group=step` : Attribue le répertoire au compte et au groupe du service.
- `--mode=700` : Autorise uniquement le compte `step` à lire, modifier et parcourir ce répertoire.

## 4. Configuration de step-ca

4.1. **Création du fichier de mot de passe de la PKI.** Le fichier protège les clés privées de l'autorité de certification. Il ne doit pas contenir un mot de passe réel dans l'historique du shell ou dans la documentation.

```bash title="Création du fichier de mot de passe"
sudo install --owner=step --group=step --mode=600 /dev/null /etc/step-ca/password.txt
sudoedit /etc/step-ca/password.txt
```

- `install /dev/null` : Crée un fichier vide sans recopier de contenu provenant d'une commande.
- `--owner=step --group=step` : Rend le fichier lisible par le compte qui exécutera step-ca.
- `--mode=600` : Autorise uniquement le compte `step` et `root` à lire ou modifier le fichier.
- `sudoedit` : Ouvre le fichier avec l'éditeur configuré par Debian, sans donner directement les droits `root` à l'éditeur.

Saisir un mot de passe robuste dans l'éditeur, enregistrer le fichier, puis le fermer.

4.2. **Initialisation de l'autorité.** Génère les clés asymétriques de l'autorité racine et de l'autorité intermédiaire en fournissant les paramètres nécessaires sans invite interactive.

```bash title="Initialisation de la CA"
sudo -u step STEPPATH=/etc/step-ca step ca init \
  --name="Ecocert4 PKI" \
  --dns="pki.ecocert4.fr" \
  --address=":443" \
  --provisioner="ecocert4" \
  --password-file="/etc/step-ca/password.txt"
```

- `sudo -u step` : Exécute la commande avec le compte propriétaire de la configuration.
- `STEPPATH=/etc/step-ca` : Remplace le répertoire step par défaut (`~/.step`) par le répertoire de la PKI.
- `step ca init` : Initialise une nouvelle PKI et génère sa configuration ainsi que ses certificats.
- `--name="Ecocert4 PKI"` : Définit le nom lisible de l'autorité de certification.
- `--dns="pki.ecocert4.fr"` : Ajoute le nom DNS de l'autorité au certificat TLS du serveur.
- `--address=":443"` : Configure step-ca pour écouter sur le port HTTPS 443 sur toutes les interfaces.
- `--provisioner="ecocert4"` : Crée le provisioner initial utilisé pour administrer l'autorité.
- `--password-file="/etc/step-ca/password.txt"` : Indique le fichier utilisé pour chiffrer et déchiffrer les clés privées.

## 5. Configuration du provisioner ACME

5.1. **Ajout du protocole ACME.** Permet aux clients (par exemple Certbot ou Traefik) de demander et de renouveler automatiquement des certificats.

```bash title="Ajout du provisioner ACME"
sudo -u step STEPPATH=/etc/step-ca step ca provisioner add acme --type ACME \
  --x509-min-dur=720h \
  --x509-default-dur=720h \
  --x509-max-dur=720h
```

- `sudo -u step` : Exécute la modification avec le compte propriétaire de la configuration.
- `STEPPATH=/etc/step-ca` : Indique à la CLI l'emplacement de la configuration de step-ca.
- `step ca provisioner add` : Ajoute un provisioner à l'autorité de certification.
- `acme` : Nom identifiant le provisioner ACME.
- `--type ACME` : Active le protocole Automated Certificate Management Environment.
- `--x509-min-dur=720h` : Impose une durée minimale de certificat de 720 heures, soit 30 jours.
- `--x509-default-dur=720h` : Définit une durée de 30 jours lorsque le client n'en demande pas.
- `--x509-max-dur=720h` : Empêche une demande de certificat dépassant 30 jours.

## 6. Configuration du service systemd

6.1. **Automatisation du lancement.** Création de l'unité systemd pour gérer le cycle de vie du processus en arrière-plan.

```bash title="Création de l'unité systemd"
sudoedit /etc/systemd/system/step-ca.service
```

- `sudoedit` : Ouvre le fichier d'unité avec les privilèges nécessaires, sans exécuter l'éditeur en tant que `root`.

```ini title="/etc/systemd/system/step-ca.service"
[Unit]
Description=step-ca service
After=network.target

[Service]
User=step
Group=step
Environment=STEPPATH=/etc/step-ca
ExecStart=/usr/bin/step-ca /etc/step-ca/config/ca.json --password-file /etc/step-ca/password.txt
Restart=on-failure
RestartSec=10
AmbientCapabilities=CAP_NET_BIND_SERVICE
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
```

- `[Unit]`, `[Service]` et `[Install]` : Sections systemd définissant les métadonnées, l'exécution et l'activation du service au démarrage.
- `After=network.target` : Demande le démarrage du service après l'initialisation du réseau.
- `User=step` et `Group=step` : Garantissent que le démon s'exécute avec des droits restreints.
- `Environment=STEPPATH=/etc/step-ca` : Fournit au processus le chemin de configuration utilisé par step-ca.
- `ExecStart` : Lance step-ca avec sa configuration JSON et le fichier contenant le mot de passe des clés privées.
- `Restart=on-failure` et `RestartSec=10` : Redémarrent le service après un échec, avec un délai de 10 secondes.
- `AmbientCapabilities=CAP_NET_BIND_SERVICE` : Autorise le compte non privilégié à écouter sur le port 443.
- `LimitNOFILE` : Augmente la limite de descripteurs de fichiers pour soutenir un volume important de requêtes ACME simultanées.
- `WantedBy=multi-user.target` : Rattache le service à la cible standard de démarrage des services système.

6.2. **Activation et démarrage.** Prise en compte du nouveau service et lancement du démon.

```bash title="Activation du service"
sudo systemctl daemon-reload
sudo systemctl enable --now step-ca
```

- `systemctl daemon-reload` : Recharge les fichiers d'unité afin que systemd prenne en compte le nouveau service.
- `systemctl enable --now step-ca` : Active le démarrage automatique du service et le démarre immédiatement.

Vérifier ensuite l'état du service :

```bash title="Vérification du service"
sudo systemctl status step-ca --no-pager
```

- `systemctl status step-ca` : Affiche l'état courant du service et les derniers messages disponibles.
- `--no-pager` : Affiche directement la sortie dans le terminal sans ouvrir de pager interactif.
