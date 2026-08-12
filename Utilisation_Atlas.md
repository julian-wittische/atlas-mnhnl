# Guide utilisation du template

Ce guide explique comment utiliser le template pour créer et générer son propre atlas.

Le document **Fonctionnement du template** explique en détail ce que font les différents scripts et comment les éléments du projet sont liés entre eux. Ce guide se concentre uniquement sur les étapes à réaliser pour configurer et utiliser le template.

------------------------------------------------------------------------

## Étape 1 — Récupérer le projet

Le projet s'appelle `atlas-mnhnl`.

Il contient notamment :

``` text
atlas-mnhnl/
├── atlas-mnhnl.Rproj
└── Atlas/
    ├── _quarto.yml
    ├── code/
    ├── data/
    ├── images/
    ├── species_account/
    ├── species_content/
    └── ...
```

Vérifier que les éléments suivants sont présents :

- `atlas-mnhnl.Rproj`
- le dossier `Atlas/`
- `Atlas/_quarto.yml`
- `Atlas/code/`
- `Atlas/images/`
- `Atlas/species_account/`
- `Atlas/species_content/`

------------------------------------------------------------------------

## Étape 2 — Ouvrir le projet dans RStudio

1.  Ouvrir RStudio.
2.  Aller dans **File → Open Project...**
3.  Sélectionner le fichier `atlas-mnhnl.Rproj`.

------------------------------------------------------------------------

## Étape 3 — Installer les librairies R nécessaires

Le template utilise plusieurs packages R pour :

- manipuler les données ;
- effectuer les traitements spatiaux ;
- produire les cartes ;
- générer les graphiques ;
- construire les cartes interactives ;
- communiquer avec certaines sources externes.

Installer les packages nécessaires du script `0_Initialistion.R`

------------------------------------------------------------------------

## Étape 4 — Configurer `1_config.R`

Le fichier `1_config.R` contient les paramètres propres au projet et au poste de travail.

### 4.1 Créer `1_config.R`

1.  Ouvrir `Atlas/code/`.
2.  Ouvrir `ConfigTEMPLATE.txt`.
3.  Copier son contenu.
4.  Créer un fichier nommé exactement :

``` text
1_config.R
```

dans `Atlas/code/`.

5.  Coller le contenu de `ConfigTEMPLATE.txt` dans ce fichier.

### 4.2 Configurer le chemin des données

Modifier `DATAPATH` afin qu'il pointe vers le dossier contenant les données du nouvel atlas.

### 4.3 Configurer le taxon

Modifier également le taxon utilisé par le projet afin qu'il corresponde au groupe étudié dans le nouvel atlas.

Les paramètres exacts à modifier sont ceux indiqués dans `ConfigTEMPLATE.txt`.

------------------------------------------------------------------------

## Étape 5 — Préparer les données d'observation

Les données du nouvel atlas doivent être adaptées au format attendu par `3_LoadData.R`.

Le résultat final de ce script doit être une table `DB` contenant au minimum :

| Colonne  | Contenu                             |
|----------|-------------------------------------|
| `Lat`    | Latitude en WGS84 / EPSG:4326       |
| `Long`   | Longitude en WGS84 / EPSG:4326      |
| `ID`     | Nom scientifique de l'espèce        |
| `Source` | Source ou méthode de collecte       |
| `Year`   | Année d'observation                 |
| `Date`   | Date complète de l'observation      |
| `Cell`   | Identifiant de cellule de la grille |

Pour les cartes interactives et leurs fenêtres d'information, `DB_full` doit également contenir :

| Colonne       | Contenu                                  |
|---------------|------------------------------------------|
| `Origin`      | Origine précise de l'observation         |
| `Observateur` | Observateur ou collecteur                |
| `Identifieur` | Personne ayant identifié l'observation   |
| `URL`         | Lien vers l'observation lorsqu'il existe |

La préparation et l'harmonisation des données doivent être réalisées dans :

``` text
Atlas/code/3_LoadData.R
```

------------------------------------------------------------------------

## Étape 6 — Préparer les données géographiques

Les données géographiques nécessaires au nouvel atlas doivent être placées dans `Atlas/data/`.

Selon les chapitres conservés dans le projet, cela peut notamment inclure :

- les frontières du territoire étudié ;
- les frontières administratives ou régionales ;
- les données utilisées pour la géologie ;
- les données utilisées pour les sols ;
- les données d'occupation du sol ;
- les limites communales ;
- les autres couches nécessaires aux cartes.

Les fichiers réellement nécessaires dépendent des chapitres et des scripts conservés dans le nouvel atlas. Les chemins et paramètres propres aux données géographiques doivent être adaptés dans les scripts concernés.

------------------------------------------------------------------------

## Étape 7 — Préparer les images

Les images utilisées par le livre sont placées dans :

``` text
Atlas/images/
```

### Image de couverture

L'image de couverture doit être nommée exactement :

``` text
cover.png
```

### Images des espèces

Les images d'espèces doivent respecter la convention utilisée automatiquement par `7_GenerateSpeciesPages.R` :

``` text
<species_key>.<Photographe>.<Licence>.<extension>
```

Par exemple :

``` text
temnostoma_meridionale.Sam_Schaack.CC-BY-NC.png
```

Le `species_key` correspond au nom de l'espèce transformé en identifiant de fichier.

Le nom du photographe et la licence sont utilisés pour générer automatiquement le crédit affiché sur la fiche.

### Images déjà fournies avec le template

Les pictogrammes de statut de conservation sont déjà fournies dans le projet.

------------------------------------------------------------------------

