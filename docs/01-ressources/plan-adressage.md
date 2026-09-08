# Plan d'adressage

![Bannière CUB](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

## Informations

- **Auteur :** Louis MEDO
- **Date :** 04/09/2026
- **Domaine :** Réseaux

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Plan d'adressage](#3-plan-dadressage)
- [4. Calcul du plan d'adressage](#4-calcul-du-plan-dadressage)

## 2. Contexte

Ce document définit le plan d'adressage IP (IPv4) de l'infrastructure réseau. La méthode VLSM (Variable Length Subnet Masking) est utilisée pour optimiser l'allocation des adresses IP en adaptant la taille de chaque sous-réseau aux stricts besoins d'hôtes requis par composant (avec une marge de 20%). L'objectif est de segmenter logiquement le réseau via des VLANs afin d'assurer l'isolation des flux, la sécurité et un routage optimisé.

## 3. Plan d'adressage

Le réseau parent utilisé est **192.168.4.0/24**.

| ID VLAN | Nom | Réseau | CIDR | Masque | Première @ | Dernière @ | Broadcast |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 11 | Administration | 192.168.4.0 | /26 | 255.255.255.192 | 192.168.4.1 | 192.168.4.62 | 192.168.4.63 |
| 21 | Service de certification | 192.168.4.64 | /27 | 255.255.255.224 | 192.168.4.65 | 192.168.4.94 | 192.168.4.95 |
| 81 | Wifi-Visiteurs | 192.168.4.96 | /27 | 255.255.255.224 | 192.168.4.97 | 192.168.4.126 | 192.168.4.127 |
| 61 | Expertise technique & conseil | 192.168.4.128 | /27 | 255.255.255.224 | 192.168.4.129 | 192.168.4.158 | 192.168.4.159 |
| 31 | Service référentiels | 192.168.4.160 | /27 | 255.255.255.224 | 192.168.4.161 | 192.168.4.190 | 192.168.4.191 |
| 71 | Services techniques | 192.168.4.192 | /28 | 255.255.255.240 | 192.168.4.193 | 192.168.4.206 | 192.168.4.207 |
| 41 | Formations professionnelles | 192.168.4.208 | /28 | 255.255.255.240 | 192.168.4.209 | 192.168.4.222 | 192.168.4.223 |
| 54 | Serveurs | 172.16.54.0 | /24 | 255.255.255.0 | 172.16.54.1 | 172.16.54.254 | 172.16.54.255 |
| 14 | Inter-co (SW & FW) | 192.168.14.248 | /29 | 255.255.255.248 | 192.168.14.249 | 192.168.14.254 | 192.168.14.255 |

## 4. Calcul du plan d'adressage

### 4.1. Figure 1 - Tableau des valeurs des puissances de 2

| Valeurs ² | Puissances ² |
| --- | --- |
| 128 | 7 |
| 64 | 6 |
| 32 | 5 |
| 16 | 4 |
| 8 | 3 |
| 4 | 2 |
| 2 | 1 |

### 4.2. Exemple de calcul pour le réseau `Administration` (VLAN 11)

Ce réseau nécessite 56 adresses (45 hôtes + 1 passerelle + 20% de marge).

**1. Trouver la puissance de 2 (bits d'hôtes)**
Pour héberger un besoin d'au moins 56 hôtes, il faut trouver la puissance de 2 permettant d'obtenir ce nombre de machines (en retirant l'adresse réseau et l'adresse de broadcast) :

- Équation : `2^x - 2 >= 56`
- Calcul : `2^6 - 2 = 62` (qui est >= 56)
- Il faut donc **6 bits** réservés pour les hôtes.

**2. Déterminer le préfixe CIDR**
Le préfixe définit la partie réseau sur les 32 bits d'une adresse IPv4 :

- Calcul : `32 bits - 6 bits = 26 bits`
- Le CIDR est donc **/26**.

**3. Calculer le masque de sous-réseau en décimal**
Le CIDR /26 signifie que les 26 premiers bits du masque sont à 1 :

- Notation binaire : `11111111 . 11111111 . 11111111 . 11000000`
- Conversion d'un octet plein (`11111111`) : Addition des poids `128 + 64 + 32 + 16 + 8 + 4 + 2 + 1 = 255`.
- Conversion du dernier octet (`11000000`) : Les deux premiers bits sont actifs, leurs poids sont `128 + 64 = 192`.
- Masque décimal : **255.255.255.192**

**4. Déterminer la plage d'adresses**
L'adresse réseau de départ est `192.168.4.0`. Le pas du sous-réseau (nombre total d'adresses dans le bloc) est de `2^6 = 64`.

- **Adresse de broadcast :** C'est la dernière adresse du bloc, soit l'adresse réseau à laquelle on ajoute toutes les valeurs d'hôtes possibles (`64 - 1 = 63`).
  - `192.168.4.0 + 63 = 192.168.4.63`
- **Première IP utilisable :** C'est l'adresse réseau incrémentée de 1.
  - `192.168.4.0 + 1 = 192.168.4.1`
- **Dernière IP utilisable :** C'est l'adresse de broadcast décrémentée de 1.
  - `192.168.4.63 - 1 = 192.168.4.62`

!!! Note "Calcul du prochain réseau"
    La même logique d'emprunt de bits hôtes a été réitérée en cascade pour les VLAN suivants, en modifiant le préfixe (/27, puis /28) à mesure que les besoins en hôtes diminuaient. On ajoute simplement un 1 à l'adresse de broadcast du réseau précédent. Par exemple si le broadcast est `192.168.4.63`, l'adresse du prochain réseau sera `192.168.4.64`.
