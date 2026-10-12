---
description: Procédure d'extension de volume Windows en supprimant la partition de récupération bloquante via diskpart.
---

# Redimensionner le disque d'un serveur Windows avec diskpart

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 09/10/2026
> - **Domaine :** Windows

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Identification des partitions](#3-identification-des-partitions)
- [4. Suppression de la partition de récupération](#4-suppression-de-la-partition-de-recuperation)
- [5. Extension du volume principal](#5-extension-du-volume-principal)

## 2. Contexte

Le volume principal (C:) du serveur Windows nécessite une extension de stockage. Cependant, une partition de récupération s'intercale entre la partition principale et l'espace non alloué, bloquant l'extension. Cette procédure documente la suppression forcée de la partition de récupération avec l'outil en ligne de commande, puis l'extension du volume.

> [!warning] "Attention aux identifiants matériels"
> Les numéros de disques (ex: `disk 0`) et de partitions (ex: `partition 3`) utilisés dans cette procédure sont donnés à titre d'exemple. Vous devez **impérativement adapter** ces numéros à votre propre infrastructure en analysant rigoureusement les retours des commandes `list disk` et `list partition`.

> [!caution] "Comportement de la partition de récupération"
> La partition de récupération **ne se recrée pas toute seule** après sa suppression. Sans action de votre part, l'environnement de récupération (WinRE) reste désactivé. Il est nécessaire de la recréer manuellement à l'issue de l'extension du volume pour conserver les options de dépannage du système.

## 3. Identification des partitions

3.1. **Lancement de l'utilitaire et sélection du disque.** Ouvrir une invite de commande avec privilèges élevés (Administrateur) pour interagir avec le gestionnaire de disques en ligne de commande.

```bat title="Lancement et identification"
diskpart
list disk
select disk 0
list partition
```

- `diskpart` : Lance l'interpréteur de commandes de gestion des disques.
- `list disk` : Affiche tous les disques physiques disponibles sur le serveur.
- `select disk 0` : Donne le focus au disque contenant le système d'exploitation.
- `list partition` : Affiche les partitions du disque sélectionné pour repérer la partition de récupération.

## 4. Suppression de la partition de récupération {#4-suppression-de-la-partition-de-recuperation}

4.1. **Sélection et forçage de la suppression.** Sélectionner la partition de récupération identifiée à l'étape précédente et forcer sa suppression pour libérer la contiguïté de l'espace.

```bat title="Suppression de la partition bloquante"
select partition 3
delete partition override
```

- `select partition 3` : Donne le focus à la partition de récupération (le numéro exact dépend de l'affichage de la commande précédente).
- `delete partition override` : Supprime la partition. L'attribut `override` est indispensable pour contourner la protection système empêchant la suppression standard.

## 5. Extension du volume principal

5.1. **Agrandissement du système de fichiers.** Cibler la partition contenant le système (C:) et l'étendre vers l'espace non alloué désormais adjacent.

```bat title="Extension du volume"
select partition 2
extend
exit
```

- `select partition 2` : Donne le focus à la partition principale (C:) à étendre.
- `extend` : Agrandit le volume sélectionné pour occuper tout l'espace non alloué contigu disponible.
- `exit` : Ferme proprement l'utilitaire `diskpart`.
