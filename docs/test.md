---
description: Procédure de validation des éléments de configuration Zensical.
---

# Test de mise en forme

![Bannière CUB](https://epoka.bts.loutik.fr/assets/banniere_epoka.png)

---

!!! note "Informations"

    - **Auteur :** Louis MEDO
    - **Date :** 06/09/2026
    - **Domaine :** Test

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Validation des éléments Zensical](#3-validation-des-elements-zensical)

## 2. Contexte

Cette procédure valide la configuration Zensical en testant le rendu des composants Markdown (admonitions, blocs de code avancés et tableaux). Elle garantit que la documentation d'infrastructure (IaC) sera correctement formatée et lisible.

## 3. Validation des éléments Zensical

!!! tip "Bonne pratique SRE"
    
    L'automatisation nécessite une documentation standardisée, claire et reproductible.

3.1.  **Création du répertoire de test.** Exécution d'un script de préparation de l'environnement.

```bash title="setup.sh" hl_lines="2"
#!/bin/bash
mkdir -p /opt/zensical/test
```

- `#!/bin/bash` : Shebang indiquant au système d'utiliser l'interpréteur bash pour exécuter le script.
- `mkdir` : Commande permettant de créer un ou plusieurs répertoires.
- `-p` : Option (parents) forçant la création des répertoires parents manquants sans retourner d'erreur s'ils existent.
- `/opt/zensical/test` : Chemin absolu de la structure de répertoires ciblée.

3.2.  **Vérification des droits d'accès.** Configuration des permissions selon le standard.

| Permission | Description |
| :--- | :--- |
| `755` | :lucide-check: Lecture/Exécution globale, Écriture propriétaire |
| `600` | :lucide-check-check: Lecture/Écriture réservées au propriétaire |
| `777` | :lucide-x: Accès total déconseillé en production |