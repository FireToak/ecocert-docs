# BTS SIO — ECOCERT — DOCUMENTATION

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

## Contexte

Ce dépôt centralise la documentation d'infrastructure du projet **ECOCERT**, un organisme de certification de pratiques durables et de l'agriculture biologique. Hébergé sous forme de site statique généré via **Zensical**, il documente le déploiement, la configuration et l'exploitation des environnements Windows Server (Active Directory, LDAPS), Debian 13 (GLPI 11, Kea DHCP, TrueNAS) et Réseau (Stormshield, Cisco, UniFi). Il est géré via une approche GitOps collaborative garantissant l'intégrité et la révision par les pairs des procédures techniques.

---

## Structure du dépôt

```text
ecocert-docs/
├── docs/
│   ├── index.md                          ← Page d'accueil du site
│   ├── 01-ressources/                    ← Architecture globale
│   │   ├── index.md
│   │   ├── annuaire-machine.md
│   │   ├── plan-adressage.md
│   │   ├── table-routage.md
│   │   ├── table-nat.md
│   │   ├── schemas.md
│   │   ├── contexte.md
│   │   ├── conf-ressources-equipements.md
│   │   └── pki.md
│   ├── 02-reseau/                        ← Équipements réseau
│   │   ├── index.md
│   │   ├── expl-cisco-reinitialisation.md
│   │   ├── pare-feu/
│   │   │   ├── conf-stormshield-interface.md
│   │   │   ├── conf-stormshield-nat.md
│   │   │   ├── conf-stormshield-routage.md
│   │   │   ├── expl-stormshield-sauvegarde.md
│   │   │   └── rect-stormshield-parefeu.md
│   │   ├── commutateur/
│   │   │   └── rect-cisco-commutateur.md
│   │   └── wifi/
│   │       ├── inst-unifi-controleur.md
│   │       ├── conf-unifi-postinstall.md
│   │       ├── conf-unifi-equipement.md
│   │       ├── conf-unifi-wifi.md
│   │       ├── rect-unifi-controleur.md
│   │       └── rect-unifi-wifi.md
│   ├── 03-debian/                        ← Serveurs Linux Debian 13
│   │   ├── index.md
│   │   ├── commun/
│   │   │   ├── conf-commun-hostname.md
│   │   │   └── expl-commun-apparmor.md
│   │   ├── glpi/
│   │   │   ├── inst-glpi-debian.md
│   │   │   ├── conf-glpi-debian.md
│   │   │   ├── conf-glpi-ldaps.md
│   │   │   └── conf-glpi-gpo.md
│   │   ├── dhcp/
│   │   │   ├── inst-dhcp-kea.md
│   │   │   ├── conf-dhcp-kea.md
│   │   │   ├── conf-dhcp-avancer.md
│   │   │   ├── expl-dhcp-script.md
│   │   │   ├── rect-dhcp-kea.md
│   │   │   └── rect-dhcp-script.md
│   │   └── nas/
│   │       ├── inst-nas-truenas.md
│   │       ├── conf-nas-truenas.md
│   │       ├── conf-nas-zfs.md
│   │       └── rect-nas-truenas.md
│   └── 04-windows/                       ← Serveurs Windows Server
│       ├── index.md
│       ├── ad/
│       │   ├── inst-ad-windows.md
│       │   ├── conf-ad-windows.md
│       │   ├── conf-ad-ldaps.md
│       │   └── rect-ad-windows.md
│       └── commun/
│           └── conf-commun-network.md
├── zensical.toml                         ← Configuration du site (navigation, thème)
├── requirements.txt
└── README.md
```

### Convention de nommage des fichiers

Tous les fichiers Markdown respectent la convention `[type]-[service]-[technologie].md` :

| Préfixe | Type de document |
| :--- | :--- |
| `inst-` | Procédure d'**installation** pas à pas |
| `conf-` | Procédure de **configuration** d'un service |
| `rect-` | **Fiche recette** (validation / tests) |
| `expl-` | **Explication** / synthèse théorique |

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
# Indexer les fichiers modifiés
git add .

# Créer un commit descriptif
git commit -m "docs: ajout de la procédure d'installation GLPI"

# Pousser la branche sur GitHub
git push origin feat/ajout-docs-glpi
```

Une fois cette étape terminée, ouvrez une **Pull Request** sur GitHub pour qu'un autre administrateur relie et valide la documentation avant son intégration sur `main`.

> [!NOTE]
> Une fois le `merge` effectué sur `main`, la chaîne CI/CD via **GitHub Actions** compilera automatiquement les fichiers et déploiera la nouvelle version du site.

---

## Bonnes pratiques

1. **Revue par les pairs (Peer Review)** : Ne jamais pousser directement sur `main`. Les Pull Requests garantissent que la documentation est claire, sans erreur, et validée avant la mise en ligne.
2. **Convention de nommage stricte** : Tout fichier créé doit respecter la convention `[type]-[service]-[techno].md` décrite ci-dessus.
3. **Template de procédure** : Chaque fichier doit commencer par le frontmatter YAML, la bannière ECOCERT, l'encart `!!! note "Méta-informations"` et un sommaire.

---

## 👨‍💻 Mainteneurs

* **Louis MEDO** | [LinkedIn](https://www.linkedin.com/in/louismedo/) | [Portfolio](https://louis.loutik.fr/) | [GitHub](https://github.com/FireToak) | [louis.medo@loutik.fr](mailto:louis.medo@loutik.fr)
* **Amine KADA** | [GitHub](https://github.com/IT-Amine) | [Portfolio](https://amine-it.vercel.app/)
