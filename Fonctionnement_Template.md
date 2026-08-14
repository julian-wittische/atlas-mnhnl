# Fonctionnement du template

> Ce document décrit le fonctionnement technique du template et les fonctionnalités qu'il permet de produire. Pour la procédure d'installation, de configuration, de préparation des données et de rendu du livre, voir le *Guide d'utilisation du template*.

## Vue d'ensemble

Le projet est un template en Quarto et R permettant de construire un atlas de biodiversité. Le livre est composé de chapitres `.qmd`, de scripts R qui préparent les données et fournissent les fonctions utilisées par ces chapitres, de fichiers de données géographiques, d'images et de contenus rédactionnels.

Le sommaire du livre est défini dans `_quarto.yml`, dans le sous-dossier `Atlas/`. Les chapitres `.qmd` contiennent le texte du livre ainsi que les appels aux fonctions qui génèrent automatiquement les cartes, graphiques et autres éléments interactifs.

Le dossier `code/` contient les scripts R communs : configuration, chargement des données, fonctions de cartographie, graphiques, taxonomie et génération des fiches espèces.

Le fichier `style.scss` définit l'apparence visuelle du livre : couleurs, tailles, espacements et mise en forme des différents composants.

La racine du projet R est `atlas-mnhnl`, identifiée par le fichier `atlas-mnhnl.Rproj`.

## Arborescence

``` text
Atlas/
├── _quarto.yml          → structure et configuration du livre
├── style.scss           → couleurs / mise en page du site
├── index.qmd            → page de couverture
├── acknowledgement.qmd  → page de remerciements
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
│   ├── _template.qmd    → modèle des fiches espèces
│   └── (une fiche .qmd générée par espèce)
├── species_content/     → contenu rédactionnel des espèces
├── images/              → images du projet
├── data/                → données géographiques et fichiers sources
└── code/                → scripts R
```

## `_quarto.yml`

`_quarto.yml` définit la structure du livre et l'ordre des chapitres.

``` yaml
project:
  type: book

book:
  title: xx
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
        - species_account/xx.qmd
        - species_account/xx.qmd
    - spatial.qmd
    - conservation.qmd
    - references.qmd

format:
  html:
    theme:
      light: [zephyr, style.scss]
```

La liste `chapters:` détermine l'ordre des pages du livre. Les blocs `part:` créent les grandes sections du livre. Le thème `zephyr` fournit le thème de base, auquel `style.scss` ajoute les personnalisations propres au projet.

Les fiches espèces constituent un cas particulier : leur liste est générée automatiquement par `7_GenerateSpeciesPages.R` et mise à jour par `pre-render.R` lors du rendu.

## Contenu d'un fichier `.qmd`

Un chapitre `.qmd` combine le contenu rédactionnel du livre et les appels aux fonctions R nécessaires à la production des éléments graphiques.

Exemple simplifié avec `biophysical/climate.qmd` :

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

Le bloc `setup` charge `0_Initialisation.R`, qui met en place l'environnement commun et les scripts essentiels. Les scripts spécifiques à un chapitre sont chargés directement dans le `.qmd` lorsqu'ils sont nécessaires.

Les fonctions de cartographie et de graphique sont ensuite appelées depuis le chapitre. Le résultat de ces fonctions est intégré directement dans le rendu Quarto.

`#| echo: false` permet de masquer le code R dans le livre final, tandis que `fig.height` et `fig.width` contrôlent les dimensions des figures.

Dans `biophysical/climate.qmd`, un sélecteur interactif permet également de choisir une variable BIOCLIM. Les cartes sont pré-générées puis affichées ou masquées selon le choix effectué dans le menu. Le sélecteur est défini dans le `.qmd` et sa mise en forme est assurée par les classes `.bio-select` et `.bio-map` de `style.scss`.

De manière générale, les chapitres `.qmd` contiennent peu de calculs directement : ils utilisent les fonctions définies dans les scripts du dossier `code/`.

## Scripts (`code/`)

### Initialisation et scripts essentiels

