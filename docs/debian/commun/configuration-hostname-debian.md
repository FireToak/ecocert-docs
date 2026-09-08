---
description: Procédure de configuration, modification et vérification du nom d'hôte sur un système Debian.
---

# Configuration du hostname

![Bannière CUB](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** Amine KADA
    - **Date :** 08/09/2026
    - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Vérification de l'état actuel](#3-verification-de-letat-actuel)
- [4. Changement du nom d'hôte](#4-changement-du-nom-dhote)
- [5. Vérification de la persistance et résolution](#5-verification-de-la-persistance-et-resolution)

## 2. Contexte

La configuration rigoureuse du nom d'hôte (hostname) est primordiale pour l'identification unique et standardisée des serveurs au sein de l'infrastructure CUB. Ce paramètre impacte directement la journalisation centralisée, les agents de supervision, le maillage de services (Service Mesh) et la résolution DNS interne. Une identité serveur correcte garantit la fiabilité des flux réseau inter-applicatifs et la cohérence de l'automatisation de type Infrastructure as Code (IaC).

## 3. Vérification de l'état actuel

3.1. **Consultation des paramètres d'hôte.** Identifier l'identité courante du serveur avant d'appliquer la nouvelle norme de nommage.

```bash title="Commandes_Verification_Initiale.sh"
hostnamectl status
hostname
hostnamectl --static
hostnamectl --transient
hostnamectl --pretty
```

- `status` : Affiche l'état global du système, y compris l'architecture et les différents hostnames.
- `--static` : Restreint l'affichage au nom d'hôte persistant (stocké dans `/etc/hostname`).
- `--transient` : Affiche le nom d'hôte dynamique (généralement attribué par le serveur DHCP ou le cloud-init).
- `--pretty` : Affiche la version formatée et lisible par l'utilisateur du nom d'hôte.

## 4. Changement du nom d'hôte

!!! warning "Avertissement de redémarrage de services"

    Bien que la modification du hostname soit appliquée à chaud, certains processus (ex: `syslog`, agents de monitoring) peuvent nécessiter un redémarrage pour acquitter la nouvelle valeur.

4.1. **Définition de la nouvelle identité cible.** Utilisation de l'outil d'administration `hostnamectl` pour altérer le hostname localement de manière persistante.

```bash title="Modification_Hostname.sh" hl_lines="1"
sudo hostnamectl set-hostname api-prod-eu1-01
```

- `set-hostname` : Argument ordonnant au démon système de mettre à jour le nom d'hôte à la fois en mémoire et sur le disque.
- `api-prod-eu1-01` : Valeur cible respectant la nomenclature d'infrastructure (Rôle-Environnement-Région-Index).

## 5. Vérification de la persistance et résolution

5.1. **Vérification de l'écriture disque.** S'assurer que le daemon a bien modifié le fichier de configuration statique.

```bash title="Verification_Persistance.sh"
cat /etc/hostname
```

5.2. **Test de la résolution système.** Vérifier que le système d'exploitation parvient à résoudre le nouveau nom d'hôte en interrogeant les bases locales de résolution (comme le fichier `/etc/hosts` ou le service NSS).

```bash title="Verification_Resolution.sh" hl_lines="1-2"
getent hosts api-prod-eu1-01
hostname -f
```

- `hosts` : Spécifie la base de données de noms ciblée par l'utilitaire `getent`.
- `-f` : Demande l'affichage du FQDN (Fully Qualified Domain Name) de la machine.

5.3. **Validation de l'état système final.** Contrôler la bonne prise en compte globale par `systemd`.

```bash title="Validation_Finale.sh"
hostnamectl status
```

!!! success "Critère de réussite"

    L'opération est considérée comme validée si les retours de la vérification finale affichent systématiquement le nouveau hostname statique `api-prod-eu1-01` et que la commande de résolution DNS interne s'exécute sans erreur.