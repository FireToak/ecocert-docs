# Configuration de Unbound

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 02/11/2026
> - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Configuration du résolveur local temporaire](#3-configuration-du-resolveur-local-temporaire)
- [4. Mise en place des serveurs racines (Root Hints)](#4-mise-en-place-des-serveurs-racines-root-hints)
- [5. Configuration de la journalisation et profil AppArmor](#5-configuration-de-la-journalisation-et-profil-apparmor)
- [6. Configuration principale d'Unbound](#6-configuration-principale-dunbound)
- [7. Bascule du résolveur en production](#7-bascule-du-resolveur-en-production)
- [8. Optimisation des performances (Facultatif)](#8-optimisation-des-performances-facultatif)

## 2. Contexte

La configuration d'Unbound vise à établir un serveur DNS récursif local performant et sécurisé pour l'infrastructure ECOCERT. Ce service permet de résoudre les requêtes DNS externes via les serveurs racines tout en transférant les requêtes de la zone interne vers les serveurs faisant autorité (Stub Zones). La procédure intègre également la configuration de la journalisation (via Rsyslog), l'adaptation stricte des règles de sécurité AppArmor (MAC) et l'optimisation des tampons réseau.

## 3. Configuration du résolveur local temporaire {#3-configuration-du-resolveur-local-temporaire}

3.1. **Définition d'un DNS récursif externe.** Configuration temporaire du système pour assurer la connectivité pendant l'installation.

```bash
nameserver 86.54.11.1
```

- `nameserver` : Directive indiquant l'adresse IP du serveur de noms à interroger (ici Quad9).

> [!info] Spécificité Debian 13 (DHCP)
> Avec Debian 13, si le service `dhcpd` est présent, le fichier `/etc/resolv.conf` est en lecture seule. Renseignez les paramètres dans `/etc/resolv.conf.head`.

## 4. Mise en place des serveurs racines (Root Hints)

4.1. **Téléchargement du fichier root.hints.** Récupération de la liste officielle des serveurs racines pour la résolution autonome.

```bash
sudo curl --output /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
sudo chown -R unbound:unbound /var/lib/unbound/
```

- `curl --output` : Télécharge le fichier distant et l'écrit à l'emplacement spécifié.
- `chown -R` : Assigne récursivement la propriété du dossier et de son contenu à l'utilisateur et au groupe `unbound`.

## 5. Configuration de la journalisation et profil AppArmor

5.1. **Initialisation des logs.** Création du fichier journal.

```bash
sudo touch /var/log/unbound.log
sudo chown unbound:unbound /var/log/unbound.log
```

- `touch` : Crée un fichier vide ou met à jour son horodatage.

5.2. **Dérogation AppArmor.** Autorisation pour le daemon Unbound d'écrire dans son fichier de log.

> [!danger] Restrictions AppArmor
> Sur les systèmes Debian récents, AppArmor bloque nativement la lecture et l'écriture dans `/var/log/`. Une dérogation est indispensable.

```bash
# Autoriser le daemon unbound à lire et ecrire dans le fichier /var/log/unbound.log
sudoedit /etc/apparmor.d/usr.sbin.unbound

/var/log/unbound.log rw,
```

- `rw,` : Règle AppArmor accordant les permissions de lecture (Read) et d'écriture (Write).

5.3. **Application des règles de sécurité.**

```bash
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.unbound
sudo systemctl restart apparmor
sudo systemctl restart unbound
```

- `apparmor_parser -r` : Recharge (`-r`) le profil AppArmor spécifié dans le noyau sans redémarrer le système complet.

## 6. Configuration principale d'Unbound

6.1. **Édition du fichier de configuration.** Définition des interfaces, du contrôle d'accès et des zones spécifiques.

```bash
sudoedit /etc/unbound/unbound.conf
```

```yaml
# Unbound configuration file for Debian.
include: "/etc/unbound/unbound.conf.d/*.conf"

server:
    # Interfaces d’écoute IPv4 sur le réseau
    interface: 172.16.54.51
    interface: 127.0.0.1

    # Contrôle d'accès : Autorisation avec traçage (dig +trace)
    access-control: 192.168.4.0/24 allow_snoop
    access-control: 172.16.54.0/24 allow_snoop
    access-control: 127.0.0.0/8 allow_snoop

    # Fichier indiquant les serveurs DNS racines
    root-hints: "/var/lib/unbound/root.hints"

    # Sécurité et masquage d'identité
    hide-version: yes
    hide-identity: yes
    qname-minimisation: yes
    do-ip4: yes

    # Journalisation
    logfile: /var/log/unbound.log
    verbosity: 1
    log-queries: yes

    # Désactivation de DNSSEC pour la zone locale
    domain-insecure: "ecocert4.fr."
    private-domain: "ecocert4.fr."

# Déclaration de la zone locale 
stub-zone:
    name: "ecocert4.fr."
    stub-addr: 172.16.54.50
```

- `allow_snoop` : Règle d'ACL autorisant les requêtes non récursives (utiles pour le débogage avec `dig +trace`).
- `qname-minimisation` : Technique de confidentialité n'envoyant aux serveurs racines que la portion stricte du domaine nécessaire (RFC 7816).
- `stub-zone` : Zone dont la résolution est transférée vers des serveurs d'autorité spécifiques sans passer par la racine.

6.2. **Validation et application.**

```bash
sudo unbound-checkconf
sudo systemctl restart unbound
sudo systemctl status unbound
```

- `unbound-checkconf` : Utilitaire natif vérifiant la validité syntaxique du fichier de configuration.

## 7. Bascule du résolveur en production {#7-bascule-du-resolveur-en-production}

7.1. **Configuration du client DNS local.** Modification de la configuration système pour interroger le service Unbound local en priorité, le serveur redondant en secondaire, et le DNS public en secours.

```bash
nameserver 127.0.0.1
nameserver 86.54.11.1
```

- `nameserver 127.0.0.1` : Pointe vers l'interface de bouclage locale (le service Unbound de cette machine).
- `nameserver 86.54.11.1` : Serveur public de dernier recours si l'infrastructure interne défaille.

## 8. Optimisation des performances (Facultatif)

8.1. **Ajustement de la mémoire tampon réseau.** Par défaut, le noyau Linux limite la taille maximale des buffers réseau, ce qui génère l'avertissement `warning: so-sndbuf 4194304 was not granted`. Cette étape modifie la limite du noyau (sysctl) pour autoriser Unbound à allouer un tampon d'envoi de 4 Mo, optimisant ainsi le traitement de requêtes simultanées massives.

```bash
echo "net.core.wmem_max=4194304" | sudo tee /etc/sysctl.d/99-unbound.conf
sudo sysctl -p /etc/sysctl.d/99-unbound.conf
```

- `echo ... | tee` : Génère la directive et l'écrit dans un fichier de configuration persistant, avec élévation de privilèges (`sudo`).
- `sysctl -p` : Charge et applique immédiatement les paramètres du fichier spécifié dans le noyau Linux en cours d'exécution.