## Étape 8 — Préparer les fiches espèces

Les fiches espèces sont générées automatiquement à partir des données.

L'utilisateur **ne doit pas créer manuellement le fichier `.qmd` de chaque espèce**.

Le fonctionnement est le suivant :

``` text
Données d'observation
        ↓
Taxonomie.R
        ↓
DB_taxo
        ↓
7_GenerateSpeciesPages.R
        ↓
species_account/nom_espece.qmd
        ↓
8_InjectContent.R
        ↓
species_content/nom_espece.txt
        ↓
Fiche espèce complète
```

### 8.1 Ajouter le texte d'une espèce

Pour chaque espèce à documenter, créer un fichier dans :

``` text
Atlas/species_content/
```

Le fichier doit utiliser le nom de l'espèce sous la forme attendue par le template.

Par exemple :

``` text
blera_fallax.txt
```

Le texte doit utiliser les titres reconnus par `8_InjectContent.R` :

``` markdown

## Description

...

## Habitat

### Immature

...

### Mature

...

## Distribution

...

## Notes

...

### Author {.author-species}

...
```

Le texte placé dans ce fichier sera automatiquement inséré dans la fiche générée.

### 8.2 Ne pas modifier directement les fiches générées

Les fichiers présents dans :

``` text
Atlas/species_account/
```

sont des fichiers générés automatiquement.

Pour modifier le contenu rédactionnel d'une espèce, utiliser :

``` text
Atlas/species_content/
```

Pour modifier la structure ou la présentation de **toutes les fiches espèces**, modifier :

``` text
Atlas/species_account/_template.qmd
```

Il n'est donc généralement pas nécessaire de modifier individuellement les fichiers :

``` text
species_account/nom_espece.qmd
```

------------------------------------------------------------------------

## Étape 9 — Ajouter une nouvelle espèce

Pour ajouter une nouvelle espèce au livre :

1.  Vérifier que l'espèce est présente dans les données d'observation.
2.  Vérifier que son nom scientifique est correctement renseigné dans la colonne `ID`.
3.  Vérifier qu'elle possède au moins une observation valide pouvant être utilisée par le pipeline taxonomique.
4.  Créer son fichier :

``` text
Atlas/species_content/nom_espece.txt
```

5.  Rédiger le contenu avec les titres attendus.
6.  Ajouter une image de l'espèce dans `Atlas/images/` en respectant la convention de nommage.
7.  Lancer le rendu du livre.

Lors du rendu, le template :

- identifie l'espèce ;
- récupère les informations taxonomiques nécessaires ;
- génère sa fiche à partir de `_template.qmd` ;
- récupère les noms vernaculaires lorsque les sources disponibles en fournissent ;
- associe l'image correspondante ;
- insère le contenu de `species_content/` ;
- ajoute la fiche dans le sommaire du livre.

Il n'est donc pas nécessaire d'ajouter manuellement le chemin de la nouvelle espèce dans `_quarto.yml`.

------------------------------------------------------------------------

## Étape 10 — Configurer les chapitres du livre

Le sommaire et l'ordre des chapitres sont définis dans :

``` text
Atlas/_quarto.yml
```

Les chapitres standards peuvent être ajoutés ou retirés directement dans `chapters:`.

Par exemple :

``` yaml
book:
  chapters:
    - index.qmd
    - introduction.qmd
    - methodology.qmd
    - ecology.qmd
    - references.qmd
```

Les fiches espèces sont une exception : leur liste est gérée automatiquement par le pipeline de génération.

Les chapitres spécifiques au nouvel atlas peuvent être adaptés ou remplacés selon les besoins du projet.

------------------------------------------------------------------------

## Étape 11 — Adapter les textes des chapitres

Les chapitres narratifs se trouvent dans `Atlas/`.

Ils peuvent être directement modifiés pour le nouvel atlas :

``` text
introduction.qmd
history.qmd
ecology.qmd
methodology.qmd
glossary.qmd
spatial.qmd
conservation.qmd
```

Les chapitres du dossier `biophysical/` peuvent également être adaptés :

``` text
biophysical/
├── climate.qmd
├── geo_topography.qmd
└── land_use_cover.qmd
```

------------------------------------------------------------------------

## Étape 12 — Lancer un premier rendu

Dans RStudio :

1.  Ouvrir le **Terminal**.
2.  Vérifier que le terminal se trouve à la racine du projet :

``` text
atlas-mnhnl/
```

3.  Lancer :

``` bash
quarto render Atlas
```

Le rendu déclenche automatiquement le pipeline de préparation du livre, notamment la génération et la mise à jour des fiches espèces.

------------------------------------------------------------------------

## Étape 13 — Consulter le livre généré

Une fois le rendu terminé, le livre HTML est généré dans :

``` text
Atlas/_book/
```

Ouvrir :

``` text
Atlas/_book/index.html
```

pour consulter le livre.

------------------------------------------------------------------------

## Étape 14 — Relancer le rendu après une modification

Après une modification d'un :

- fichier `.qmd` ;
- script R ;
- fichier de configuration ;
- fichier de données ;
- contenu d'une fiche espèce ;
- image utilisée par le livre ;

relancer :

``` bash
quarto render Atlas
```

### Si une modification n'apparaît pas

Quarto peut réutiliser les résultats déjà calculés présents dans :

``` text
Atlas/_freeze/
```

Si un changement effectué dans un script ne semble pas être pris en compte, supprimer le sous-dossier `_freeze` correspondant au chapitre concerné, puis relancer le rendu.

------------------------------------------------------------------------

## Étape 15 — Publier le livre en ligne

...
