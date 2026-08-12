------------------------------------------------------------------------


# Fonctionnement du template

> Ce document décrit le fonctionnement technique du template. Pour la procédure (installation, configuration, rendu), voir le *Guide.*

## Vue d'ensemble

Ce projet est un template, en Quarto et R, pour construire un atlas de biodiversité. Le sommaire du livre est défini dans `_quarto.yml`, dans le sous-dossier `Atlas/`. Chaque chapitre est un fichier `.qmd`, contenant à la fois du texte et des blocs de code R qui génèrent automatiquement cartes, graphiques et tableaux.

Le dossier `code/` contient les scripts R communs : préparation des données, fonctions de cartographie, génération des fiches espèces.

Le fichier `style.scss` définit l'apparence visuelle du site (couleurs, tailles, espacements, ...)

Racine du projet R : `atlas-mnhnl` (fichier `atlas-mnhnl.Rproj`).

## Arborescence

```         
Atlas/
├── _quarto.yml          → sommaire du livre
├── style.scss           → couleurs / mise en page du site
├── index.qmd             → page de couverture
├── acknowledgement.qmd   → page de remerciements
├── introduction.qmd
├── history.qmd
├── ecology.qmd
├── methodology.qmd
├── glossary.qmd
├── spatial.qmd
├── conservation.qmd
├── references.qmd
├── references.bib       → informations de citation
├── biophysical/
│   ├── climate.qmd
│   ├── geo_topography.qmd
│   └── land_use_cover.qmd
├── species_account/
│   ├── _template.qmd          → modèle pour les fiches espèce
│   └── (une fiche .qmd générée par espèce)
├── species_content/     → un .txt par espèce, texte rédigé
├── images/               → toutes les images du projet
├── data/                 → données géographiques du Luxembourg (frontières, géologie, sols, occupation du sol)
└── code/                 → scripts R 
```

## `_quarto.yml`

Structure résumée :

``` yaml
project:
  type: book
book:
  title: Atlas of Hoverflies in Luxembourg
  chapters:
    - index.qmd
    - acknowledgement.qmd
    - introduction.qmd
    - part: Biophysical
      chapters:
        - biophysical/geo_topography.qmd
        - biophysical/climate.qmd
        - biophysical/land_use_cover.qmd
    - history.qmd
    - ecology.qmd
    - methodology.qmd
    - glossary.qmd
    - part: Species accounts
      chapters:
        - species_account/blera_fallax.qmd
        - species_account/myathropa_florea.qmd
    - spatial.qmd
    - conservation.qmd
    - references.qmd
format:
  html:
    theme:
      light: [zephyr, style.scss]
```

La liste `chapters:` détermine l'ordre exact des pages du livre. Les blocs `part:` créent une sous-section dans un chapitre. La ligne `theme: light: [zephyr, style.scss]` applique le thème de base puis les personnalisations faites dans `style.scss`.

**Ajout d'un chapitre standard** : création du fichier `.qmd` correspondant, puis ajout de son chemin dans la liste `chapters:` à la position voulue.

**Cas des fiches espèces** : l'ajout de chemins sous `part: Species accounts` est automatisé par `7_GenerateSpeciesPages.R` et remis à jour à chaque rendu par `pre-render.R`.

## Contenu d'un fichier `.qmd`

Exemple : `biophysical/climate.qmd`.

```` markdown
# Climate

```{r setup}
#| echo: false
here::i_am("atlas-mnhnl.Rproj")
source(here::here("Atlas", "code", "0_Initialisation.R"))
source(here::here("Atlas", "code", "14_ClimateMaps.R"))
```

### Author {.author}

## Annual Mean Temperature

```{r temp}
#| fig.height: 14
#| fig.width: 14
plot_bio1_map(bioclim_lux, lux_borders)
```
````

Éléments :

- `# Climate` : titre de niveau 1 du chapitre.

