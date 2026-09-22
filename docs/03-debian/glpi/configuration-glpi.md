
---

description: Configuration du moteur GLPI 11, du helpdesk (ITIL) et déploiement de l'inventaire automatisé via GPO.

---

# Configuration du serveur GLPI (Helpdesk & Inventaire)

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)


- **Auteur :** Amine KADA
- **Classe :** BTS SIO 2 - Option SISR (Tours)
- **Date :** 22 Septembre 2026
- **Domaine :** Debian / GLPI

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Déploiement et Sécurisation du Serveur](#3-deploiement-et-securisation-du-serveur)
- [4. Configuration du Helpdesk (ITIL)](#4-configuration-du-helpdesk-itil)
- [5. Automatisation de l'Inventaire de Parc (GPO)](#5-automatisation-de-linventaire-de-parc-gpo)

## 2. Contexte

- **Serveur GLPI :** GLPIECOCERT
- **IP et Passerelle :** `172.16.54.40` (Passerelle : `172.16.54.253`)
- **Système d'exploitation :** Debian 13
- **Services en charge :** Gestion d'inventaire et de tickets d'incident

## 3. Déploiement et Sécurisation du Serveur

- **Moteur GLPI :** Installation de la version 11 sur la machine virtuelle Debian.
- **Sécurisation Web :** Configuration du serveur web (Apache/Nginx) pour restreindre la lecture stricte au dossier racine `/public`. Cette action répond aux exigences de sécurité de GLPI 11 et empêche l'exposition des fichiers de configuration sensibles de l'infrastructure.

## 4. Configuration du Helpdesk (ITIL)

Pour structurer la gestion des tickets et respecter les processus ITIL, l'assistance est divisée entre les deux administrateurs réseau selon leurs domaines d'expertise.

### 4.1. Création des groupes de techniciens

- **Équipe Réseau & Accès :** Créé avec le paramètre `Peut être assigné : Oui` pour pouvoir y affecter des tickets.
- **Équipe Serveurs & Systèmes :** Créé avec le paramètre `Peut être assigné : Oui`.

### 4.2. Création des comptes administrateurs

- **Olivier TONDET (`otondet`) :**
  - Profil : *Admin* (sur l'entité racine).
  - Affectation : Associé au groupe **Équipe Réseau & Accès**.
- **Pamela TREMO (`ptremo`) :**
  - Profil : *Admin* (sur l'entité racine).
  - Affectation : Associée au groupe **Équipe Serveurs & Systèmes**.

### 4.3. Paramétrage des catégories de tickets (Routage automatique)

Afin d'automatiser le flux de travail (workflow ITIL), les catégories d'incidents sont liées aux groupes pour un routage sans intervention manuelle :

- **Catégorie "Problème réseau / Interconnexion" :** Liée au groupe technique en charge *Équipe Réseau & Accès*. Les tickets tombent directement dans la file d'attente d'Olivier.
- **Catégorie "Problème Serveur / AD" :** Liée au groupe technique en charge *Équipe Serveurs & Systèmes*. Les tickets tombent directement dans la file d'attente de Pamela.

## 5. Automatisation de l'Inventaire de Parc (GPO)

La remontée du matériel et des logiciels est entièrement automatisée pour s'intégrer au domaine Active Directory (`local.ecocert4.fr`).

### 5.1. Stratégie de déploiement

Création d'une GPO sur le contrôleur de domaine Windows Server 2025 (`ADECOCERT`) pour installer silencieusement le paquet `GLPI-Agent.msi` (version 11.0.9) sur les postes clients.

### 5.2. Configuration de la communication Agent/Serveur

1. **Clé de registre :** Ajout d'une configuration via la GPO avec la création de la clé `HKEY_LOCAL_MACHINE\SOFTWARE\GLPI-Agent` et la valeur chaîne `server`.
2. **Ajustement de l'URL :** La valeur `server` est définie sur l'URL courte `http://172.16.54.40/` (au lieu du chemin classique `/front/inventory.php`). Cela permet de contourner l'erreur HTTP 404 causée par la restriction de sécurité du dossier web (`/public`) mise en place lors de l'installation.

### 5.3. Validation

Après application des stratégies et redémarrage du service local *GLPI Agent*, les postes communiquent avec le serveur de manière autonome.

```cmd title="Terminal (Client Windows)"
gpupdate /force
```

- **Vérification :** Naviguez dans **Parc > Ordinateurs** sur l'interface GLPI. Les postes Windows doivent remonter automatiquement avec leurs configurations exhaustives.
