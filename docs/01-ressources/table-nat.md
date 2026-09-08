# Tables NAT

![Bannière CUB](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

## Informations

* **Auteur :** Louis MEDO
* **Date :** 04/09/2026
* **Domaine :** réseaux

---

## 1. Sommaire

* [1. Sommaire](#1-sommaire)
* [2. Contexte](#2-contexte)
* [3. Tables NAT](#3-tables-nat)

## 2. Contexte

Documentation référençant les règles de traduction d'adresses réseau (Source NAT / SNAT). Ce mécanisme masque les plans d'adressage internes (LAN, INTER-CO et SERVEURS) en les traduisant vers une adresse IP unique (`172.16.32.4`), permettant ainsi l'accès à des réseaux externes tout en sécurisant la topologie de l'infrastructure de base.

## 3. Tables NAT

### 3.1. Pare-feu ec-fw-c1 "StormShield"

| Description | IP src (Avant) | Port src | IP dst (Avant) | Port dst | IP src (Après) | Port src | IP dst (Après) | Port dst |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| LAN | `192.168.4.0/24` | `*` | `*` | `*` | `172.16.32.4` | `*` | `*` | `*` |
| INTER-CO (SW & FW) | `192.168.14.0/29` | `*` | `*` | `*` | `172.16.32.4` | `*` | `*` | `*` |
| SERVEURS | `172.16.54.0/24` | `*` | `*` | `*` | `172.16.32.4` | `*` | `*` | `*` |