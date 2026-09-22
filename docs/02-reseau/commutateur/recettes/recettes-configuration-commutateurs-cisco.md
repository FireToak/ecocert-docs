# Fiche recette - Configuration commutateurs Cisco (Passerelles et Accès)

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** Louis MEDO
    - **Date :** 21/09/2026
    - **Domaine :** Réseau

---

## 1. Contexte

Validation exhaustive de la couche de routage (Niveau 3 OSI) et des accès d'administration (Niveau 7 OSI) de l'infrastructure LAN ECOCERT. Cette procédure vérifie individuellement la disponibilité de chaque passerelle par défaut (SVI) hébergée sur le commutateur cœur de réseau `ec-sw-c1`. Elle valide également l'accessibilité sécurisée (SSH) aux équipements d'accès L2 (`ec-sw-a1`) et de cœur L3 (`ec-sw-c1`).

## 2. Accessibilité passerelle

### 2.1. VLAN 11 (Administration)

**Objectif :** Vérifier que l'interface de routage du VLAN 11 répond aux requêtes ICMP.

**Commande utilisée :**

```bash
ping 192.168.4.62
```

* `ping` : Utilitaire de test de connectivité de couche 3 (ICMP Echo Request).
* `192.168.4.62` : Adresse IP de la SVI VLAN 11 sur le commutateur L3.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. VLAN 14 (Inter-co)

**Objectif :** Vérifier que l'interface de routage du VLAN 14 (Interconnexion) répond aux requêtes ICMP.

**Commande utilisée :**

```bash
ping 192.168.14.253
```

* `ping` : Utilitaire de test de connectivité de couche 3 (ICMP).
* `192.168.14.253` : Adresse IP de la SVI VLAN 14 sur le commutateur L3.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. VLAN 21 (Certification)

**Objectif :** Vérifier que l'interface de routage du VLAN 21 répond aux requêtes ICMP.

**Commande utilisée :**

```bash
ping 192.168.4.94
```

* `ping` : Utilitaire de test de connectivité de couche 3 (ICMP).
* `192.168.4.94` : Adresse IP de la SVI VLAN 21 sur le commutateur L3.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. VLAN 41 (Forma Pro)

**Objectif :** Vérifier que l'interface de routage du VLAN 41 répond aux requêtes ICMP.

**Commande utilisée :**

```bash
ping 192.168.4.222
```

* `ping` : Utilitaire de test de connectivité de couche 3 (ICMP).
* `192.168.4.222` : Adresse IP de la SVI VLAN 41 sur le commutateur L3.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.5. VLAN 54 (Serveurs)

**Objectif :** Vérifier que l'interface de routage du VLAN 54 répond aux requêtes ICMP.

**Commande utilisée :**

```bash
ping 172.16.54.253
```

* `ping` : Utilitaire de test de connectivité de couche 3 (ICMP).
* `172.16.54.253` : Adresse IP de la SVI VLAN 54 sur le commutateur L3.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.6. VLAN 61 (Expertise Tech Conseil)

**Objectif :** Vérifier que l'interface de routage du VLAN 61 répond aux requêtes ICMP.

**Commande utilisée :**

```bash
ping 192.168.4.158
```

* `ping` : Utilitaire de test de connectivité de couche 3 (ICMP).
* `-c 4` : Limite le test à 4 requêtes.
* `192.168.4.158` : Adresse IP de la SVI VLAN 61 sur le commutateur L3.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.7. VLAN 71 (Techniques)

**Objectif :** Vérifier que l'interface de routage du VLAN 71 répond aux requêtes ICMP.

**Commande utilisée :**

```bash
ping 192.168.4.206
```

* `ping` : Utilitaire de test de connectivité de couche 3 (ICMP).
* `192.168.4.206` : Adresse IP de la SVI VLAN 71 sur le commutateur L3.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.8. VLAN 81 (Wifi-Visiteurs)

**Objectif :** Vérifier que l'interface de routage du VLAN 81 répond aux requêtes ICMP.

**Commande utilisée :**

```bash
ping 192.168.4.126
```

* `ping` : Utilitaire de test de connectivité de couche 3 (ICMP).
* `192.168.4.126` : Adresse IP de la SVI VLAN 81 sur le commutateur L3.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.9. VLAN 31 (Référentiels)

**Objectif :** Vérifier que l'interface de routage du VLAN 31 répond aux requêtes ICMP.

**Commande utilisée :**

```bash
ping 192.168.4.190
```

* `ping` : Utilitaire de test de connectivité de couche 3 (ICMP).
* `192.168.4.190` : Adresse IP de la SVI VLAN 41 sur le commutateur L3.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

## 3. Administration distante SSH

### 3.1. Commutateur L2 (`ec-sw-a1`)

**Objectif :** Valider l'accès sécurisé à l'interface de ligne de commande (CLI) du commutateur d'accès (Couche 2) via le VLAN d'administration technique.

!!! tip "VLAN de Management L2"
    Sur le switch L2 `ec-sw-a1`, l'interface d'administration (SVI) est configurée sur le VLAN 71 (Technique).

**Commande utilisée :**

```bash
ssh dreamlike@192.168.4.205
```

* `ssh` : Appel du client Secure Shell (Couche 7) pour une session distante chiffrée.
* `dreamlike` : Compte utilisateur disposant du privilège d'administration maximal (15).
* `@192.168.4.205` : Adresse IP attribuée à l'interface VLAN 71 du switch d'accès `ec-sw-a1`.

**Résultat attendu :**

```bash
Password: 
ec-sw-a1#
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 3.2. Commutateur L3 (`ec-sw-c1`)

**Objectif :** Valider l'accès sécurisé à l'interface de ligne de commande (CLI) du commutateur cœur de réseau (Couche 3).

**Commande utilisée :**

```bash
ssh dreamlike@192.168.4.206
```

* `ssh` : Appel du client Secure Shell (Couche 7) pour une session distante chiffrée.
* `dreamlike` : Compte utilisateur configuré sur le commutateur avec le privilège 15.
* `@192.168.4.206` : Adresse IP de la passerelle technique (VLAN 71) hébergée sur le commutateur L3 `ec-sw-c1`.

**Résultat attendu :**

```bash
Password: 
ec-sw-c1#
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

## 4. Accès Internet et chemin de routage

**Objectif :** Vérifier la connectivité de bout en bout vers Internet et valider la résolution DNS depuis un poste client d'un réseau local (ex: VLAN 11).

**Commande utilisée :**

```cmd
tracert loutik.fr
```

- `tracert` : Utilitaire réseau Windows qui trace l'itinéraire pris par les paquets IP jusqu'à la destination en affichant chaque routeur traversé (saut) grâce à l'incrémentation du TTL (Time To Live).
- `loutik.fr` : Nom de domaine cible. Son utilisation permet de valider implicitement le bon fonctionnement du service DNS en plus du routage.

**Résultat attendu :**

```cmd
Détermination de l'itinéraire vers loutik.fr
avec un maximum de 30 sauts :

  1    <1 ms    <1 ms    <1 ms  192.168.4.62
  2    <1 ms    <1 ms    <1 ms  192.168.14.254
  3    10 ms    11 ms    10 ms  [IP_PASSERELLE_FAI]
  ...
  8    15 ms    14 ms    15 ms  [IP_PUBLIQUE_LOUTIK]

Itinéraire déterminé.
```

!!! warning "Analyse des sauts"
    Le premier saut doit correspondre à la passerelle du VLAN local (ex: `192.168.4.62`). Le second saut doit être l'interface LAN du pare-feu Stormshield (`192.168.14.254`).

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