`0_Initialisation.R` charge les librairies R nécessaires au projet puis les scripts communs essentiels dans l'ordre suivant :

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
| `0_Initialisation.R` | Charge les librairies R et les scripts essentiels utilisés par le reste du projet. |
| `1_config.R` | Définit les paramètres propres au projet et au poste de travail, notamment `DATAPATH` et le taxon de l'atlas. |
| `utils.R` | Contient des fonctions transversales réutilisées dans plusieurs parties du projet, notamment les fonctions liées aux widgets de filtrage (`blockCheckboxSP`, `inlineCheckboxSP`, `filter_checkboxSP`). |
| `2_LoadBorders.R` | Construit la grille de 5 km (`rtp`), les frontières nationales (`lux_borders`), les frontières régionales (`GRborders`, `GR2169_c`) et les étiquettes des pays voisins (`country_labels`). |
| `3_LoadData.R` | Charge et harmonise les données d'observation et construit les tables `DB`, `DB_sf` et `DB_full` utilisées par le reste du pipeline. |
| `4_MainMap.R` | Construit la carte interactive principale avec fond OSM/Satellite, grille, observations, curseur par année et filtre par source. Contient également les cartes statiques de répartition historique et des anciennes carrières. |
| `5_SpeciesMaps.R` | Construit `get_species_map()`, utilisée pour les cartes interactives des fiches espèces, ainsi que la liste des identificateurs ayant réalisé plus de 30 déterminations. |
| `6_PresenceMois.R` | Contient les fonctions utilisées pour représenter la période d'activité des espèces, notamment `plot_heatmap`. |

### Scripts utilisés par des chapitres spécifiques

Ces scripts ne sont pas chargés par `0_Initialisation.R`. Ils sont appelés directement par les chapitres ou par le pipeline de génération lorsque leur fonctionnalité est nécessaire.

| Script | Rôle |
|------------------------------------|------------------------------------|
| `7_GenerateSpeciesPages.R` | Génère automatiquement les fiches `.qmd` à partir de `_template.qmd` et de `DB_taxo`, puis met à jour `_quarto.yml`. Le script vérifie également le statut taxonomique des noms via le Catalogue of Life et écarte les noms de genre seul ou les doublons. |
| `8_InjectContent.R` | Insère le contenu de `species_content/*.txt` dans les sections correspondantes des fiches générées, sans modifier le reste de la page. Une sauvegarde `.bak` est créée avant l'écriture. |
| `9_LastSpecies.R` | Interroge l'API iNaturalist afin de récupérer la dernière observation de l'espèce au Luxembourg, avec sa photo, utilisée dans `acknowledgement.qmd`. |
| `10_PieChart.R` | Génère les graphiques circulaires de répartition de la tribu et de la sous-famille (`plot_tribe_pie`, `plot_subfamily_pie`) utilisés dans `ecology.qmd`. |
| `11_Geology.R` | Contient les fonctions de carte géologique et de sa légende (`plot_carte_geologique`, `plot_legende_geologique`). |
| `12_SoilsMap.R` | Contient les fonctions de carte des sols et de sa légende (`plot_carte_sols`, `plot_legende_sols`). |
| `13_DSM.R` | Produit la carte d'altitude à partir du modèle numérique de surface. |
| `14_ClimateMaps.R` | Contient les fonctions de cartes climatiques : température annuelle moyenne, précipitations et variables BIOCLIM. |
| `15_LandOverMap.R` | Contient la fonction de production de la carte d'occupation du sol. |
| `16_CommunesMap.R` | Produit les cartes de richesse spécifique (`carte_especes_commune`) et de nombre d'observations (`carte_obs_commune`) agrégées par commune. |
| `17_Effort.R` | Produit les cartes d'effort d'échantillonnage : nombre de sorties terrain (`carte_effort_cell`), ratio observations/sortie (`carte_ratio_cell`) et ratio espèces/sortie (`carte_ratio_especes_cell`). |
| `18_RedList.R` | Prépare les données nécessaires à l'extraction des catégories IUCN à partir du fichier de données fourni. |
| `19_Barplot.R` | Produit un graphique en barres empilées (plot_habitat_espece) représentant la proportion d'habitat dominant (Grassland/Forest/Other) associée aux observations d'une espèce donnée, calculée soit par cellule de grille soit par voisinage autour de chaque point. |
| `Taxonomie.R` | Construit `DB_taxo`, contenant la hiérarchie taxonomique des espèces à partir du Catalogue of Life. |
| `PhylogeneticGraph.R` | Produit l'arbre interactif de la hiérarchie Subfamily / Tribe / Genus / espèce avec `collapsibleTree`. |
| `LandCoverBarplot.R` | Produit des graphiques d'habitat par espèce à partir de l'occupation du sol dans un rayon de 500 m autour des observations. |
| `sample_triangle.R` | Produit des graphiques ternaires (triangle) reliant composition d'habitat et richesse spécifique, par cellule de grille ou par observation (buffer 500 m, un graphique par espèce). |
| `pre-render.R` | Exécute les opérations nécessaires avant le rendu : mise à jour de la taxonomie, génération des fiches espèces et mise à jour des titres dynamiques du livre. |

## Données d'observation

