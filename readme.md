# BTS SIO - ECOCERT - DOCUMENTATION

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

## Contexte

Ce dépôt centralise la documentation d'infrastructure du projet ECOCERT, un organisme de certification. Hébergé sous forme de site statique généré (via Zensical/MkDocs), il documente le déploiement, la configuration et l'exploitation des environnements Windows (Active Directory, SQL Server), Debian (Apache, Glassfish) et Réseau (Stormshield, Cisco). Il est géré via une approche GitOps collaborative garantissant l'intégrité et la révision par les pairs des procédures techniques.

-----

## Structure du dépôt

L’organisation du dépôt suit la logique suivante :

```text
ecocert-docs/
├── 01-ressources/
│   ├── plan-adressage.md
│   └── schemas.md
├── 02-reseau/
│   ├── index.md
│   └── configuration-stormshield.md
├── 03-windows/
│   └── active-directory/
└── 04-debian/
```

* **`01-ressources/`** : Regroupe les documents d'architecture globale (schémas topologiques, plans d'adressage IP et de routage, tables NAT).
* **`02-reseau/`** : Centralise les procédures de configuration des équipements d'interconnexion (commutateurs Cisco, pare-feu Stormshield, bornes Wifi). Le fichier `index.md` définit le point d'entrée pour la navigation.
* **`03-windows/`** : Contient les procédures liées à l'écosystème Microsoft (installation et gestion d'Active Directory, DHCP, SQL Server 2022).
* **`04-debian/`** : Stocke les documentations d'administration des serveurs Linux (déploiement des serveurs Web et d'applications).

---

## Utilisation de ecocert-docs

### 1. Cloner le dépôt localement

Récupération des fichiers source du projet sur votre poste de travail.

```bash
# git clone : Télécharge une copie locale complète du dépôt distant spécifié.
git clone https://github.com/firetoak/ecocert-docs.git

# cd (change directory) : Modifie le répertoire de travail courant pour entrer dans le dossier cloné.
cd ecocert-docs

```

### 2. Créer une branche de travail

Afin de ne pas impacter la branche principale (`main`), chaque nouvelle procédure doit être rédigée dans un espace isolé.

```bash
# git checkout -b : Commande combinée permettant de créer une nouvelle branche (ex: 'ajout-docs-ad') et de basculer immédiatement dessus.
git checkout -b ajout-docs-ad

```

### 3. Enregistrer et pousser les modifications

Une fois les fichiers Markdown modifiés ou créés, il faut sauvegarder l'état et l'envoyer sur le dépôt distant pour préparer la revue de code.

```bash
# git add . : Ajoute (indexe) toutes les modifications et nouveaux fichiers du répertoire courant pour le prochain commit.
git add .

# git commit -m : Valide les modifications indexées dans l'historique local avec un message descriptif (-m).
git commit -m "docs: ajout de la procédure d'installation du serveur AD"

# git push : Transfère les commits de votre branche locale vers le serveur distant (origin).
git push origin ajout-docs-ad

```

Une fois cette étape terminée, il est nécessaire d'ouvrir une *Pull Request* (PR) sur GitHub afin qu'un autre administrateur puisse relire et valider la documentation avant son intégration.

---

## Bonnes pratiques et sécurité

1. **Revue par les pairs (Peer Review)** : Ne jamais pousser de code directement sur la branche `main`. L'utilisation des Pull Requests garantit que la documentation est compréhensible, sans erreur, et validée par le binôme avant la compilation du site.
2. **Ordre d'affichage par préfixe** : L'utilisation de préfixes numériques (ex: `01-`, `02-`) pour les noms de dossiers est requise. Cela permet au générateur de site de trier correctement les catégories dans le menu latéral tout en conservant l'auto-découverte.

---

## 👨‍💻 Mainteneurs

* **Louis MEDO** | [LinkedIn](https://www.linkedin.com/in/louismedo/) | [Portfolio](https://louis.loutik.fr/) | [GitHub](https://github.com/FireToak) | [louis.medo@loutik.fr](mailto:louis.medo@loutik.fr)
* **Amine Kada** | [GitHub](https://github.com/IT-Amine)
