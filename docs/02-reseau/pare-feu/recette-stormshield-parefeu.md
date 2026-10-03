# Fiche recette - Configuration pare-feu Stormshield

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** Louis MEDO
    - **Date :** 21/09/2026
    - **Domaine :** Réseau

---

## 1. Contexte du test

Validation de la configuration initiale du pare-feu Stormshield (`ec-fw-c1`) dans l'infrastructure ECOCERT. Les tests visent à confirmer l'accessibilité des interfaces d'administration distante (SSH et HTTPS) via l'adresse IP `192.168.14.254`, le fonctionnement de la translation d'adresse (NAT) sur l'interface de sortie (`em0`), ainsi que la connectivité de la couche 3 (OSI) avec le commutateur cœur de réseau `192.168.14.253`.

## 2. Procédures de validation

### 2.1. Accès SSH au pare-feu

**Objectif :** Vérifier l'accès à l'interface en ligne de commande (CLI) du pare-feu depuis le réseau interne.

**Commande utilisée :**

```bash
ssh admin@192.168.14.254
```

- `ssh` : Lance le client Secure Shell pour établir une connexion distante chiffrée.
- `admin@192.168.14.254` : Précise l'utilisateur cible ("admin") et l'adresse IP de l'interface LAN du pare-feu (VLAN 14 Inter-co).

**Résultat attendu :**

```bash
Password:
ec-fw-c1-VMSNSX02H5207A9>
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Accès interface web au pare-feu (HTTPS)

**Objectif :** Valider l'accès au portail d'administration Web (GUI) du pare-feu.

**Commande utilisée :**

```bash
curl -k -I https://192.168.14.254
```

- `curl` : Utilitaire réseau permettant de transférer des données depuis un serveur.
- `-k` : Demande à curl d'ignorer la validation du certificat SSL (utile pour les certificats auto-signés du pare-feu).
- `-I` : Requête uniquement les en-têtes HTTP (méthode HEAD) pour vérifier si le serveur répond correctement, sans télécharger le corps de la page.
- `https://192.168.14.254` : L'URL d'administration cible.

**Résultat attendu :**

```http
HTTP/1.1 200 OK
Content-Type: text/html
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Validation de la translation d'adresse (NAT)

**Objectif :** Confirmer que le trafic sortant est correctement traduit vers l'adresse IP WAN du pare-feu (`172.16.32.14`).

!!! tip "Conseils"
    Générez du trafic ICMP depuis une machine du réseau LAN vers l'IP `192.178.223.94` pendant l'exécution de cette capture.

**Commande utilisée :**

```bash
tcpdump -i em0 -nn icmp
```

- `tcpdump` : Outil de capture et d'analyse de paquets en ligne de commande.
- `-i em0` : Indique l'interface réseau sur laquelle écouter (interface externe du pare-feu).
- `-nn` : Désactive la résolution DNS des adresses IP et la résolution des numéros de ports, accélérant l'affichage.
- `icmp` : Filtre la capture pour n'afficher que les paquets liés au protocole ICMP.

**Résultat attendu :**

```text hl_lines="1"
16:15:31.528000 IP 172.16.32.14 > 192.178.223.94: ICMP echo request, id 1, seq 1, length 40
16:15:31.542816 IP 192.178.223.94 > 172.16.32.14: ICMP echo reply, id 1, seq 1, length 40
```

!!! success "Critère de réussite"
    La présence de l'IP source `172.16.32.14` (au lieu de l'IP privée d'origine) sur le paquet "echo request" valide l'application de la règle SNAT (Masquerading).

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. Test de connectivité routage Inter-co

**Objectif :** Vérifier que le pare-feu parvient à joindre le commutateur L3 de cœur de réseau (`192.168.14.253`) sur le segment réseau `192.168.14.248/29`.

**Commande utilisée :**

```bash
ping -c 4 192.168.14.253
```

- `ping` : Utilitaire de diagnostic testant l'accessibilité d'un hôte via le protocole ICMP.
- `-c 4` : Définit le compteur de requêtes "Echo Request" envoyées à 4, permettant d'arrêter la commande automatiquement.
- `192.168.14.253` : Adresse IP du commutateur L3 faisant office de routeur interne.

**Résultat attendu :**

```bash
4 packets transmitted, 4 received, 0% packet loss
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