\- Bloc `setup` : charge `0_Initialisation.R`, qui charge les librairies et les scripts communs essentiels (config, bordures, données, cartes principales, graphiques d'activité). Les scripts spécifiques à un chapitre (ici `14_ClimateMaps.R`) ne sont pas chargés dans `0_Initialisation.R` mais directement dans le `.qmd` qui en a besoin. 

\- `## Annual Mean Temperature` : titre de niveau 2

\- Le bloc de code appelle une fonction déjà définie dans `code/` (`plot_bio1_map`) ; le résultat s'affiche directement dans la page.

\- `#| echo: false` masque le code R dans le rendu final. `#| fig.height` / `#| fig.width` fixent les dimensions de la figure.

**Cas sélecteur interactif (climat)** : dans `biophysical/climate.qmd`, le chapitre teste le format de sortie avec `knitr::pandoc_to("html")`. En HTML, il génère un menu déroulant (`<select id="bio-select">`, stylé via `.bio-select`/`.bio-map` dans `style.scss`) qui bascule entre plusieurs cartes BIOCLIM pré-générées (`style="display:none"`).

Principe général : une page `.qmd` n'effectue quasiment aucun calcul directement ; elle appelle des fonctions déjà écrites dans `code/`.

## Chapitres narratifs


| Chapitre | Contenu attendu |
|------------------------------------|------------------------------------|
| `introduction.qmd` | Présentation générale de l'atlas |
| `history.qmd` | Texte à rédiger + carte des observations antérieures à l'arrivée des sciences citoyennes (générée dans `4_MainMap.R`) |
| `ecology.qmd` | Attend deux images statiques dans `images/` : `phylogenetic_circle.png` et `phylogenetic_graph.png` + graphiques circulaires par tribu/sous-famille générés par `10_PieChart.R` |
| `methodology.qmd` | Description des sources de données, à personnaliser par projet |
| `glossary.qmd` | Glossaire à rédiger |
| `spatial.qmd` | Cartes d'effort d'échantillonnage (`17_Effort.R`) |
| `conservation.qmd` | à rédiger |
| `biophysical/geo_topography.qmd` | Géologie + légende, sols + légende ; chapitre Altitude |
| `biophysical/climate.qmd` | Température moyenne annuelle, précipitations, sélecteur BIOCLIM |
| `biophysical/land_use_cover.qmd` | Carte d'occupation du sol prévue (`15_LandOverMap.R`) |

## Scripts (`code/`)

Ordre de chargement des scripts essentiels, défini dans `0_Initialisation.R` :

``` r
source("1_config.R")
source("utils.R")
source("2_LoadBorders.R")
source("3_LoadData.R")
source("4_MainMap.R")
source("5_SpeciesMaps.R")
source("6_PresenceMois.R")
```

| Script | Rôle |
|------------------------------------|------------------------------------|
| `0_Initialisation.R` | Charge l'ensemble des librairies R (lecture de fichiers, SIG, cartes interactives, plotting, manipulation de données), puis les scripts essentiels listés ci-dessus. |
| `1_config.R` | Définit `DATAPATH`, propre à chaque poste de travail. |
| `utils.R` | Fonctions transverses réutilisées ailleurs dans le projet. Contient les fonctions de widget checkbox (`blockCheckboxSP`, `inlineCheckboxSP`) et `filter_checkboxSP` (filtre à cases à cocher personnalisé basé sur crosstalk, utilisée par la carte principale). |
| `2_LoadBorders.R` | Construit la grille de 5 km sur le territoire (`rtp`), les frontières nationales (`lux_borders`) et régionales (`GRborders`, recadrées en `GR2169_c`), ainsi que les étiquettes des pays voisins (`country_labels`). |
| `3_LoadData.R` | Charge et nettoie les données d'observation brutes, construit les tables combinées `DB`, `DB_sf` et `DB_full` utilisées par le reste du pipeline. **Ce script est spécifique à chaque jeu de données** — voir la section « Apporter vos propres données ». |
| `4_MainMap.R` | Carte interactive principale : fond OSM/Satellite, grille, points d'observation, curseur par année, filtre par source (via `filter_checkboxSP`). Contient aussi deux cartes statiques ggplot annexes (répartition avant l'arrivée des sciences citoyennes, carte des anciennes carrières). |
| `5_SpeciesMaps.R` | Construit `get_species_map()` (carte interactive de répartition par espèce, avec popups détaillés par cellule/point) et la liste des identificateurs ayant fait plus de 30 déterminations. |
| `6_PresenceMois.R` | Fonctions de graphique de période d'activité par mois (`plot_heatmap`), utilisées dans les fiches espèces. |

### Scripts appelés depuis un chapitre spécifique

Ces scripts ne sont pas chargés dans `0_Initialisation.R` mais directement `source()`-és dans le `.qmd` qui en a besoin :

