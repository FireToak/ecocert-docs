# Fiche recette - Contrôleur Unifi

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** Louis MEDO
    - **Date :** 22/09/2026
    - **Domaine :** Réseau

---

## 1. Contexte du test

Validation post-déploiement du contrôleur réseau Unifi. Les tests visent à s'assurer de la disponibilité du service applicatif (Couche 7 du modèle OSI), de la connectivité au réseau WAN pour le téléchargement des mises à jour (Couche 3/4), et du bon provisionnement des réseaux logiques (VLAN) et sans fil (WLAN).

## 2. Procédures de validation

### 2.1. Vérification du fonctionnement du service uosserver

**Objectif :** S'assurer que le processus du contrôleur UniFi OS est actif, démarré et s'exécute sans erreur en mémoire.

**Commande utilisée :**

```bash
sudo systemctl status uosserver
```

- `sudo` : Permet d'exécuter la commande avec les privilèges d'administration (root), nécessaires pour interroger systemd.
- `systemctl` : Utilitaire de gestion du gestionnaire de services système `systemd`.
- `status` : Argument demandant l'affichage de l'état actuel du service.
- `uosserver` : Nom du service ciblé (UniFi OS Server).

**Résultat attendu :**

```bash
● uosserver.service - UniFi OS Server Service
     Loaded: loaded (/etc/systemd/system/uosserver.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-09-22 19:06:51 CEST; 2min 44s ago
 Invocation: cc5a1db737654752bd0a4ae6e986b24c
   Main PID: 951 (uosserver-servi)
      Tasks: 8 (limit: 2252)
     Memory: 59.3M (peak: 93.4M, swap: 3.6M, swap peak: 3.6M)
        CPU: 850ms
     CGroup: /system.slice/uosserver.service
             ├─ 951 /var/lib/uosserver/bin/uosserver-service
             └─1100 /var/lib/uosserver/bin/discovery
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Vérification de l'accès Internet (Mises à jour)

**Objectif :** Vérifier que le contrôleur est capable de résoudre un nom de domaine (DNS) et d'atteindre le réseau WAN (Internet) pour s'assurer du bon fonctionnement du routage vers les serveurs de mises à jour Ubiquiti.

**Commande utilisée :**

```bash
ping -c 4 ping.ui.com
```

- `ping` : Outil de diagnostic réseau envoyant des paquets ICMP (Echo Request) pour vérifier la connectivité IP vers un hôte.
- `-c 4` : Argument (count) spécifiant d'envoyer exactement 4 requêtes avant de s'arrêter.
- `ping.ui.com` : L'adresse de destination (serveur Ubiquiti) testée pour valider à la fois la résolution DNS et le routage.

**Résultat attendu :**

```bash
PING ping.ui.com (54.230.12.11) 56(84) bytes of data.
64 bytes from 54.230.12.11: icmp_seq=1 ttl=55 time=12.4 ms
64 bytes from 54.230.12.11: icmp_seq=2 ttl=55 time=11.8 ms
64 bytes from 54.230.12.11: icmp_seq=3 ttl=55 time=12.1 ms
64 bytes from 54.230.12.11: icmp_seq=4 ttl=55 time=11.9 ms

--- ping.ui.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Vérification de la configuration des VLAN et réseaux Wi-Fi

**Objectif :** Confirmer que l'isolation logique (VLAN) et les réseaux de diffusion (SSID) sont correctement paramétrés et associés sur le contrôleur.

> [!info] Vérification via Interface Web
> Cette étape est une vérification visuelle de la configuration (Infrastructure as Code ou configuration manuelle) directement sur le portail d'administration Unifi.

**Actions à réaliser :**

1. Naviguer dans **Settings > Networks**.
2. Vérifier la présence et la configuration des sous-réseaux :
   - `VLAN TECHNIQUE`
   - `VLAN VISITEURS`
3. Naviguer dans **Settings > WiFi**.
4. Vérifier la présence et l'association (VLAN mapping) des SSID :
   - `WIFI TECHNIQUE` (associé au VLAN TECHNIQUE)
   - `WIFI VISITEURS` (associé au VLAN VISITEURS)

**Résultat attendu :**

Tous les réseaux logiques et SSID sont présents, activés, et correctement mappés pour assurer le cloisonnement réseau attendu.

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
