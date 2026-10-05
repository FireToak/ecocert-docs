# 👋 Bienvenue

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

## 1. 🧭 Contexte

ECOCERT est un organisme indépendant spécialisé dans la certification de pratiques durables et de l'agriculture biologique. Afin d'accompagner cette demande croissante, le projet consiste à déployer et documenter une infrastructure sécurisée permettant d'offrir au grand public la consultation en ligne des certificats, et aux producteurs un système de gestion des demandes de conversion. L'environnement technologique s'appuie sur une ferme de serveurs Proxmox, des équipements de commutation CISCO, un pare-feu Stormshield, ainsi que des serveurs d'applications et de bases de données.

## 2. 🗺️ Navigation

L'arborescence de la documentation repose sur une logique de classement structurée : on identifie d'abord le système d'exploitation hébergeant le service, puis le nom de l'outil concerné, et enfin les fichiers Markdown correspondants aux procédures. Un dossier racine indépendant regroupe toutes les ressources d'architecture réseau.

```text
.
├── [type-os]/
│   └── [nom-outil]/
│       ├── procedure-1.md
│       └── procedure-2.md
└── ressources/
    ├── schemas.md
    ├── plan-adressage.md
    ├── plan-routage.md
    └── table-nat.md
```

## 3. 📚 Contenu

<!-- 
NE PAS SUPPRIMER CE COMMENTAIRE !!!

Message pour l'ia : Tu mets à jour avec les informations données en entrée dans le prompt et en utilisant la structure suivante

### [Catégorie | Ex. Cybersécurité, Administration et supervision des réseaux, Administration Windows, Cybersécurité, Exploitation des services]

* **[Nom de la technologie mise en place]** : [Bref description du contexte de mise en place de cette technologie]
-->

### Administration Windows

* **Active Directory** : Mise en place de l'annuaire centralisé pour la gestion des identités, des accès utilisateurs et de l'authentification sur le domaine.
* **PowerShell** : Automatisation de la création, de la modification et de la suppression des comptes et groupes Active Directory.
* **GPO et partages réseau** : Administration des stratégies de groupe ainsi que des lecteurs partagés destinés aux utilisateurs et aux administrateurs.
* **Bureau à distance et Agent QEMU Guest** : Administration et intégration des postes et serveurs Windows virtualisés.
* **SQL Server 2022** : Déploiement du système de gestion de bases de données relationnelles (SGBD) hébergeant les données de certification.

### Exploitation des services

* **Debian 13** : Administration des serveurs Linux, de leur configuration système et de leurs services.
* **Kea DHCP** : Déploiement et automatisation de la configuration du service DHCP à partir du plan d'adressage VLSM.
* **GLPI et NAS** : Mise en place des services de gestion de parc, d'inventaire et de stockage réseau.
* **Ansible** : Gestion centralisée et automatisée des postes Debian avec des playbooks d'installation, de mise à jour et de durcissement.
* **Proxmox** : Gestion de la ferme de serveurs pour la virtualisation et la haute disponibilité de l'infrastructure.
* **Apache 2.4.56, GlassFish 6, PHP et Java** : Déploiement des serveurs Web et applicatifs pour héberger les services en ligne destinés au public et aux producteurs.

### Administration et supervision des réseaux

* **Cisco (niveaux 2 et 3)** : Configuration, réinitialisation et validation des commutateurs pour assurer le routage, la segmentation VLAN et la connectivité globale.
* **Stormshield SN 210** : Configuration du routage, des interfaces et de la translation d'adresses (NAT) du pare-feu.
* **UniFi** : Installation du contrôleur, ajout des équipements et déploiement des réseaux Wi-Fi.
* **Plans et recettes réseau** : Formalisation du plan d'adressage, des tables de routage et des tests de validation de l'infrastructure.

### Cybersécurité

* **Stormshield SN 210** : Filtrage des flux réseau, sécurisation des accès externes et protection de l'infrastructure interne.

### Documentation

* **Git et GitHub** : Versionnement des procédures, travail par branches, revues de code et intégration des contributions par Pull Request.
* **GitHub Actions et Zensical** : Construction et déploiement automatisés du site de documentation après modification de la branche principale.

## 4. 🧠 Compétences du référentiel de BTS SIO

<!-- 
NE PAS SUPPRIMER CE COMMENTAIRE !!!

Message pour l'ia : Tu mets à jour avec les informations données en entrée dans le prompt et en utilisant la structure suivante

### [Nom de la compétence principale]

* **[Sous-compétence mobilisée]** : justification
-->

### Gérer le patrimoine informatique