Les données d'observation sont préparées dans `3_LoadData.R` afin de produire des tables standardisées utilisées par les différentes fonctionnalités du template.

La table principale `DB` contient notamment :

| Colonne  | Contenu                             |
|----------|-------------------------------------|
| `Lat`    | Latitude en WGS84 / EPSG:4326       |
| `Long`   | Longitude en WGS84 / EPSG:4326      |
| `ID`     | Nom scientifique de l'espèce        |
| `Source` | Source ou méthode de collecte       |
| `Year`   | Année d'observation                 |
| `Date`   | Date complète de l'observation      |
| `Cell`   | Identifiant de cellule de la grille |

`DB_sf` correspond à la version spatiale utilisée pour les traitements géographiques.

`DB_full` contient en plus les informations utilisées dans les fenêtres d'information des cartes interactives et dans certaines fonctionnalités des fiches espèces :

| Colonne       | Contenu                                  |
|---------------|------------------------------------------|
| `Origin`      | Origine précise de l'observation         |
| `Observateur` | Observateur ou collecteur                |
| `Identifieur` | Personne ayant identifié l'observation   |
| `URL`         | Lien vers l'observation lorsqu'il existe |

Une fois ces tables construites, les scripts de cartographie, de taxonomie et de génération des fiches peuvent utiliser une structure de données commune.

## Taxonomie

`Taxonomie.R` utilise les noms d'espèces présents dans les données d'observation pour construire `DB_taxo`.

Cette table rassemble les informations taxonomiques utilisées notamment pour les fiches espèces et l'arbre phylogénétique :

- sous-famille ;
- tribu ;
- genre ;
- espèce.

Le script utilise le Catalogue of Life pour vérifier les noms et récupérer la hiérarchie taxonomique.

`PhylogeneticGraph.R` utilise ensuite ces informations pour construire un arbre interactif avec les niveaux :

**Subfamily → Tribe → Genus → Species**

## Fiches espèces

Les fiches espèces sont construites automatiquement à partir de plusieurs éléments :

1.  `_template.qmd` définit la structure commune de toutes les fiches.
2.  `DB_taxo` fournit les informations taxonomiques.
3.  `7_GenerateSpeciesPages.R` remplit les éléments variables de la fiche et génère le fichier `.qmd` de l'espèce.
4.  `8_InjectContent.R` insère le contenu rédactionnel provenant de `species_content/`.
5.  L'image correspondant à l'espèce est associée automatiquement à partir de son nom de fichier.
6.  `_quarto.yml` est mis à jour pour intégrer les fiches générées au livre.

Les fiches présentes dans `species_account/` sont donc des fichiers générés à partir du modèle.

### Structure d'une fiche

Le modèle utilise notamment les placeholders suivants :

``` text
<<species>>
<<authorship>>
<<name>>
<<subfamily>>
<<tribe>>
<<en>>
<<lb>>
<<fr>>
<<de>>
<<image_file>>
<<image_credit>>
```

Ils sont remplacés lors de la génération de la fiche par les informations disponibles dans les données taxonomiques et les sources externes.

Les informations taxonomiques et les noms vernaculaires sont récupérés automatiquement lorsque les sources disponibles les fournissent.

### Contenu d'une fiche générée

Dans l'ordre d'apparition, une fiche contient :

1.  **Menu déroulant des synonymes** : les synonymes du nom d'espèce sont récupérés via le Catalogue of Life.
2.  **Taxonomie et noms vernaculaires** : sous-famille, tribu, puis noms communs en anglais, luxembourgeois, français et allemand.
3.  **Statuts de conservation** : Europe et Union européenne (27), avec les informations fournies par le système IUCN.
4.  **Photo de l'espèce** et crédit associé.
5.  **Période d'activité** sous forme de heatmap mensuelle.
6.  **Description, habitat, distribution** et autres contenus rédactionnels.
7.  **Carte de répartition interactive**.
8.  **Compteur d'observations** et avertissement conditionnel lorsque le nombre d'observations est inférieur au seuil défini.
9. **Barplot landcover** répartition de l'habitat dominant (Grassland/Forest/Other) autour des observations de l'espèce.
10.  **Notes**.
11. **Auteur** de la fiche.

## Carte de répartition des espèces

La fonction `get_species_map()` produit la carte interactive présente sur chaque fiche espèce.

La carte affiche trois couches principales :

- **Grid** : grille de cellules de 5 km utilisée pour découper le territoire luxembourgeois ;
- **Cells** : cellules dans lesquelles l'espèce a été observée au moins une fois ;
- **Points** : observations individuelles.

Les couches peuvent être activées ou désactivées depuis le menu de la carte.

