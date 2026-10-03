# BTS SIO — ECOCERT — DOCUMENTATION

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

## Contexte

Ce dépôt centralise la documentation d'infrastructure du projet **ECOCERT**, un organisme de certification de pratiques durables et de l'agriculture biologique. Hébergé sous forme de site statique généré via **Zensical**, il documente le déploiement, la configuration et l'exploitation des environnements Windows Server (Active Directory, LDAPS), Debian 13 (GLPI 11, Kea DHCP, TrueNAS) et Réseau (Stormshield, Cisco, UniFi). Il est géré via une approche GitOps collaborative garantissant l'intégrité et la révision par les pairs des procédures techniques.

---

## Structure du dépôt

```text
ecocert-docs/
├── docs/
│   ├── 01-ressources/    ← Schémas, plans d'adressage, NAT, routage, PKI
│   ├── 02-reseau/        ← Stormshield, Cisco, UniFi
│   ├── 03-debian/        ← GLPI 11, Kea DHCP, TrueNAS, AppArmor
│   └── 04-windows/       ← Active Directory, LDAPS
├── zensical.toml         ← Configuration du site
└── README.md
```

### Convention de nommage des fichiers

Tous les fichiers Markdown respectent la convention `[type]-[service]-[technologie].md` :

| Préfixe | Type de document |
| :--- | :--- |
| `installation-` | Procédure d'installation pas à pas |
| `configuration-` | Procédure de configuration d'un service |
| `recette-` | Fiche recette (tests de validation) |
| `explication-` | Explication / synthèse théorique |

Les dossiers `assets/` portent le même nom que le fichier de procédure auquel ils sont rattachés.

---

## Utilisation de ecocert-docs

### 1. Cloner le dépôt localement

```bash
git clone https://github.com/firetoak/ecocert-docs.git
cd ecocert-docs
```

### 2. Créer une branche de travail

Toujours travailler dans une branche dédiée pour ne pas impacter `main` :

```bash
git checkout -b feat/ajout-docs-glpi
```

### 3. Enregistrer et pousser les modifications

```bash
git add .
git commit -m "docs: ajout de la procédure d'installation GLPI"
git push origin feat/ajout-docs-glpi
```

Une fois cette étape terminée, ouvrez une **Pull Request** sur GitHub pour qu'un autre administrateur relie et valide la documentation avant son intégration sur `main`.

> [!NOTE]
> Une fois le `merge` effectué sur `main`, la chaîne CI/CD via **GitHub Actions** compilera automatiquement les fichiers et déploiera la nouvelle version du site.

---

## 👨‍💻 Mainteneurs

* **Louis MEDO** | [LinkedIn](https://www.linkedin.com/in/louismedo/) | [Portfolio](https://louis.loutik.fr/) | [GitHub](https://github.com/FireToak) | [louis.medo@loutik.fr](mailto:louis.medo@loutik.fr)
* **Amine KADA** | [GitHub](https://github.com/IT-Amine) | [Portfolio](https://amine-it.vercel.app/)