| Script | Rôle |
|------------------------------------|------------------------------------|
| `7_GenerateSpeciesPages.R` | Génère automatiquement un fichier `.qmd` par espèce dans `species_account/` à partir de `_template.qmd` et de `DB_taxo`, puis met à jour `_quarto.yml`. Vérifie aussi le statut taxonomique de chaque nom (accepté, synonyme, non trouvé) via le Catalogue of Life, et écarte les noms de genre seul ou les doublons. |
| `8_InjectContent.R` | Insère le texte de `species_content/*.txt` (Author, Description, Habitat, Immature, Mature, Distribution, Notes) dans la section correspondante de chaque fiche `.qmd`, sans modifier le reste de la page. Une sauvegarde `.bak` de la fiche est créée avant chaque écriture. |
| `9_LastSpecies.R` | Interroge l'API iNaturalist pour récupérer la dernière observation de l'espèce au Luxembourg (photo incluse), utilisée dans `acknowledgement.qmd`. |
| `10_PieChart.R` | Création de pie charts pour la répartition de la tribu et de la sous-famille (`plot_tribe_pie`, `plot_subfamily_pie`), destinées à `ecology.qmd`. |
| `11_Geology.R` | Fonctions de carte géologique et de sa légende (`plot_carte_geologique`, `plot_legende_geologique`), utilisées dans `geo_topography.qmd`. |
| `12_SoilsMap.R` | Fonctions de carte des sols et de sa légende (`plot_carte_sols`, `plot_legende_sols`). |
| `13_DSM.R` | Carte d'altitude (modèle numérique de surface). |
| `14_ClimateMaps.R` | Cartes climatiques : température annuelle moyenne, précipitations, et un sélecteur de variables BIOCLIM en HTML. |
| `15_LandOverMap.R` | Carte d'occupation du sol, prévue pour `land_use_cover.qmd`. |
| `16_CommunesMap.R` | Cartes de richesse spécifique (`carte_especes_commune`) et de nombre d'observations (`carte_obs_commune`) agrégées par commune, à partir d'un fichier de limites communales. |
| `17_Effort.R` | Cartes d'effort d'échantillonnage par cellule de la grille : nombre de sorties terrain (`carte_effort_cell`), ratio observations/sortie (`carte_ratio_cell`), ratio espèces/sortie (`carte_ratio_especes_cell`). |
| `18_redList.R` | Construction d'une base de données propre pour l'extraction des catégorie IUCN (à partir d'un Excel à fournir)|
| `Taxonomie.R` | Construit `DB_taxo` (nom, sous-famille, tribu, genre par espèce) via le Catalogue of Life. |
| `PhylogeneticGraph.R` | Arbre interactif (`collapsibleTree`) de la hiérarchie Subfamily/Tribe/Genus/espèce. |
| `LandCoverBarplot.R` | Exploration de graphiques d'habitat par espèce à partir de l'occupation du sol dans un rayon de 500 m autour des observations. |
| `sample_triangle.R` | Graphique ternaire (`ggtern`) reliant richesse spécifique et composition d'habitat par cellule. |
| `pre-render.R` | Met à jour les titres dynamiques du livre et la liste des fiches espèces dans `_quarto.yml`, à chaque rendu. |

## Ce qui se passe automatiquement au rendu

Le script `pre-render.R` s'exécute automatiquement avant chaque rendu (voir Guide pour la commande de rendu). Il enchaîne, dans l'ordre :

1.  `Taxonomie.R` : construit `DB_taxo` (sous-famille, tribu, genre par espèce) à partir des données d'observation et du Catalogue of Life.
2.  `7_GenerateSpeciesPages.R` : génère une fiche `.qmd` pour chaque nouvelle espèce à partir de `_template.qmd` et `DB_taxo`, met à jour `_quarto.yml`, puis appelle `8_InjectContent.R` pour insérer le texte rédigé dans `species_content/`.
3.  Mise à jour dynamique des titres du livre et des chapitres (`ecology.qmd`, `history.qmd`, `conservation.qmd`) en fonction du taxon.

Le rendu produit un dossier `Atlas/_book/` avec la version HTML navigable du livre (une page par chapitre) ainsi que les librairies JS/CSS.

Le dossier `Atlas/_freeze/` contient le cache de Quarto : les résultats déjà calculés pour un chapitre sont réutilisés tant que son code n'a pas changé, ce qui évite de recalculer à chaque rendu. Si un rendu ne reflète pas un changement fait dans un script, supprimer le sous-dossier concerné dans `_freeze/`.

## `1_config.R`

Ce fichier définit `DATAPATH` (chemin vers le dossier de données) et le taxon de l'atlas. Il est propre à chaque poste de travail.

## Apporter vos propres données

Les données doivent être chargées dans **`3_LoadData.R`** vers une table finale unique, `DB`, avec exactement ces colonnes :

| Colonne | Type | Contenu attendu |
|------------------------|------------------------|------------------------|
| `Lat` | numeric | Latitude (WGS84 / EPSG:4326) |
| `Long` | numeric | Longitude (WGS84 / EPSG:4326) |
| `ID` | character | Nom de l'espèce (nom scientifique, tel qu'utilisé pour générer les fiches) |
| `Source` | character | Catégorie de la méthode/source de collecte (ex. piégeage, sciences citoyennes...) |
| `Year` | numeric | Année d'observation |
| `Date` | Date | Date complète de l'observation |
| `Cell` | numeric | Identifiant de cellule de la grille (calculé par jointure spatiale avec `rtp`) |

