---

description: Procédure de configuration d'une interface réseau en IP statique et des serveurs DNS sous Debian.

---

# Configuration network debian

![Bannière CUB](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** Jean DUPONT
    - **Date :** 14/09/2026
    - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Configuration de l'interface réseau](#3-configuration-de-linterface-reseau)
- [4. Configuration de la résolution DNS](#4-configuration-de-la-resolution-dns)
- [5. Application et vérification des paramètres](#5-application-et-verification-des-parametres)

## 2. Contexte

La configuration réseau statique est un prérequis fondamental pour garantir la stabilité, l'accessibilité et la prédictibilité d'un serveur Debian au sein de l'infrastructure. L'utilisation d'une adresse IP fixe prévient les changements inopinés liés aux baux DHCP, assurant ainsi la fiabilité des règles de pare-feu et des flux réseau entrants. Une configuration stricte des serveurs de noms (DNS) au niveau du composant de résolution système garantit également que les dépendances externes et internes puissent être résolues sans latence ni corruption.

## 3. Configuration de l'interface réseau

3.1. **Édition du fichier interfaces.** Ouvrir le fichier de configuration principal des interfaces réseau pour passer l'interface souhaitée en mode statique.

```bash title="Ouverture du fichier réseau"
nano /etc/network/interfaces
```

3.2. **Déclaration des paramètres IPv4.** Remplacer la configuration existante (souvent en `dhcp`) par les paramètres statiques de l'infrastructure. Il est impératif d'utiliser la notation CIDR si le système le supporte, ou de déclarer le netmask séparément en fonction de la version du paquet `ifupdown`.

```text title="/etc/network/interfaces" hl_lines="2-4"
auto ens18
iface ens18 inet static
    address 172.16.54.x/24
    gateway 172.16.54.254
```

- `auto ens18` : Instruis le système d'activer l'interface `eth0` automatiquement lors du démarrage.
- `iface ens18 inet static` : Définit l'interface réseau pour utiliser le protocole IPv4 (`inet`) avec une attribution fixe (`static`).
- `address 172.16.54.x/24` : Assigne l'adresse IP statique avec son masque de sous-réseau en notation CIDR directement intégrée.
- `gateway 172.16.54.254` : Spécifie l'adresse de la passerelle par défaut pour le routage du trafic externe.


## 4. Configuration de la résolution DNS

4.1. **Édition du fichier resolv.conf.** Modifier le fichier de résolution pour indiquer au serveur quels résolveurs DNS interroger pour la traduction des FQDN.

```bash title="Ouverture du fichier de résolution"
nano /etc/resolv.conf
```

4.2. **Déclaration des serveurs de noms.** Supprimer les anciennes entrées et déclarer les serveurs DNS internes ou externes fiables.

```text title="/etc/resolv.conf" hl_lines="1-2"
nameserver 1.1.1.1
nameserver 8.8.8.8
```

- `nameserver 1.1.1.1` : Déclare le serveur DNS primaire qui sera sollicité en premier lieu.
- `nameserver 8.8.8.8` : Déclare le serveur DNS secondaire en cas d'échec du premier.

!!! info "Persistance de la configuration"

    Si le paquet `resolvconf` ou `systemd-resolved` est installé, toute modification manuelle de `/etc/resolv.conf` sera écrasée au redémarrage. Dans ce cas, les entrées DNS devront être déclarées avec `dns-nameservers 1.1.1.1 8.8.8.8` directement dans `/etc/network/interfaces`.

## 5. Application et vérification des paramètres

5.1. **Redémarrage du service réseau.** Appliquer immédiatement les nouveaux paramètres réseau pour activer l'adresse IP statique et les nouvelles routes.

```bash title="Application des paramètres"
systemctl restart networking
```

!!! warning "Coupure de session"

    Si cette opération est effectuée via SSH sur l'adresse IP dynamiquement attribuée au préalable, la session sera déconnectée. Il faudra ouvrir une nouvelle session avec la nouvelle adresse IP statique configurée.

5.2. **Vérification de l'état réseau.** Confirmer que la nouvelle adresse est montée sur l'interface et que la résolution DNS fonctionne.

```bash title="Vérification de la connectivité"
ip a show ens18
ping -c 3 debian.org
```

- `ip a show` : Affiche les informations détaillées de la pile réseau et vérifie la présence du bloc inet configuré.
- `ping -c 3` : Teste la connectivité externe en 3 paquets ICMP, validant à la fois la passerelle et la résolution DNS.