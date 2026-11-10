# Déploiement du Certificat Racine sur Debian 13

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 10/11/2026
> - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Récupération du certificat racine](#3-recuperation-du-certificat-racine)
- [4. Vérification de l'empreinte cryptographique](#4-verification-de-lempreinte-cryptographique)
- [5. Importation dans le magasin de certificats Debian](#5-importation-dans-le-magasin-de-certificats-debian)

## 2. Contexte

Afin que les serveurs et conteneurs basés sur Debian fassent confiance aux services internes d'Ecocert (requêtes API, curl, webhooks), le certificat de l'autorité racine doit être intégré au magasin CA natif du système d'exploitation. Cette procédure documente les commandes Bash strictes pour télécharger, vérifier et installer le certificat, facilement transposables dans un playbook Ansible via les modules `get_url`, `copy` et `command`.

## 3. Récupération du certificat racine

3.1. **Téléchargement du certificat.** Récupération sécurisée de la clé publique de l'autorité depuis son point de terminaison web, sauvegardée temporairement pour vérification.

```bash title="download_root_ca.sh"
curl -k "https://pki.ecocert4.fr/roots.pem" -o /tmp/root_ca_ecocert.crt
```

- `-k` : (insecure) Autorise la connexion TLS même si la machine ne fait pas encore confiance à l'autorité émettrice.
- `-o` : Spécifie le chemin de destination. L'extension `.crt` est obligatoire pour l'importation sous Debian.

## 4. Vérification de l'empreinte cryptographique

> [!warning] "Intégrité"
> L'installation d'une autorité racine donne un contrôle total sur l'interception des flux (MITM). Il est impératif de valider que le fichier téléchargé correspond cryptographiquement à la PKI légitime avant son importation.
>
> **Hash en SHA256 du certificat racine :**
>
> ```bash
> 71A84C99304E592EF481D7A31E5223E3E988F79C05E8EE4EB12A802DB42AC43C
> ```

4.1. **Calcul de l'empreinte SHA256.** Utilisation d'OpenSSL pour extraire et afficher l'empreinte cryptographique du fichier téléchargé.

```bash title="verify_fingerprint.sh"
sha256sum /tmp/root_ca_ecocert.crt
```

## 5. Importation dans le magasin de certificats Debian

5.1. **Mise en place du certificat.** Déplacement du certificat validé vers le répertoire standard de Debian réservé aux autorités locales certifiées par l'administrateur. Cette action requiert les privilèges `root`.

```bash title="copy_certificate.sh"
sudo cp /tmp/root_ca_ecocert.crt /usr/local/share/ca-certificates/root_ca_ecocert.crt
sudo chmod 644 /usr/local/share/ca-certificates/root_ca_ecocert.crt
```

- `/usr/local/share/ca-certificates/` : Répertoire officiel sous Debian/Ubuntu pour les certificats tiers ou internes (ne pas utiliser `/etc/ssl/certs/` directement).
- `chmod 644` : Assure que le fichier est lisible par tous les utilisateurs et processus du système.

5.2. **Mise à jour du magasin système.** Exécution de l'utilitaire de mise à jour pour recompiler la base de données des certificats approuvés (`ca-certificates.crt`).

```bash title="update_ca.sh" hl_lines="1"
sudo update-ca-certificates
```

- `update-ca-certificates` : Parcours le dossier `/usr/local/share/ca-certificates/`, crée les liens symboliques nécessaires et met à jour le bundle global dans `/etc/ssl/certs/ca-certificates.crt`. Un message confirmera que `1 added` a été traité.
