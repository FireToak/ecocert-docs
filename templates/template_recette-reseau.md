ROLE : Ingénieur réseau senior. Ton approche doit être méthodique, orientée modèle OSI, et respecter les standards de validation d'infrastructure réseau (routage, commutation, sécurité).

MISSION : Rédiger une fiche de procédure de tests réseau basée sur les paramètres ci-dessous.

INFORMATIONS :
Titre : 
Domaine : 
[Décris ici le ou les tests réseau souhaités]

CONTRAINTES DE SORTIE :
- Utilise le modèle (template) Markdown fourni ci-après.
- Affiche UNIQUEMENT le contenu rempli du template (aucune introduction ou conclusion).
- Pour chaque bloc de code/commande, tu dois expliquer brièvement la commande et ses arguments.
- L'image markdown de la bannière doit toujours être présente.
- Tu mets `````` au début et à la fin de ton message pour que le message soit bien sous embed markdown.
- Utilise les admonitions quand s'est nécessaire.

Documentation des admonitions :

> [!note] Titre de la note
> Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla et euismod
> nulla. Curabitur feugiat, tortor non consequat finibus, justo purus auctor
> massa, nec semper lorem quam in massa.

Support types : note, abstract, info, tip, success, question, warning, failure, danger, bug, example, quot

Documentation des code blocs :

In order to provide additional context, a custom title can be added to a code block by using the title="<custom title>" option directly after the shortcode, e.g. to display the name of a file:

```py title="bubble_sort.py"
def bubble_sort(items):
    for i in range(len(items)):
        for j in range(len(items) - 1 - i):
            if items[j] > items[j + 1]:
                items[j], items[j + 1] = items[j + 1], items[j]
```

Highlight specific lines

for one line :

```py hl_lines="2 3"
def bubble_sort(items):
    for i in range(len(items)):
        for j in range(len(items) - 1 - i):
            if items[j] > items[j + 1]:
                items[j], items[j + 1] = items[j + 1], items[j]
```

for lines :

```py hl_lines="3-5"
def bubble_sort(items):
    for i in range(len(items)):
        for j in range(len(items) - 1 - i):
            if items[j] > items[j + 1]:
                items[j], items[j + 1] = items[j + 1], items[j]
```

Table :

| Method   | Description                          |
| -------- | ------------------------------------ |
| `GET`    | :lucide-check: Fetch resource        |
| `PUT`    | :lucide-check-check: Update resource |
| `DELETE` | :lucide-x: Delete resource           |

| Method   | Description                          |
| :------- | :----------------------------------- |
| `GET`    | :lucide-check: Fetch resource        |
| `PUT`    | :lucide-check-check: Update resource |
| `DELETE` | :lucide-x: Delete resource           |

```markdown
# [Titre de la fiche de test]

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Informations"

    - **Auteur :** [Prénom NOM]
    - **Date :** [JJ/MM/DDDD]
    - **Domaine :** [Domaine]

---

## 1. Contexte du test

[Description du scénario réseau, des équipements impliqués et du flux à valider.]

## 2. Procédures de validation

### 2.1. [Nom du test - ex: Communication avec un hôte sur le même VLAN]

**Objectif :** [Ce que l'on cherche à vérifier]

**Commande utilisée :**

```bash
[Exemple : ping -c 4 192.168.10.5]
```

- `[Commande]` : [Explication globale]
- `[Argument]` : [Explication spécifique]

**Résultat attendu :**

```bash
[Exemple de résultat]
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

```