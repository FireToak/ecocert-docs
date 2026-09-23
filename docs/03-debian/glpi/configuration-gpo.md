---
description: Procédures additionnelles pour la configuration de la base de données EcoCert et le déploiement GPO de l'agent GLPI.
---

# Actions Complémentaires GLPI

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)


- **Auteur :** KADA Amine
- **Date :** 23/09/2026
- **Domaine :** Debian / GLPI

---

## 2. Contexte

Ce document annexe regroupe les actions complémentaires exigées pour le déploiement massif et la structuration avancée du serveur GLPI au sein de l'infrastructure d'EcoCert. Il détaille la configuration spécifique de la base de données, la création de la politique de groupe (GPO) pour le déploiement silencieux de l'agent, et la validation du mécanisme de remontée automatique de l'inventaire.

## 3. Déploiement de l'agent GLPI via GPO

Le déploiement automatisé permet à chaque poste Windows intégré au domaine de s'installer de façon autonome l'agent GLPI et de remonter ses caractéristiques matérielles et logicielles sans intervention manuelle des techniciens.

3.1.  **Ouverture de la console de Gestion de stratégie de groupe**.
L'opération s'effectue depuis le contrôleur de domaine (`ADECOCERT`) ou un poste d'administration disposant des outils RSAT.

1. Appuyez sur les touches `Win + R` pour ouvrir la fenêtre **Exécuter**.
2. Tapez la commande suivante et validez par Entrée :

```cmd title="Fenêtre Exécuter"
gpmc.msc
```

3.2.  **Création et liaison de la GPO**.

1. Dans la console, déroulez l'arborescence : `Forêt > Domaines > local.ecocert4.fr`.
2. Faites un clic droit sur l'Unité d'Organisation (OU) qui contient les ordinateurs de votre parc (et non l'OU des utilisateurs).
3. Sélectionnez **Créer un objet GPO dans ce domaine, et le lier ici...**.
4. Nommez-le explicitement, par exemple : `Deploiement_Agent_GLPI`.

3.3.  **Déploiement du package d'installation (MSI)**.

1. Faites un clic droit sur votre nouvelle GPO et choisissez **Modifier**.
2. Naviguez vers : `Configuration ordinateur > Stratégies > Paramètres logiciels > Installation de logiciel`.
3. Faites un clic droit dans la zone vide, puis **Nouveau > Package...**.
4. **ATTENTION :** Ne sélectionnez pas le fichier `.msi` depuis un chemin local (ex: `C:\Dossier\GLPI-Agent.msi`), car les postes clients chercheraient ce fichier sur leur propre disque C:. Vous devez impérativement entrer un **chemin réseau (UNC)** pointant vers un dossier partagé accessible à tous en lecture.
   - *Exemple de chemin valide :* `\\NASECOCERT\Partages\GLPI-Agent.msi` ou `\\ADECOCERT\SYSVOL\local.ecocert4.fr\scripts\GLPI-Agent.msi`.
5. Sélectionnez le mode de déploiement **Attribué** (Assigned) et validez.

3.4.  **Paramétrage du Registre (Cible du serveur GLPI)**.
Afin que l'agent installé sache où envoyer ses données, il faut lui injecter l'URL du serveur via une clé de registre.

1. Toujours dans l'éditeur de la GPO, naviguez vers : `Configuration ordinateur > Préférences > Paramètres Windows > Registre`.
2. Faites un clic droit > **Nouveau > Élément Registre** et remplissez les propriétés exactes suivantes :
   - **Action :** Créer (ou Mettre à jour)
   - **Ruche :** `HKEY_LOCAL_MACHINE`
   - **Chemin de la clé :** `SOFTWARE\GLPI-Agent`
   - **Nom de la valeur :** `server`
   - **Type de valeur :** `REG_SZ` (Valeur Chaîne)
   - **Données de la valeur :** `https://172.16.54.40` (L'URL racine de votre GLPI, sécurisée en HTTPS).
3. Cliquez sur **Appliquer** puis **OK**. Fermez l'éditeur de stratégie.

## 4. Configuration de la récupération automatique (Inventory)

4.1.  **Configuration côté Serveur GLPI**.

1. Dans l'interface web sécurisée de GLPI, naviguez dans **Administration > Inventaire**.
2. Vérifiez que la collecte des inventaires partiels et complets est bien autorisée pour que le serveur accepte les requêtes entrantes des agents.

4.2.  **Validation côté Client Windows**.

1. Sur un poste client cible, forcez l'application de la politique réseau pour déclencher l'installation de l'agent :

```cmd title="Terminal (Client Windows)"
gpupdate /force
```

2. Ouvrez le gestionnaire de services local (`services.msc`) et vérifiez que le service **GLPI Agent** est présent et en cours d'exécution.
3. Vérifiez la remontée effective du poste dans l'interface d'administration GLPI sous le menu **Parc > Ordinateurs**. Les informations (CPU, RAM, Disques, Logiciels) doivent y être exhaustives.
