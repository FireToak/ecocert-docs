---
description: Fiche conceptuelle sur le fonctionnement d'AppArmor et la gestion des politiques de sécurité MAC sous Debian.
---

# Concepts Avancés : Sécurité du Noyau avec AppArmor

> [!note] Informations
> - **Auteur :** Amine KADA
> - **Date :** 29/09/2026
> - **Domaine :** Cybersécurité / Administration Système

---

## 1. Introduction : Qu'est-ce qu'AppArmor ?

**AppArmor** (Application Armor) est un module de sécurité intégré directement dans le noyau Linux. Son objectif principal est de confiner les programmes (comme un serveur web, un serveur DHCP ou une base de données) dans un périmètre d'action strictement délimité, afin de limiter les dégâts en cas de piratage.

Il repose sur le principe du **moindre privilège** : un programme ne peut faire que ce qui lui est explicitement autorisé.

## 2. La différence fondamentale : DAC vs MAC

Pour comprendre AppArmor, il faut opposer deux modèles de sécurité :

### A. Le modèle classique : DAC (Discretionary Access Control)
C'est le système de permissions standard sous Linux (`chmod`, `chown`).
- **Fonctionnement :** La sécurité est basée sur l'utilisateur. Si le processus `_kea` a les droits d'écriture (ex: `750`) sur le dossier `/var/log/kea/`, il peut y écrire.
- **La faille :** Si un pirate exploite une vulnérabilité dans le service Kea, il prend le contrôle du processus avec les droits de l'utilisateur `_kea`. Il peut alors naviguer partout où cet utilisateur a accès.

### B. Le modèle avancé : MAC (Mandatory Access Control)
C'est le système utilisé par AppArmor (ou son équivalent SELinux).
- **Fonctionnement :** La sécurité est basée sur le programme lui-même, indépendamment de l'utilisateur. Le noyau Linux consulte une "liste blanche" (un profil). 
- **La protection :** Même si un pirate prend le contrôle du processus en tant que `root` ou `_kea`, il sera prisonnier du profil AppArmor. S'il tente d'ouvrir le fichier des mots de passe (`/etc/shadow`) ou de lancer un script malveillant, le noyau bloquera l'action instantanément (Accès refusé).

## 3. Le fonctionnement par "Profils"

AppArmor utilise des fichiers texte appelés **profils**, stockés dans `/etc/apparmor.d/`. Chaque profil dicte les règles d'un programme spécifique (fichiers lisibles, dossiers inscriptibles, capacités réseau).

Un profil peut être dans l'un des deux modes suivants :
1. **Enforce (Application) :** Le mode par défaut. Toute action non autorisée est bloquée brutalement et journalisée.
2. **Complain (Apprentissage/Plainte) :** Le mode de débogage. Les actions non autorisées sont permises, mais elles génèrent une alerte dans les logs. Très utile pour créer un profil sans casser un service.

## 4. Cas Pratique : Le blocage de Kea DHCP

Lors du déploiement de l'architecture Kea, un conflit s'est produit entre nos bonnes pratiques d'administration et les règles strictes d'AppArmor.

**Le problème :**
Nous avons configuré Kea pour écrire ses journaux dans un dossier personnalisé (`/var/log/kea/`). Bien que les permissions Linux classiques (DAC) étaient correctes (`chown _kea:_kea`), le service plantait au démarrage. 

**L'explication :**
Le profil par défaut d'AppArmor pour Kea (`/etc/apparmor.d/usr.sbin.kea-dhcp4`) ne prévoyait pas l'existence de ce dossier personnalisé. Le noyau a donc appliqué la règle MAC et bloqué la création du fichier (erreur `apparmor="DENIED" operation="mknod"`).

**La résolution (Bonne pratique) :**
Il ne faut jamais modifier le profil principal (qui serait écrasé à la prochaine mise à jour du paquet). Il faut utiliser le répertoire des surcharges locales :
1. Édition de `/etc/apparmor.d/local/usr.sbin.kea-dhcp4`
2. Ajout de la règle autorisant l'écriture : `/var/log/kea/** rwk,`
3. Rechargement dynamique dans le noyau : `apparmor_parser -r`

## 5. Mémo des commandes AppArmor (Cheat Sheet)

Voici les commandes essentielles pour diagnostiquer et gérer AppArmor au quotidien :

| Commande | Action |
| :--- | :--- |
| `sudo aa-status` | Affiche l'état d'AppArmor et liste tous les profils chargés (Enforce ou Complain). |
| `sudo dmesg \| grep -i apparmor` | Lit les logs du noyau pour repérer les blocages de sécurité récents. |
| `sudo aa-complain <nom_profil>` | Passe un profil en mode permissif (nécessite le paquet *apparmor-utils*). |
| `sudo aa-enforce <nom_profil>` | Remet un profil en mode strict (blocage). |
| `sudo apparmor_parser -r <fichier>` | Recharge un profil dans le noyau après une modification de ses règles. |