---
description: Procédure de test et de validation de l'exécution du script d'automatisation DHCP.
---

# Fiche Recette : Exécution du script d'automatisation DHCP

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** Amine KADA
    - **Date :** 29/09/2026
    - **Domaine :** Debian / Automatisation

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Validation de l'exécution interactive](#3-validation-de-lexecution-interactive)
- [4. Validation de la génération du fichier de configuration](#4-validation-de-la-generation-du-fichier-de-configuration)

---

## 2. Contexte

Cette fiche de recette a pour but de valider le bon fonctionnement du script Bash d'automatisation (`config_dhcp.sh`). Les tests permettent de confirmer que le script interagit correctement avec l'administrateur système pour récolter les informations (DNS, nom de domaine, plages d'IP, passerelles) et qu'il génère dynamiquement des blocs de configuration valides au format JSON pour le serveur Kea DHCP.

---

## 3. Validation de l'exécution interactive

3.1. **Lancement du script et saisie des paramètres.**
L'exécution du script doit d'abord réaliser une sauvegarde automatique de la configuration initiale de Kea, puis demander les paramètres globaux (Serveurs DNS et Nom de domaine) avant de boucler sur les sous-réseaux pour demander les plages et passerelles.

- Le script est exécuté depuis le terminal Debian.
- Les invites de commandes (prompts) s'affichent correctement.
- L'administrateur peut saisir les valeurs sans erreur d'interruption.

![Exécution du script Bash](assets/fiche-recette-script-dhcp/execution-script.png)

*Validation : L'interactivité du script et le parcours du fichier d'adressage fonctionnent comme attendu.*

---

## 4. Validation de la génération du fichier de configuration

4.1. **Vérification du fichier de sortie JSON.**
Une fois le script terminé, le fichier de résultat `/etc/kea/blocs_sous_reseaux.json` doit contenir les blocs de sous-réseaux correctement formatés, incluant toutes les variables saisies précédemment.

- Les masques de sous-réseaux (ex: 255.255.255.0) ont bien été convertis en notation CIDR (ex: /24).
- Les options `domain-name-servers` et `domain-name` sont présentes dans le bloc `option-data`.
- Le pool d'adresses correspond bien aux adresses de début et de fin renseignées.

![Résultat de la génération JSON](assets/fiche-recette-script-dhcp/resultat-json.png)

*Validation : Le code JSON généré est syntaxiquement correct et prêt à être intégré dans le fichier de configuration principal `kea-dhcp4.conf`.*
