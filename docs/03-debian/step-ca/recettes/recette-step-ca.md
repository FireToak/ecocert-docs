# Fiche recette - PKI

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 16/11/2026
> - **Domaine :** Debian

---

## 1. Contexte du test

Validation de l'infrastructure d'autorité de certification `step-ca` sur serveur Debian. Ce test vise à vérifier le fonctionnement du service, le déploiement automatisé du certificat racine via stratégie de groupe (GPO) sur les clients Windows, et la reconnaissance de la chaîne de confiance cryptographique au niveau du navigateur web pour l'URL `https://pki.ecocert.fr`.

## 2. Procédures de validation

### 2.1. Vérification de l'état du service step-ca

**Objectif :** Vérifier que le démon de l'autorité de certification est actif et opérationnel sur le serveur Debian.

**Commande utilisée :**

```bash title="Vérification du service"
sudo systemctl status step-ca --no-pager
```

* `systemctl status step-ca` : Affiche l'état courant du service et les derniers messages disponibles.
* `--no-pager` : Affiche directement la sortie dans le terminal sans ouvrir de pager interactif.

**Résultat attendu :**

```bash
Active: active (running) since ...
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Vérification de la GPO sur le poste client

**Objectif :** Valider que la stratégie de groupe a injecté le certificat racine de confiance dans le magasin système Windows de la machine cible.

> [!warning] "Périmètre d'application"
> La GPO modifie la configuration système globale du poste ("Configuration ordinateur"). Un redémarrage des clients ou une actualisation GPO en arrière-plan est requis pour que l'approbation soit active.

**Commande utilisée :**

```powershell title="verify_gpo.ps1"
gpupdate /force
Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object { $_.Subject -match "Ecocert" }
```

* `gpupdate /force` : Binaire natif forçant le rafraîchissement immédiat de toutes les stratégies de groupe locales et Active Directory.
* `Get-ChildItem` : Cmdlet listant les objets d'un chemin, ciblant ici spécifiquement le magasin cryptographique système (`LocalMachine\Root`).
* `Where-Object` : Filtre les résultats renvoyés pour confirmer la présence du sujet de l'autorité (Ecocert).

**Résultat attendu :**

```powershell
Thumbprint                                Subject
----------                                -------
71A84C99304E592EF481D7A31E5223E3E988F79C  CN=Ecocert4 PKI
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Validation de la confiance HTTPS sur le navigateur

**Objectif :** S'assurer que le certificat de la PKI est reconnu par le navigateur internet, permettant de joindre le site sans avertissement de sécurité.

**Résultat attendu :**

Le navigateur s'ouvre sur la page web. Le cadenas à côté de l'URL est fermé, et aucun écran d'alerte ou avertissement TLS lié à l'autorité de certification n'apparaît.

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
