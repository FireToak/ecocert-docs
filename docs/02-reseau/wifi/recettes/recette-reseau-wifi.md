# Fiche recette - Accès réseau wifi

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** Louis MEDO
    - **Date :** 22/09/2026
    - **Domaine :** Réseau

---

## 1. Contexte du test

Validation de bout en bout des accès sans fil (Couches 1 à 3 du modèle OSI) pour les réseaux `TECHNIQUE-GP4` (VLAN 71) et `VISITEURS` (VLAN 81). Les tests vérifient l'association L2 des terminaux, l'allocation dynamique des adresses IP (DHCP), la joignabilité de la passerelle par défaut assignée au sous-réseau, et le bon fonctionnement du routage inter-VLAN vers les passerelles de sécurité selon la topologie logique ECOCERT.

## 2. Procédures de validation

### 2.1. Association Wi-Fi et bail DHCP - WIFI TECHNIQUE-GP4

**Objectif :** S'assurer que le client s'associe correctement au SSID technique et reçoit une adresse IP dynamique valide dans le sous-réseau du VLAN 71 (`192.168.4.192/28`).

**Commande utilisée :**

```text
Se connecter visuellement via l'interface des réseaux WIFI sur le poste de travail.
```

**Résultat attendu :**

```text
Connexion réussie
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Joignabilité de la passerelle - WIFI TECHNIQUE-GP4

**Objectif :** Valider la connectivité réseau de niveau 3 (ICMP) entre le client Wi-Fi et l'interface virtuelle (SVI) de sa passerelle définie sur le routeur (`192.168.4.206`).

**Commande utilisée :**

```bash
ping -c 4 192.168.4.206
```

- `ping` : Utilitaire de test de connectivité réseau de bout en bout (basé sur ICMP Echo Request/Reply).
- `-c 4` : Limite le nombre de requêtes à 4 paquets.
- `192.168.4.206` : Adresse IP de la passerelle attribuée au VLAN 71.

**Résultat attendu :**

```text
PING 192.168.4.206 (192.168.4.206) 56(84) bytes of data.
64 bytes from 192.168.4.206: icmp_seq=1 ttl=64 time=2.12 ms
...
--- 192.168.4.206 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Association Wi-Fi et bail DHCP - WIFI VISITEURS

**Objectif :** S'assurer que le client invité s'associe au SSID visiteur et obtient une adresse IP dynamique incluse dans le pool du VLAN 81 (`192.168.4.96/27`).

**Commande utilisée :**

```text
Se connecter visuellement via l'interface des réseaux WIFI sur le poste de travail.
```

**Résultat attendu :**

```text
Connexion réussie
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. Joignabilité de la passerelle - WIFI VISITEURS

**Objectif :** Valider la connectivité réseau de niveau 3 entre les hôtes isolés du réseau VISITEURS et leur passerelle de routage (`192.168.4.126`).

**Commande utilisée :**

```bash
ping -c 4 192.168.4.126
```

- `ping` : Outil de diagnostic IP.
- `-c 4` : Nombre de sondes ICMP envoyées.
- `192.168.4.126` : Dernière adresse utile du VLAN 81, configurée comme passerelle par défaut pour ce réseau.

**Résultat attendu :**

```text
PING 192.168.4.126 (192.168.4.126) 56(84) bytes of data.
64 bytes from 192.168.4.126: icmp_seq=1 ttl=64 time=3.45 ms
...
--- 192.168.4.126 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.5. Validation du chemin de routage (Traceroute)

**Objectif :** Confirmer le bon comportement de la table de routage. Le flux sortant des réseaux Wi-Fi doit d'abord traverser le commutateur L3/routeur inter-VLAN puis être redirigé vers l'interface interne du pare-feu Stormshield (`192.168.14.254/29`) via le TRUNK.

> [!warning] Règle de filtrage
> Assurez-vous au préalable que le pare-feu (Stormshield ec-fw-c1) autorise les trames ICMP de type "Time Exceeded" en sortie, sinon des astérisques `* * *` apparaîtront aux sauts intermédiaires.

**Commande utilisée :**

```bash
traceroute 9.9.9.9
```

- `traceroute` : Cartographie la route IP d'un paquet à travers les routeurs intermédiaires en augmentant progressivement le TTL (Time To Live).
- `9.9.9.9` : Hôte de destination (WAN) pour forcer le paquet à traverser toute la chaîne de routage interne.

**Résultat attendu :**

```text
traceroute to 9.9.9.9 (9.9.9.9), 30 hops max, 60 byte packets
 1  192.168.4.206 (192.168.4.206)  2.122 ms  2.100 ms  2.080 ms
 2  192.168.14.254 (192.168.14.254)  2.845 ms  2.831 ms  2.815 ms
 3  172.16.32.254 (172.16.32.254)  3.512 ms  3.501 ms  3.489 ms
 4  * * *
 ...
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
