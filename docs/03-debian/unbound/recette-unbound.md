# Fiche recette - Unbound

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 02/11/2026
> - **Domaine :** debian

---

## 1. Contexte du test

Cette fiche de recette vise à valider le déploiement et le bon fonctionnement du service DNS récursif Unbound au sein de l'infrastructure. Les tests permettront de certifier que le service est actif, que la configuration locale du serveur est conforme, que les clients réseau parviennent à résoudre des noms de domaine via le serveur primaire et le serveur secondaire, et que la résilience (basculement en cas de panne) est opérationnelle pour les clients basés sur Debian.

## 2. Procédures de validation

> [!TIP] Vider le cache DNS
> Cette commande est utile pour pour vider le cache DNS sur le service Unbound.
>
> ```bash
> sudo unbound-control flush_zone votre.domaine
> ```

### 2.1. Vérification de l'état du service Unbound

**Objectif :** S'assurer que le daemon Unbound a démarré correctement et tourne sans erreur sur le serveur DNS.

**Commande utilisée :**

```bash
sudo systemctl status unbound
```

* `sudo` : Exécute la commande avec les privilèges d'administrateur.
* `systemctl` : Utilitaire de gestion des services Systemd.
* `status` : Argument permettant d'afficher l'état actuel du service ainsi que les dernières lignes de journaux.
* `unbound` : Le nom du service à interroger.

**Résultat attendu :**

```bash
● unbound.service - Unbound DNS server
     Loaded: loaded (/lib/systemd/system/unbound.service; enabled; preset: enabled)
     Active: active (running) since Wed 2026-09-23 16:00:00 CEST;
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Validation de la configuration locale (resolv.conf)

**Objectif :** Vérifier que le serveur DNS est configuré pour s'interroger lui-même (via la boucle locale) puis interroger le serveur secondaire en cas de besoin.

**Commande utilisée :**

```bash
cat /etc/resolv.conf
```

* `cat` : Commande permettant de lire et de concaténer le contenu d'un fichier sur la sortie standard.
* `/etc/resolv.conf` : Fichier de configuration spécifiant les serveurs de noms (nameservers) utilisés par le système.

**Résultat attendu :**

```bash
nameserver 127.0.0.1
nameserver 8.8.8.8
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Test de résolution DNS

**Objectif :** Confirmer depuis un poste client que le serveur DNS récursif traite et répond correctement aux requêtes.

**Commande utilisée :**

```bash
dig @172.16.54.51 debian.org
```

* `dig` : Outil standard d'interrogation des serveurs DNS (Domain Information Groper).
* `@172.16.54.51` : Argument forçant l'outil à interroger spécifiquement l'adresse IP du serveur primaire.
* `debian.org` : Nom de domaine cible à résoudre pour le test.

**Résultat attendu :**

```bash
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 54321
;; Query time: 15 msec
;; SERVER: 172.16.54.51#53(172.16.54.51)
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. Test de résolution d'un domaine local

**Objectif :** Vérifier que le résolveur Unbound permet de résoudre le domaine local `ns01.ecocert4.fr` hébergé sur le serveur DNS faisant autorité `172.16.54.50`.

**Commande utilisée :**

```bash
dig @172.16.54.51 ns01.ecocert4.fr
```

* `dig` : Outil d'interrogation des serveurs DNS.
* `@172.16.54.51` : Interroge le serveur Unbound.
* `ns01.ecocert4.fr` : Nom de domaine local à résoudre.

**Résultat attendu :**

```text
;; ->>HEADER<<- opcode: QUERY, status: NOERROR
;; ANSWER SECTION:
ns01.ecocert4.fr.    ...    IN    A    172.16.54.50

;; SERVER: 172.16.54.51#53(172.16.54.51)
```

La réponse `172.16.54.50` confirme que la résolution de la zone locale `ecocert4.fr` fonctionne via Unbound et que le nom `ns01.ecocert4.fr` correspond bien au serveur DNS faisant autorité.

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