Un clic sur une cellule affiche le nombre d'observations dans cette cellule ainsi que leur répartition par méthode ou source de collecte.

Un clic sur un point affiche les informations de l'observation : source, date, observateur, identificateur et, lorsqu'il existe, lien vers la fiche de l'observation en ligne.

Le comportement de la carte dépend également du niveau de zoom. À faible zoom, les cellules sont utilisées pour représenter la répartition. À partir du niveau de zoom 12, les cellules disparaissent et les observations individuelles apparaissent.

## Graphique de période d'activité

`plot_heatmap()` produit la heatmap utilisée dans les fiches espèces pour représenter la période d'activité de l'espèce.

La bande horizontale est divisée en **48 segments**, correspondant à quatre périodes par mois :

- jours 1 à 7 ;
- jours 8 à 14 ;
- jours 15 à 21 ;
- jours 22 à la fin du mois.

Les observations sont regroupées dans ces périodes, toutes années confondues.

La couleur de chaque segment dépend du nombre d'observations enregistrées pendant la période :

- blanc : aucune observation ;
- vert de plus en plus foncé : nombre d'observations croissant.

Le graphique permet ainsi de visualiser rapidement les périodes de l'année pendant lesquelles l'espèce est le plus souvent observée.

## Statuts de conservation (IUCN)

Les fiches espèces affichent les statuts de conservation disponibles pour :

- l'Europe ;
- l'Union européenne (27) ;
- le Luxembourg.

Dans `_template.qmd`, le statut est récupéré avec :

``` r
status <- get_iucn_status(params$species)
```

Les catégories européennes et UE27 sont issues des données préparées par `18_RedList.R`.

### Fichier source

`18_RedList.R` utilise le fichier :

``` text
data/EuropeanRedList.xlsx
```

Le fichier doit contenir notamment :

| Colonne             | Rôle                               |
|---------------------|------------------------------------|
| `Genus`             | Genre de l'espèce                  |
| `Species`           | Épithète spécifique                |
| `European Category` | Catégorie IUCN au niveau européen  |
| `European Criteria` | Critère(s) IUCN au niveau européen |
| `European Endemic`  | Endémisme au niveau européen       |
| `EU27 Category`     | Catégorie IUCN au niveau UE27      |
| `EU27 Criteria`     | Critère(s) IUCN au niveau UE27     |
| `EU27 Endemic`      | Endémisme au niveau UE27           |

Les catégories sont ensuite utilisées pour associer les pictogrammes correspondants dans les fiches espèces.

## Images

Les images du projet sont stockées dans `images/`.

### Image de couverture

La couverture utilise :

``` text
cover.png
```

### Images des espèces

Les images d'espèces suivent la convention :

``` text
<species_key>.<Photographe>.<Licence>.<extension>
```

Par exemple :

``` text
temnostoma_meridionale.Sam_Schaack.CC-BY-NC.png
```

`build_image_table()` dans `7_GenerateSpeciesPages.R` utilise cette convention pour associer une image à une espèce et construire automatiquement le crédit photographique.

Le `species_key` correspond au nom de l'espèce transformé en identifiant de fichier : minuscules, caractères spéciaux retirés et espaces remplacés par `_`.

Le nom du photographe utilise des underscores dans le nom de fichier, qui sont ensuite remplacés par des espaces lors de l'affichage.

La licence est utilisée telle quelle dans le crédit.

Si plusieurs images correspondent au même `species_key`, la première par ordre alphabétique est retenue + avertissement.

### Autres images

Les pictogrammes de statut de conservation sont utilisés par les fiches espèces.

`9_LastSpecies.R` récupère automatiquement `last_syrphidae.jpg` pour la dernière observation utilisée dans `acknowledgement.qmd`.

Les images `phylogenetic_circle.png` et `phylogenetic_graph.png` sont utilisées dans `ecology.qmd` et sont à fournir.

## Chapitres biophysiques

### Géologie

`11_Geology.R` fournit les fonctions :

``` r
plot_carte_geologique()
plot_legende_geologique()
```

Elles sont utilisées dans `geo_topography.qmd` pour afficher la carte géologique et sa légende.

### Sols

`12_SoilsMap.R` fournit :

``` r
plot_carte_sols()
plot_legende_sols()
```

Ces fonctions produisent la carte des sols et sa légende.

### Altitude

`13_DSM.R` produit la carte d'altitude à partir du modèle numérique de surface.

### Climat

`14_ClimateMaps.R` produit les cartes climatiques utilisées dans `climate.qmd`, notamment :

- température moyenne annuelle ;
- précipitations ;
- variables BIOCLIM.

Le chapitre utilise un sélecteur permettant de choisir la variable climatique à afficher.

