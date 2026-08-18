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

# Étape 4 — Configurer `1_config.R`

Le fichier `1_config.R` contient les paramètres propres au projet et au poste de travail.

## 4.1 Créer `1_config.R`

1.  Ouvrir `Atlas/code/`.
2.  Ouvrir `ConfigTEMPLATE.txt`.
3.  Copier son contenu.
4.  Créer un fichier nommé exactement :

``` text
1_config.R
```

dans `Atlas/code/`. 5. Coller le contenu de `ConfigTEMPLATE.txt` dans ce fichier.

## 4.2 Adapter les paramètres à votre projet

Le contenu collé se présente ainsi, avec les lignes de paramètres commentées :

``` r
### Create a config.R file with paths locally and ignore it in git
## Taxon's name
#taxon <- "Hoverfly"
## Location of Dataset 1
#DATAPATH <- "C:/Users/CAG569/Desktop/HinateaCarte/HoverflyAtlasDATA/"
```

### Le taxon étudié

Remplacer `"Hoverfly"` par le nom de votre taxon, par exemple :

``` r
taxon <- "Hoverfly"
```

Ce nom sera utilisé automatiquement dans les titres du book, des chapitres et des fiches espèces générés dynamiquement

### Le chemin d'accès aux données (`DATAPATH`)

Remplacer le chemin par celui de votre propre poste de travail, pointant vers votre dossier de données local, par exemple :

``` r
DATAPATH <- "C:/Users/VotreNom/Chemin/vers/VosDonnees/"
```

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

Les données géographiques nécessaires au nouvel atlas doivent être placées dans `Atlas/data/`, à l'emplacement pointé par `DATAPATH` (voir Étape 4).

| Source de données | Chemin attendu dans `DATAPATH` | Téléchargement | Lien |
|------------------|------------------|------------------|------------------|
| Copernicus HRL VLCC — Grassland (2017–présent, 10 m) | `Grassland/20240101/CLMS_HRLVLCC_GRA_LU_0.tif` | Manuel | [land.copernicus.eu](https://land.copernicus.eu/en/products/high-resolution-layer-grasslands/grassland-2017-present-raster-10-m-europe-yearly) |
| Copernicus HRL VLCC — Tree Cover Density (2018–présent, 10 m) | `TreeCover/20240101/CLMS_HRLVLCC_TCD_LU_0.tif` | Manuel | [land.copernicus.eu](https://land.copernicus.eu/en/products/high-resolution-layer-forests-and-tree-cover/tree-cover-density-2018-present-raster-10-m-europe-yearly) |
| Climat WorldClim (BIO1/BIO12) | — | Automatique (package R `geodata`) | — |
| Altitude (MNS Lidar 2024) | `MNS_Lidar2024.tif` | Manuel | [Téléchargement (39.9 GB)](https://download.data.public.lu/resources/bd-l-lidar2024-releve-3d-du-territoire-luxembourgeois/20241223-093912/MNS_Lidar2024.tif) |
| Géologie (géoportail.lu, flux OAPIF) | `GEO_stratunit.xlsx` (table couleurs uniquement) | Automatique (flux) + Manuel (xlsx) | [GEO25K50K.zip](https://geologie.lu/opendata/cartgeol/geo25k50k/GEO25K50K.zip) (`\GEO25K50K\DOC\GEO_stratunit.xlsx`) |
| Soils map | `Carte_associations_de_sols` | Automatique | <https://data.public.lu/en/datasets/carte-des-associations-de-sols/> |
| Red List européenne | `EuropeanRedList.xlsx` | Manuel | à importer selon son jeu de données |

|  |
|:-----------------------------------------------------------------------|
| \## Étape 7 — Préparer les images |
| Les images utilisées par le livre sont placées dans : |
| `text Atlas/images/` |
| \### Image de couverture |
| L'image de couverture doit être nommée exactement : |
| `text cover.png` |
| \### Images des espèces |
| Les images d'espèces doivent respecter la convention utilisée automatiquement par `7_GenerateSpeciesPages.R` : |
| `text <species_key>.<Photographe>.<Licence>.<extension>` |
| Par exemple : |
| `text temnostoma_meridionale.Sam_Schaack.CC-BY-NC.png` |
| Le `species_key` correspond au nom de l'espèce transformé en identifiant de fichier. |
| Le nom du photographe et la licence sont utilisés pour générer automatiquement le crédit affiché sur la fiche. |
| \### Phylogenetic circle et phylogenetic graph |
| 2 images sont attendues pour le chapitre *Ecology* : |
| `phylogenetic_circle.png` et `phylogenetic_graph.png` |
| \### Images déjà fournies avec le template |
| Les pictogrammes de statut de conservation sont déjà fournies dans le projet. |

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

Il faut ensuite supprimer les qmd des espèces déjà générés et lancer le livre.

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

------------------------------------------------------------------------

## Étape 10 — Lancer un premier rendu

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

## Étape 11 — Consulter le livre généré

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

## Étape 12 — Relancer le rendu après une modification

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

## Étape 13 — Publier le livre en ligne

...
