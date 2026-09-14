# Tables de routage

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
- [4. Tables de routage](#4-tables-de-routage)

## 2. Contexte

Ce document définit les règles de routage statique et les réseaux directement connectés appliqués aux équipements cœur de l'infrastructure. Il détaille les tables de routage du commutateur de niveau 3 (ec-sw-c1), responsable du routage inter-VLAN (Production, Clients, Administration), et du pare-feu (ec-fw-c1), qui gère les flux vers la DMZ et l'accès extérieur (WAN).

## 4. Tables de routage

### 4.1. Switch `ec-sw-c1` "Switch Cisco L3"

| Nom                           | Réseau         | Masque          | Passerelle     | Interface      | Type |
| ----------------------------- | -------------- | --------------- | -------------- | -------------- | ---- |
| Inter-co                      | 192.168.14.248 | 255.255.255.248 | 192.168.14.254 | 192.168.14.253 | C    |
| Administration                | 192.168.4.0    | 255.255.255.192 | 192.168.4.62   | 192.168.4.62   | C    |
| Service de certification      | 192.168.4.64   | 255.255.255.224 | 192.168.4.94   | 192.168.4.94   | C    |
| Wifi-Visiteurs                | 192.168.4.96   | 255.255.255.224 | 192.168.4.126  | 192.168.4.126  | C    |
| Expertise technique & conseil | 192.168.4.128  | 255.255.255.224 | 192.168.4.158  | 192.168.4.158  | C    |
| Service référentiels          | 192.168.4.160  | 255.255.255.224 | 192.168.4.190  | 192.168.4.190  | C    |
| Services techniques           | 192.168.4.192  | 255.255.255.240 | 192.168.4.206  | 192.168.4.206  | C    |
| Formations professionnelles   | 192.168.4.208  | 255.255.255.240 | 192.168.4.222  | 192.168.4.222  | C    |
| Serveurs                      | 172.16.54.0    | 255.255.255.0   | 172.16.54.253  | 172.16.54.253  | C    |
| Default                       | 0.0.0.0        | 0.0.0.0         | 192.168.14.254 | 192.168.14.253 | S*   |

### 4.2. Pare-feu `ec-fw-c1` "Firewall StormShield"

| Nom      | Réseau         | Masque               | Passerelle     | interface      | Type |
| -------- | -------------- | -------------------- | -------------- | -------------- | ---- |
| WAN      | 172.16.32.0    | 255.255.255.0 (/24)  | 172.16.32.254  | 172.16.32.14   | C    |
| Inter-co | 192.168.14.248 | 255.255.255.248 (29) | 192.168.14.253 | 192.168.14.254 | C    |
| LAN      | 192.168.4.0    | 255.255.255.0 (/24)  | 192.168.14.253 | 192.168.14.254 | S    |
| SERVEURS | 172.16.54.0    | 255.255.255.0 (/24)  | 192.168.14.253 | 192.168.14.254 | S    |
| Default  | 0.0.0.0        | 0.0.0.0              | 172.16.32.254  | 172.16.32.14   | S*   |