### Occupation du sol

`15_LandOverMap.R` produit la carte d'occupation du sol utilisée dans `land_use_cover.qmd`.

## Cartes et analyses spatiales

### Carte communale

`16_CommunesMap.R` permet de représenter à l'échelle des communes :

- la richesse spécifique avec `carte_especes_commune` ;
- le nombre d'observations avec `carte_obs_commune`.

### Effort d'échantillonnage

`17_Effort.R` produit plusieurs indicateurs d'effort par cellule de la grille :

- `carte_effort_cell` : nombre de sorties terrain ;
- `carte_ratio_cell` : ratio observations / sortie ;
- `carte_ratio_especes_cell` : ratio espèces / sortie.

Ces cartes permettent de mettre en relation la répartition des observations avec l'effort d'échantillonnage.

### Habitat

`LandCoverBarplot.R` utilise les données d'occupation du sol autour des observations afin de produire des graphiques décrivant l'habitat associé aux espèces.

Le traitement utilise un rayon de 500 m autour des observations.

### Graphique ternaire

`sample_triangle.R` produit un graphique ternaire permettant de mettre en relation la richesse spécifique et la composition de l'habitat à l'échelle des cellules.

## Fonctionnement automatique lors du rendu

Avant le rendu du livre, `pre-render.R` effectue plusieurs opérations automatiques.

Il met notamment à jour les informations taxonomiques, génère les fiches espèces et actualise les éléments dynamiques du livre.

Le processus comprend notamment :

1.  `Taxonomie.R` construit `DB_taxo` à partir des espèces présentes dans les données.
2.  `7_GenerateSpeciesPages.R` génère les fiches espèces à partir de `_template.qmd` et de `DB_taxo`.
3.  `8_InjectContent.R` insère le contenu rédactionnel correspondant à chaque espèce.
4.  La liste des fiches espèces dans `_quarto.yml` est mise à jour.
5.  Certains titres et contenus dynamiques du livre sont actualisés.
6.  Quarto génère ensuite le livre HTML.

Le résultat est placé dans :

``` text
Atlas/_book/
```

Le fichier `Atlas/_book/index.html` constitue la page d'entrée du livre.

## Cache Quarto : `_freeze/`

Quarto peut conserver les résultats déjà calculés dans :

``` text
Atlas/_freeze/
```

Lorsqu'un chapitre dispose déjà de résultats calculés, ceux-ci peuvent être réutilisés afin d'éviter de recalculer les éléments qui n'ont pas changé.

Si une modification d'un script n'est pas prise en compte lors du rendu, le cache correspondant au chapitre peut être supprimé afin de forcer le recalcul.

## Style (`style.scss`)

`style.scss` complète le thème Quarto utilisé par le livre.

Les principales variables de couleur sont définies au début du fichier :

``` scss
$primary: #5f7132 !default;
$body-color: #263126 !default;
$body-bg: #ffffff !default;
$headings-color: #16200f !default;
$link-color: #52662d !default;
```

Le fichier contient également les règles de mise en forme des différents composants du template.

Parmi les principaux composants :

- `.dropdown`, `.dropdown-btn`, `.dropdown-content`, `.scroller` : menu déroulant des synonymes des fiches espèces ;
- `.obs-count`, `.obs-warning` : compteur d'observations et avertissement en cas de faible nombre d'observations ;
- `.species-taxonomy` : mise en forme du bloc taxonomique et des noms vernaculaires ;
- `.lightbox`, `#img-modal` : agrandissement des images ;
- `.bio-select`, `.bio-map` : sélecteur et affichage des cartes climatiques.

La mise en forme du titre des fiches espèces est définie directement dans `_template.qmd`.

## Bibliographie et citations

Deux fichiers sont utilisés pour la bibliographie :

- `references.bib` : fichier BibTeX référencé par `bibliography:` dans `_quarto.yml` et utilisé pour générer les références ;
- `references.yaml` : fichier complémentaire utilisé selon les besoins du projet.

## Données géographiques (`data/`)

En plus de données d'observation, le dossier `data/` regroupe les données géographiques utilisées par les différents chapitres et scripts.

Les scripts n'utilisent pas de chemin en dur : ils accèdent aux fichiers via la variable `DATAPATH`, définie par chaque utilisateur dans `1_config.R`. Le dossier doit notamment contenir :

- les frontières nationales et régionales ;
- les données géologiques ;
- les données sur les sols ;
- les couches spécifiques utilisées pour les analyses d'habitat ;
- les limites communales.

Les scripts du dossier `code/` utilisent ces données pour construire les différentes cartes et analyses spatiales du livre.