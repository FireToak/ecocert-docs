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
* **DHCP** : Configuration de l'attribution dynamique des adresses IP pour l'ensemble des équipements du réseau.
* **SQL Server 2022** : Déploiement du système de gestion de bases de données relationnelles (SGBD) hébergeant les données de certification.

### Exploitation des services

* **Proxmox** : Gestion de la ferme de serveurs pour la virtualisation et la haute disponibilité de l'infrastructure.
* **Apache 2.4.56 & Glassfish 6** : Déploiement des serveurs Web et d'applications pour héberger les services en ligne destinés au public et aux producteurs.

### Administration et supervision des réseaux

* **Cisco (Niveau 2 et 3)** : Configuration des commutateurs pour assurer le routage, la segmentation VLAN et la connectivité globale.
* **Borne Wifi** : Mise en place de l'infrastructure réseau sans fil.

### Cybersécurité

* **Stormshield SN 210** : Intégration du pare-feu matériel pour filtrer les flux réseaux, sécuriser les accès externes et protéger l'infrastructure interne.

## 4. 🧠 Compétences du référentiel de BTS SIO

<!-- 
NE PAS SUPPRIMER CE COMMENTAIRE !!!

Message pour l'ia : Tu mets à jour avec les informations données en entrée dans le prompt et en utilisant la structure suivante

### [Nom de la compétence principale]

* **[Sous-compétence mobilisée]** : justification
-->

### Gérer le patrimoine informatique

* **Recenser et identifier les ressources numériques** : Élaboration de la section "Ressources" regroupant les schémas, le plan d'adressage IP, le plan de routage et la table de NAT.
* **Mettre en place et vérifier les niveaux d'habilitation** : Installation et configuration des politiques de sécurité et des accès via l'Active Directory.

### Répondre aux incidents et aux demandes d'assistance et d'évolution

* **Maintenir et améliorer les services de l'infrastructure** : Implémentation d'un flux de travail GitOps pour sécuriser la mise à jour des procédures techniques sans risque de conflit.

### Développer la présence en ligne de l'organisation

* **Participer à l'évolution d'un site Web exploitant les données de l'organisation** : Intégration des serveurs Apache et Glassfish pour rendre les certificats accessibles publiquement.

### Travailler en mode projet

* **Planifier les activités** : Mise en œuvre d'une collaboration asynchrone structurée via la création de branches, la réalisation de Pull Requests (PR) et les revues de code entre pairs.

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