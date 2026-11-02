# Fiche recette - Validation DNS Bind9

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 02/11/2026
> - **Domaine :** debian

---

## 1. Contexte du test

Cette fiche recette consigne les opérations de diagnostic méthodiques pour valider la configuration du service DNS Bind9 sur le réseau ECOCERT. Les tests sont exécutés sur le serveur autoritaire 172.16.54.50. L'objectif est de garantir la validité syntaxique des fichiers, la bonne exécution du démon nommé `named`, la résolution correcte des enregistrements A, l'absence de récursivité externe (sécurité), et l'effectivité des transferts de zone (AXFR).

## 2. Procédures de validation

### 2.1. Vérification de la syntaxe globale

**Objectif :** Vérifier les fichiers de configuration globale fournis par le paquet pour détecter les éventuelles erreurs de syntaxe avant tout redémarrage du service.

**Commande utilisée :**

```bash
sudo named-checkconf
```

* `sudo` : Exécute la commande avec les privilèges d'administrateur (root), requis pour lire les fichiers dans `/etc/bind/`.
* `named-checkconf` : Utilitaire natif de Bind9 permettant d'analyser et de valider la syntaxe des fichiers de configuration globale (ex: `named.conf`, `named.conf.options`).

**Résultat attendu :**

```bash
# Ne retourne rien (silence terminal si aucune erreur)
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Vérification de la syntaxe du fichier de zone

**Objectif :** S'assurer de la validité de la syntaxe des fichiers de zone (parenthèses du SOA, points finaux des FQDN) pour prévenir un crash ou le rejet de la zone au démarrage.

**Commande utilisée :**

```bash
sudo named-checkconf -z
```

* `named-checkconf` : Utilitaire de vérification de la configuration Bind9.
* `-z` : Argument forçant l'outil à charger et à vérifier la syntaxe de toutes les zones déclarées dans les fichiers de configuration globale.

**Résultat attendu :**

```bash
zone ns01.ecocert4.fr/IN: loaded serial 2026110201
OK
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

> [!warning] "Démarrage du serveur et traces"
> Sauf erreur de syntaxe bloquante, le démon `named` tentera de démarrer. Pour certifier l'absence d'erreurs logiques ou de droits, la lecture des journaux système (logs) est une étape obligatoire.

### 2.3. Contrôle du démarrage du service dans les journaux

**Objectif :** Contrôler dynamiquement le démarrage ou redémarrage du service Bind9 pour s'assurer que la zone `ns01.ecocert4.fr` est chargée sans erreur.

**Commande utilisée :**

```bash
tail -f /var/log/bind.log
```

* `tail` : Commande permettant d'afficher la fin d'un fichier texte.
* `-f` : Argument (follow) pour lire en flux continu le fichier et surveiller les événements du démon `named` en temps réel.
* `/var/log/bind.log` : Chemin absolu vers le fichier de trace (peut aussi être vérifié via `journalctl -u bind9 -f` selon la configuration syslog).

**Résultat attendu :**

```text
# Exécution sans erreurs. Si un problème survient, le log indiquera "failed: file not found" ou "unexpected end of input".
zone ns01.ecocert4.fr/IN: loaded serial 2026110201
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. Vérification des données relatives à la zone

**Objectif :** Interroger directement le serveur DNS ciblé pour valider qu'il résout correctement son propre FQDN via l'enregistrement A correspondant.

**Commande utilisée :**

```bash
dig @172.16.54.50 ns01.ecocert4.fr A
```

* `dig` : Outil standard (Domain Information Groper) d'interrogation des serveurs DNS.
* `@172.16.54.50` : Spécifie explicitement l'adresse IP du serveur DNS à interroger (contourne le résolveur de l'OS).
* `ns01.ecocert4.fr` : Le nom de domaine pleinement qualifié (FQDN) à résoudre.
* `A` : Précise que l'on recherche spécifiquement un Resource Record (RR) de type IPv4.

**Résultat attendu :**

```text
;; QUESTION SECTION:
;ns01.ecocert4.fr.          IN      A

;; ANSWER SECTION:
ns01.ecocert4.fr.   86400   IN      A       172.16.54.50

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.5. Vérification de la non-récursivité

**Objectif :** Valider que le serveur DNS autoritaire refuse de résoudre des domaines externes pour des clients non autorisés (mitigation des attaques par amplification DNS).

**Commande utilisée :**

```bash
dig @172.16.54.50 loutik.fr

```

* `dig` : Outil d'interrogation DNS.
* `@172.16.54.50` : Cible le serveur DNS local ECOCERT.
* `loutik.fr` : Nom de domaine externe utilisé comme appât pour forcer une requête récursive.

**Résultat attendu :**

```text
;; ->>HEADER<< opcode: QUERY, status: REFUSED, id: 12345
; EDE: 20 (Not Authoritative): (recursion disabled)

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