* **Recenser et identifier les ressources numériques** : Mise à jour de l'annuaire des machines et élaboration des schémas, du plan d'adressage IP, des tables de routage et de la table NAT.
* **Exploiter des référentiels, normes et standards adoptés par le prestataire informatique** : Application d'une architecture structurée par VLAN, d'un plan d'adressage VLSM et de procédures standardisées de configuration et de recette.
* **Mettre en place et vérifier les niveaux d'habilitation associés à un service** : Configuration des comptes, groupes, GPO et partages Active Directory, ainsi que de l'authentification SSH par clés.
* **Vérifier les conditions de la continuité d'un service informatique** : Sauvegarde chiffrée des configurations Stormshield et sauvegarde automatique de la configuration DHCP avant modification.
* **Gérer des sauvegardes** : Archivage versionné des configurations d'infrastructure et des procédures dans le dépôt Git.

### Répondre aux incidents et aux demandes d'assistance et d'évolution

* **Collecter, suivre et orienter des demandes** : Utilisation de GLPI pour centraliser la gestion de parc et le suivi des demandes.
* **Traiter des demandes concernant les services réseau et système** : Procédures de configuration, de réinitialisation et de recette pour les commutateurs Cisco, le pare-feu Stormshield, le Wi-Fi UniFi et les services DHCP.
* **Maintenir et améliorer les services de l'infrastructure** : Automatisation des opérations Active Directory, DHCP et postes Debian afin de fiabiliser les changements et de réduire les interventions manuelles.

### Développer la présence en ligne de l'organisation

* **Participer à l'évolution d'un site Web exploitant les données de l'organisation** : Intégration des serveurs Apache et Glassfish pour rendre les certificats accessibles publiquement.

### Mettre à disposition des utilisateurs un service informatique

* **Déployer un service** : Déploiement et configuration des services Active Directory, DHCP, GLPI, NAS, Apache, GlassFish et Ansible.
* **Réaliser les tests d'intégration et d'acceptation d'un service** : Création de fiches de recette pour valider les accès, le routage, le NAT, le DHCP, le NAS, le Wi-Fi et Active Directory.
* **Accompagner les utilisateurs dans la mise en place d'un service** : Documentation des procédures d'installation, de configuration, d'utilisation des partages et d'administration des postes.

### Travailler en mode projet

* **Analyser les objectifs et les modalités d'organisation d'un projet** : Découpage du projet en situations professionnelles et en lots d'infrastructure documentés.
* **Planifier les activités** : Mise en œuvre d'une collaboration asynchrone structurée via la création de branches, la réalisation de Pull Requests (PR) et les revues de code entre pairs.
* **Évaluer les indicateurs de suivi d'un projet et analyser les écarts** : Vérification des résultats au moyen de fiches de recette et de tests de validation après chaque déploiement.

## 5. 🛠️ Comment utiliser la documentation ?

Ce site de documentation est généré automatiquement à partir de fichiers Markdown hébergés depuis le dépôt : [ecocert-docs](https://github.com/firetoak/ecocert-docs)

### 5.2 ✏️ Modifier la documentation

Pour contribuer ou mettre à jour la documentation, nous utilisons une approche GitOps collaborative. Afin d'éviter les conflits et d'assurer une relecture (review), suivez cette procédure :

1. Cloner le dépôt en local :

```bash
git clone https://github.com/firetoak/ecocert-docs.git
cd ecocert-docs

```

2. Créer une nouvelle branche de travail :

```bash
git switch -C feat/s0-m1-nom

```

3. Créer ou modifier les fichiers : éditez les fichiers `.md` situés dans l'arborescence correspondante (ex: `windows/active-directory/`).

4. Indexer les modifications :

```bash
git add .

```

5. Créer un commit descriptif :

```bash
git commit -m "docs: ajout de la procédure d'installation AD"

```

6. Pousser la branche sur GitHub :

```bash
git push origin feat/s0-m1-nom

```

7. Réalisation de la Pull Request (PR) : Sur GitHub, ouvrez une Pull Request. L'autre administrateur effectuera la *review* pour s'assurer que la procédure est claire, propre et compréhensible.

8. Merge : Une fois la validation effectuée, la branche est fusionnée sur `main`.

*Une fois le `push` ou le `merge` effectué sur `main`, la chaîne CI/CD via GitHub Actions compilera automatiquement les fichiers et déploiera la nouvelle version du site MkDocs.*

---

## 👥 6. Auteurs

Ce contexte est réalisé par deux étudiants en BTS SIO.

* **Louis MEDO** : [LinkedIn](https://www.linkedin.com/in/louismedo/) | [Portfolio](https://louis.loutik.fr) | [GitHub](https://github.com/FireToak) | [Mail](https://www.google.com/search?q=mailto%3Alouis.medo%40loutik.fr)
* **Amine Kada** : [GitHub](https://github.com/IT-Amine)