Une version étendue, `DB_full`, ajoute les colonnes utilisées par les fiches espèces et les popups des cartes interactives :

| Colonne supplémentaire | Contenu attendu |
|------------------------------------|------------------------------------|
| `Origin` | Plateforme/origine précise de l'observation (ex. nom de la plateforme de sciences citoyennes, ou source interne) |
| `Observateur` | Nom de l'observateur/collecteur |
| `Identifieur` | Nom de la personne ayant identifié le spécimen |
| `URL` | Lien direct vers l'observation en ligne si elle vient d'une plateforme externe, sinon `NA` |

Étapes à reproduire dans votre propre `3_LoadData.R` : 1. Lire chacune de vos sources de données brutes et harmoniser les noms de colonnes. 
2. Convertir chaque source en objet spatial (`st_as_sf(..., coords = c("Long", "Lat"), crs = 4326)`). 
3. Calculer la colonne `Cell` par une jointure spatiale avec la grille `rtp` (déjà construite par `2_LoadBorders.R`) : `st_join(votre_sf, st_transform(st_as_sf(rtp), st_crs(votre_sf)))$layer`. 
4. Empiler (`rbind`) toutes les sources harmonisées en une seule table `DB` (et `DB_full` pour les popups détaillés). 
5. Nettoyer : lignes avec coordonnées et année valides, gérer les noms d'espèce.

Une fois `DB`/`DB_full` construits selon cette structure, tout le reste (`4_MainMap.R`, `5_SpeciesMaps.R`, `6_PresenceMois.R`, `Taxonomie.R`, `7_GenerateSpeciesPages.R`...) fonctionne sans modification.

## Fiches espèces

1.  **Modèle** : `species_account/_template.qmd`, contenant des placeholders `<<species>>`, `<<authorship>>`, `<<name>>`, `<<subfamily>>`, `<<tribe>>`, `<<en>>`, `<<lb>>`, `<<fr>>`, `<<de>>`, `<<image_file>>`, `<<image_credit>>`.
2.  **Remplissage taxonomique** : `7_GenerateSpeciesPages.R` remplit ces placeholders à partir de `DB_taxo` (nom, sous-famille, tribu), du Catalogue of Life / iNaturalist / Wikidata (noms vernaculaires EN/LB/FR/DE, en cascade) et du dossier `images/` (fichier + crédit photo, voir « Images »), pour chaque espèce sans fichier existant.
3.  **Injection du texte** : `8_InjectContent.R` insère le contenu de `species_content/nom_espece.txt` dans les sections correspondantes (`### Author`, `## Description`, `## Habitat`, `### Immature`, `### Mature`, `## Distribution`, `## Notes`).


### Contenu d'une fiche générée

Dans l'ordre d'apparition :

