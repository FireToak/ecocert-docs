# Recettes - Step-CA

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 10/11/2026
> - **Domaine :** Debian

---

## 1. Contexte du test

Validation de l'installation, de la configuration et du bon fonctionnement opérationnel de l'autorité de certification (CA) locale `step-ca`. L'objectif de cette recette est de s'assurer que le service s'exécute correctement avec son compte de service dédié, qu'il est en écoute sur les ports requis, et que l'autorité racine est distribuable et intègre cryptographiquement.

## 2. Procédures de validation

### 2.1. Vérification de l'état du service systemd step-ca

**Objectif :** S'assurer que le service step-ca est actif, fonctionne sans erreur en arrière-plan et est activé au démarrage du système.

**Commande utilisée :**

```bash title="verification_service.sh"
sudo systemctl status step-ca --no-pager
```

* `sudo` : Exécute la commande avec les privilèges administrateur.
* `systemctl status step-ca` : Interroge le gestionnaire de services systemd pour obtenir l'état actuel de l'unité `step-ca`.
* `--no-pager` : Affiche la sortie directement dans le terminal complet sans nécessiter d'interaction ou de défilement manuel.

**Résultat attendu :**

```bash
● step-ca.service - step-ca service
     Loaded: loaded (/etc/systemd/system/step-ca.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-11-10 13:30:00 CET; 8min ago
   Main PID: 1234 (step-ca)
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Vérification de l'écoute réseau sur le port HTTPS

**Objectif :** Confirmer que l'autorité de certification écoute bien les requêtes entrantes sur le port 443 pour répondre aux demandes ACME et de distribution de certificats.

**Commande utilisée :**

```bash title="verification_port.sh"
sudo ss -tulpn | grep 443
```

* `sudo` : Nécessaire pour afficher les processus associés aux sockets réseau.
* `ss` : Utilitaire permettant d'afficher les statistiques des sockets réseau.
* `-tulpn` : Affiche les sockets TCP (`t`), UDP (`u`), à l'écoute (`l`), les processus associés (`p`), avec la résolution numérique des ports au lieu des noms de services (`n`).
* `grep 443` : Filtre la sortie de la commande précédente pour ne conserver que les lignes concernant le port 443.

**Résultat attendu :**

```bash
tcp   LISTEN 0      4096               *:443              *:*    users:(("step-ca",pid=1234,fd=3))
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Vérification de l'accès à la PKI et téléchargement du certificat

**Objectif :** S'assurer que le serveur web embarqué de la CA répond et distribue la clé publique de l'autorité racine.

**Commande utilisée :**

```bash title="telechargement_certificat.sh"
curl -k "https://pki.ecocert4.fr/roots.pem" -o /tmp/root_ca_ecocert.crt

```

* `curl` : Utilitaire en ligne de commande pour transférer des données via URL.
* `-k` : Ignore les erreurs de validation TLS (nécessaire car la machine de test ne fait pas encore confiance à la PKI).
* `"https://pki.ecocert4.fr/roots.pem"` : Point de terminaison web distribuant le certificat racine de step-ca.
* `-o /tmp/root_ca_ecocert.crt` : Spécifie le fichier de sortie local où sera sauvegardé le certificat.

**Résultat attendu :**

```bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   826  100   826    0     0   100k      0 --:--:-- --:--:-- --:--:--  100k
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. Validation de l'intégrité du certificat racine

> [!warning] "Validation de l'empreinte"
> Ne validez ce test que si l'empreinte calculée correspond strictement à l'empreinte originale générée lors de l'initialisation de `step-ca` (ex: 71A84C99304E592EF481D7A31E5223E3E988F79C05E8EE4EB12A802DB42AC43C).

**Objectif :** Garantir que le certificat téléchargé n'a pas été altéré et correspond bien à la PKI déployée, pour contrer le risque d'attaque par l'homme du milieu (MITM).

**Commande utilisée :**

```bash title="verification_empreinte.sh" hl_lines="1"
sha256sum /tmp/root_ca_ecocert.crt
```

* `sha256sum` : Calcule et affiche l'empreinte cryptographique SHA256 d'un fichier donné.
* `/tmp/root_ca_ecocert.crt` : Chemin pointant vers le certificat racine précédemment téléchargé pour vérification.

**Résultat attendu :**

```bash
71a84c99304e592ef481d7a31e5223e3e988f79c05e8ee4eb12a802db42ac43c  /tmp/root_ca_ecocert.crt
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
