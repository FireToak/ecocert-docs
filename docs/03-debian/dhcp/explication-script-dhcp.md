---
description: Automatisation de la génération des pools DHCP pour Kea via un script Bash interactif.
---

# Automatisation de la configuration Kea DHCP

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** Amine KADA
    - **Date :** 28/09/2026
    - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Création du fichier d'adressage (Source)](#3-creation-du-fichier-dadressage-source)
- [4. Déploiement du script d'automatisation](#4-deploiement-du-script-dautomatisation)
- [5. Exécution et intégration de la configuration](#5-execution-et-integration-de-la-configuration)

## 2. Contexte

Dans le cadre de la réorganisation du réseau d'ECOCERT et de la remédiation (SP2), cette procédure vise à automatiser la configuration du serveur Kea-dhcp4. Un script d'automatisation Bash analyse le plan d'adressage (format texte) et génère interactivement la configuration associée au format JSON stricte requis par Kea. Cette approche Infrastructure as Code (IaC) minimise les erreurs de syntaxe manuelles et accélère le déploiement de nouveaux VLANs.

📄 **Document de référence :** [Contexte ECOCERT SP2](./assets/context-script/Situation%20-%20REMEDIATION%20SP2%20-%20Automatisation%20de%20la%20configuration%20du%20DHCP.pdf)

## 3. Création du fichier d'adressage (Source)

3.1. **Définition des sous-réseaux ECOCERT.** Création du fichier de base de données contenant le plan d'adressage (VLSM) qui sera traité par le script d'automatisation.

📄 **Fichier .txt du plan d'adressage réseau :** [Fichier txt réseau](./assets/context-script/SP2planadressage.txt)

- `sr` : Adresse réseau du sous-réseau (Subnet).
- `masque` : Masque de sous-réseau en notation décimale pointée.
- `diff` : Adresse de diffusion (Broadcast) du sous-réseau.

## 4. Déploiement du script d'automatisation

4.1. **Création du script Bash.** Écriture du programme chargé de convertir les masques en CIDR, d'interroger l'administrateur pour les plages d'adresses et de formater la sortie en JSON.

📄 **Script Automatisation config DHCP, service Kea :** [Config script DHCP](./assets/context-script/config.sh)

- `FICHIER_SOURCE` : Variable définissant le fichier texte d'adressage à analyser.
- `FICHIER_RESULTAT` : Variable définissant le fichier JSON de sortie à générer.
- `< /dev/tty` : Paramètre forçant la commande `read` à écouter l'entrée standard du clavier (terminal) plutôt que la boucle de lecture du fichier texte.

## 5. Exécution et intégration de la configuration

5.1. **Attribution des permissions.** Configuration des droits sur le fichier du script pour autoriser son exécution par le système.

```bash
chmod +x config.sh
```

- `+x` : Attribut de permission ajoutant le droit d'exécution (eXecute) au fichier cible.

5.2. **Exécution du processus.** Lancement de l'outil avec élévation de privilèges pour garantir l'autorisation d'écriture dans l'arborescence `/etc/kea/`.

```bash
sudo ./config.sh
```
5.3. **Exécution en mode débogage (détaillé).** Exécution pas-à-pas affichant chaque instruction interprétée et le contenu des variables en temps réel pour analyser le déroulement du script et diagnostiquer d'éventuelles erreurs.

```bash
sudo bash -x ./config.sh
```

- `sudo` : Exécute la commande avec les privilèges administrateur (root), nécessaire pour l'écriture dans `/etc/kea/`.
- `bash` : Appelle explicitement l'interpréteur de commandes Bash.
- `-x` : Active le mode de traçage (*xtrace* / débogage) affichant chaque instruction exécutée précédée d'un symbole `+` avec les variables substituées par leur valeur réelle.
- `./` : Indique au système d'exécuter le script situé dans le répertoire de travail courant.


5.4. **Intégration à Kea DHCP.** Intégration de la configuration générée dans le fichier principal du service.

```bash
cat /etc/kea/blocs_sous_reseaux.json >> /etc/kea/kea-dhcp4.conf
```

- `cat` : Affiche le contenu intégral du fichier de résultats JSON.
- `>>` : Opérateur de redirection qui concatène la sortie standard à la fin du fichier cible, sans écraser la configuration existante de Kea.