1. **Menu déroulant des synonymes** : bouton « Synonyms ▾ » (classes `.dropdown`/`.dropdown-btn`/`.dropdown-content` dans `style.scss`) qui liste les synonymes du nom d'espèce récupérés via `col_synonyms(col_match(...))` (Catalogue of Life).
2. **Taxonomie et noms vernaculaires** : sous-famille, tribu, puis noms communs en anglais/luxembourgeois/français/allemand (`.species-taxonomy`). Ce bloc partage une colonne avec le menu des synonymes, à côté du bloc Statuts de conservation.
3. **Statuts de conservation** (`## Conservation status`) : deux blocs côte à côte — Europe et Union européenne (27), calculés dynamiquement via `get_iucn_status()` (`18_redList.R`) — voir « Statuts de conservation (IUCN) ».
4. **Photo de l'espèce** (`.species-photo`) et crédit (`<<image_credit>>`).
5. **Période d'activité** : heatmap mensuelle (`plot_heatmap`).
6. **Description / Habitat (Immature, Mature) / Distribution** : texte injecté depuis `species_content/`.
7. **Carte de répartition interactive** (`get_species_map`).
8. **Compteur d'observations** (`.obs-count`) et **avertissement conditionnel** (`.obs-warning`, si `n_obs < seuil_obs`, actuellement fixé à 30) — placés juste avant les Notes, donc après la carte de répartition.
9. **Notes** : texte injecté depuis `species_content/`.
10. **Auteur** de la fiche (`### Author {.author-species}`), texte injecté par `8_InjectContent.R`. 

### Comprendre la carte et le graphique d'une fiche espèce

La carte interactive affiche trois couches superposées, activables ou désactivables via le menu en haut à droite de la carte :

\- **Grid** : la grille de cellules de 5 km utilisée pour découper le territoire luxembourgeois. Toujours visible en fond, avec un contour rouge fin.

\- **Cells** : les cellules de la grille où l'espèce a été observée au moins une fois, colorées en rouge. Un clic sur une cellule ouvre une fenêtre indiquant le nombre total d'observations dans cette cellule et le détail par méthode/source de collecte.

\- **Points** : les observations individuelles, affichées comme des points rouges à partir d'un certain zoom.

Un clic sur un point affiche le détail de cette observation précise : la méthode de collecte (Source), la date, l'observateur, l'identificateur, et un lien direct vers la fiche iNaturalist ou Observation.org si l'observation vient de l'une de ces plateformes.

Le passage d'une couche à l'autre est automatique selon le niveau de zoom : à faible zoom, seules les cellules colorées (Cells) sont visibles ; à partir du niveau 12, les cellules disparaissent et les points individuels apparaissent.

Le graphique d'activité (heatmap) est une bande horizontale divisée en 48 segments (4 par mois, un par quart de mois : jours 1-7, 8-14, 15-21, et 22-fin de mois). Chaque segment est coloré selon le nombre d'observations enregistrées durant cette période de l'année, toutes années confondues : blanc pour aucune observation, vert de plus en plus foncé quand le nombre d'observations augmente. Ce graphique permet de voir en un coup d'œil la période de l'année où l'espèce est le plus souvent observée.


## Statuts de conservation (IUCN)

Chaque fiche espèce affiche trois statuts de conservation, sous forme de pictogramme : **Europe**, **Union européenne (27)**, et **Luxembourg** .

Le mécanisme, dans `_template.qmd` :

``` r
status <- get_iucn_status(params$species)
```

`status$europe` et `status$eu27` contiennent chacun un code IUCN. Ce code est utilisé directement comme nom de fichier image : `/images/{status$europe}.png` et `/images/{status$eu27}.png`.

### Fichier source requis : `data/EuropeanRedList.xlsx`

`18_redList.R` lit un fichier Excel  : chaque projet doit le créer et le placer dans son dossier `data/`, sous le nom exact `EuropeanRedList.xlsx`. Le script lit la première feuille du classeur (`sheet = 1`) et attend les colonnes suivantes :

| Colonne attendue | Rôle |
|------------------------------------|------------------------------------|
| `Genus` | Genre de l'espèce |
| `Species` | Épithète spécifique (sans le genre) |
| `European Category` | Catégorie IUCN au niveau européen (ex. LC, NT, VU, EN, CR, EW, EX) |
| `European Criteria` | Critère(s) IUCN associé(s), niveau européen |
| `European Endemic` | Endémisme, niveau européen |
| `EU27 Category` | Catégorie IUCN au niveau Union européenne (27) |
| `EU27 Criteria` | Critère(s) IUCN associé(s), niveau UE27 |
| `EU27 Endemic` | Endémisme, niveau UE27 |

## Images

Toutes les images du projet sont stockées dans le dossier `images/`. Conventions de nommage utilisées par les scripts :

\- **Image de couverture** : le fichier doit impérativement se nommer `cover.png`. Il est appelé dans `index.qmd`.

