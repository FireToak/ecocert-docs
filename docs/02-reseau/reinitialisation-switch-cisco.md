# Réinitialisation switch Cisco

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

## Informations

- **Auteur :** Louis MEDO
- **Date :** 21/09/2026
- **Domaine :** Réseau

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Réinitialisation de l'équipement](#3-reinitialisation-de-lequipement)
- [4. Déploiement de la configuration](#4-deploiement-de-la-configuration)

## 2. Contexte

Cette procédure décrit la réinitialisation matérielle et la restauration de la configuration sur un commutateur Cisco.

## 3. Réinitialisation de l'équipement {#3-reinitialisation-de-lequipement}

3.1. **Effacement de la configuration.** Suppression de la configuration de démarrage actuelle pour remettre le commutateur à son état d'usine.

```ios
write erase
```

- `write erase` : Efface le fichier `startup-config` stocké dans la mémoire NVRAM du switch.

3.2. **Suppression de la base VLAN.** Élimination du fichier contenant la base de données VTP et les VLANs.

```ios
delete flash:vlan.dat
```

- `delete` : Demande la suppression d'un fichier spécifié sur le système de fichiers.
- `flash:vlan.dat` : Spécifie le chemin et le nom du fichier de base de données VLAN situé dans la mémoire flash.

3.3.  **Redémarrage du switch.** Redémarrage de l'équipement pour appliquer la remise à zéro.

```ios
reload
```

- `reload` : Déclenche le redémarrage à chaud du système Cisco IOS. (Il faut refuser la sauvegarde de la configuration courante si elle est demandée).

## 4. Déploiement de la configuration {#4-deploiement-de-la-configuration}

Les fichiers de configurations doit être récupéré depuis les sources Git ci-dessous :

- [ec-sw-c1](https://ecocert.bts.loutik.fr/01-ressources/assets/configurations/ec-sw-c1.txt).
- [ec-sw-a1](https://ecocert.bts.loutik.fr/01-ressources/assets/configurations/ec-sw-a1.txt).

4.1. **Accès au mode de configuration.** Élévation des privilèges et passage en mode de configuration globale.

```ios
enable
configure terminal
```

- `enable` : Passe du mode utilisateur au mode d'exécution privilégié (mode administrateur).
- `configure terminal` : Ouvre le mode de configuration globale permettant d'appliquer de nouveaux paramètres depuis le terminal.

4.2.  **Injection du fichier de configuration.** Coller le contenu du fichier directement dans le terminal.

> [!warning] Saturation du buffer
> Injectez la configuration par blocs de 30 à 50 lignes maximum pour éviter les erreurs de syntaxe dues à la saturation du buffer série.

4.3. **Sauvegarde de la nouvelle configuration.** Enregistrement de la configuration courante pour la rendre persistante.

```ios
copy running-config startup-config
```

- `copy` : Commande de copie de fichiers ou de configurations.
- `running-config` : Fichier source (la configuration actuellement active en RAM).
- `startup-config` : Fichier de destination (la configuration chargée au démarrage en NVRAM).

> [!info]
> Vous pouvez également utiliser `write`.