\- **Images d'espèces** : convention à **4 parties séparées par des points** : `<species_key>.<Photographe>.<Licence>.<extension>`, ex. `temnostoma_meridionale.Sam_Schaack.CC-BY-NC.png`. Cette convention est lue par `build_image_table()` dans `7_GenerateSpeciesPages.R` :
    - `species_key` : slug du nom scientifique (minuscules, accents/caractères spéciaux retirés, espaces remplacés par `_`) — identique au `<<name>>` utilisé pour le nom du fichier `.qmd` de l'espèce.
    - `Photographe` : underscores à la place des espaces dans le nom de fichier (ex. `Sam_Schaack`) ; ils sont convertis en espaces à l'affichage (`Sam Schaack`).
    - `Licence` : code de licence affiché tel quel (ex. `CC-BY-NC`).
    - Un fichier dont le nom contient moins de 3 points (donc ne respecte pas ce format à 4 parties) est ignoré par `build_image_table()`.
    - Si plusieurs images correspondent au même `species_key`, seule la première par ordre alphabétique de nom de fichier est retenue, et un avertissement est émis.
    - Le crédit affiché sur la fiche (`<<image_credit>>`) est construit comme `Licence Photographe`, ex. « CC-BY-NC Sam Schaack ».
    - **Pour changer cette convention** (par ex. l'ordre des parties, ou le séparateur), modifier `build_image_table()` dans `7_GenerateSpeciesPages.R`

\- **Images de statut de conservation** : chaque fiche affiche trois pictogrammes IUCN (CR, EN, EW, EX, LC, NT, VU).

\- **Dernière observation (Acknowledgements)** : `last_syrphidae.jpg`, récupérée automatiquement par `9_LastSpecies.R`.

\- **Images de phylogénie (chapitre Ecology)** : `phylogenetic_circle.png` et `phylogenetic_graph.png`, affichées de façon statique dans `ecology.qmd`.

## Style (`style.scss`)

Variables de couleur en tête de fichier :

``` scss
$primary: #5f7132 !default;
$body-color: #263126 !default;
$body-bg: #ffffff !default;
$headings-color: #16200f !default;
$link-color: #52662d !default;
```

**Modifier la couleur principale** :

``` scss
$primary: #2c5f8a !default;
```

**Modifier la taille de la photo d'espèce** (règle `.species-photo`) :

``` scss
.species-photo {
  max-width: 70%;   // 50% pour réduire la taille de la photo sur chaque fiche
}
```

**Composants** : 
- `.dropdown` / `.dropdown-btn` / `.dropdown-content` / `.scroller` : menu déroulant des synonymes sur les fiches espèces. 
- `.obs-count` / `.obs-warning` : compteur de records et encart d'avertissement en cas de faible nombre d'observations. 
- `.species-taxonomy` : mise en forme du bloc taxonomie + noms vernaculaires. 
- `.lightbox` / `#img-modal` : agrandissement au clic d'une image (utilisé dans `spatial.qmd`). 
- `.bio-select` / `.bio-map` : sélecteur de variable climatique (chapitre Climate)

**Modifier la police du titre d'une fiche espèce** : définie directement dans `_template.qmd` (dupliquée dans chaque fiche déjà générée), pas dans `style.scss`. 
Un changement de police doit être appliqué dans `_template.qmd` avant génération de nouvelles fiches ; les fiches déjà générées nécessitent une modification manuelle.

## Bibliographie et citations

Deux fichiers de bibliographie coexistent :

\- `references.bib` : format BibTeX classique, référencé par `bibliography:` dans `_quarto.yml` et utilisé par `references.qmd` (bloc `::: {#refs} :::`) pour générer la liste des références citées dans le texte
\- `references.yaml`

## Data (`data/`)

Le dossier `data/` regroupe les données géographiques utilisées par les chapitres et scripts :

\- Frontières nationales/régionales (via `geobounds`, `GRborders.gpkg`)
\- Géologie, sols (chapitre Biophysical)
\- Occupation du sol : raster (`LandCover_*.tif`) et version vecteur (`LandCover_*.gdb`), plus des couches CLMS haute résolution dédiées (`Grassland/`, `TreeCover/`) utilisées dans les scripts exploratoires d'habitat
\- Limites communales (`communes4326.geojson`), utilisées par `16_CommunesMap.R`.
