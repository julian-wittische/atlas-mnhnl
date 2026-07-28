---

editor_options: 
  markdown: 
    wrap: sentence
---

# Atlas des Syrphes (Hoverflies) du Luxembourg — Documentation du template

## Vue d'ensemble

Le projet est un livre Quarto (`project: type: book`). Le sommaire du livre est défini dans un unique fichier, `_quarto.yml`. Chaque chapitre est un fichier `.qmd`, contenant à la fois du texte et des blocs de code R qui génèrent automatiquement cartes, graphiques et tableaux. Le dossier `code/` contient l'ensemble des scripts R : préparation des données, fonctions de cartographie, génération des fiches espèces. Le fichier `style.scss` définit l'apparence visuelle du site (couleurs, tailles, espacements, ...).

## Arborescence

```         
Atlas/
├── _quarto.yml          → sommaire du livre
├── style.scss           → couleurs / mise en page du site
├── index.qmd            → page de couverture
├── acknowledgement.qmd       → page de remerciements
├── introduction.qmd
├── history.qmd
├── ecology.qmd
├── methodology.qmd
├── glossary.qmd
├── spatial.qmd
├── conservation.qmd
├── references.qmd 
├── references.bib     → page de stockage des informations des différentes citations
├── biophysical/
│   ├── climate.qmd
│   ├── geo_topography.qmd
│   └── land_use_cover.qmd
├── species_account/
│   ├── _template.qmd          → modèle pour les species account
│   ├── blera_fallax.qmd       → fiche espèce générée (exemple)
│   └── myathropa_florea.qmd   → fiche espèce générée (exemple)
├── species_content/    → fichiers .txt contenant le texte rédigé par espèce
├── images/          → dossier de stockage des différentes images utilisées
└── code/
    ├── 0_Initialisation.R
    ├── 1_config.R
    ├── utils.R
    ├── 2_LoadBorders.R
    ├── 3_LoadData.R
    ├── 4_MainMap.R
    ├── 5_SpeciesMaps.R
    ├── 6_PresenceMois.R
    ├── 7_GenerateSpeciesPages.R
    ├── 8_InjectContent.R
    ├── 9_LastHoverfly.R
    ├── 10_PieChart.R
    ├── Taxonomie.R
    ├── PhylogeneticGraph.R
    ├── Climate_Maps.R / Geology.R / SoilsMap.R / LandOverMap.R / DSM.R
    ├── pre-render.R         → script lancé avant le render du book, pour integrer dynamiquement les noms de chapitre
    └── InsertCitation.R (vide)

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

La liste de `chapters:` détermine l'ordre exact des pages du livre. Les blocs `part:` créent des sous section dans un chapitre. La ligne `theme: light: [zephyr, style.scss]` applique un thème de base puis les personnalisations de `style.scss`.

**Ajout d'un chapitre standard** : création du fichier `.qmd` correspondant, puis ajout de son chemin dans la liste `chapters:` à la position voulue.

**Cas des fiches espèces** : l'ajout de chemins sous `part: Species accounts` est automatisé par `7_GenerateSpeciesPages.R` (voir section Scripts).

## Contenu d'un fichier `.qmd`

Exemple : `biophysical/climate.qmd`.

``` markdown
# Climate
 
\`\`\`{r setup}
#| echo: false
here::i_am("atlas-mnhnl.Rproj")
source(here::here("Atlas", "code", "0_Initialisation.R"))
source(here::here("Atlas", "code", "Climate_Maps.R"))
\`\`\`
 
### Author {.author}
 
## Annual Mean Temperature
 
\`\`\`{r temp}
#| fig.height: 14
#| fig.width: 14
plot_bio1_map(bioclim_lux, lux_borders)
\`\`\`
```

Éléments : - `# Climate` : titre principal du chapitre. 
           - Bloc `setup` : présent dans presque des pages, il charge `0_Initialisation.R` (qui charge lui-même l'ensemble des librairies et scripts utiles). 
Une page peut charger en complément un script spécifique à son sujet (ici `Climate_Maps.R`). - `## Annual Mean Temperature` : Titre de niveau 2 (h2). - Bloc de code suivant : appelle une fonction déjà définie dans `code/` (`plot_bio1_map`) ; le résultat s'affiche directement dans la page. - `#| echo: false` : masque le code R dans le rendu final, seul le résultat est affiché. `#| fig.height` / `#| fig.width` : dimensions de la figure générée. Principe général : une page `.qmd` n'effectue quasiment aucun calcul directement ; elle appelle des fonctions déjà écrites dans `code/`.

## Scripts (`code/`)

Ordre de chargement défini dans `0_Initialisation.R` :

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
| `0_Initialisation.R` | Charge l'ensemble des librairies R, puis les scripts listés. |
| `1_config.R` | Définit `DATAPATH`, le chemin vers le dossier de données. |
| `utils.R` | Fonctions réutilisées ailleurs dans le projet, par exemple `filter_checkboxSP` (cases à cocher personnalisées des cartes interactives) |
| `2_LoadBorders.R` | Construit la grille de 5 km sur le Luxembourg (`rtp`), les frontières nationales (`lux_borders`) et régionales (`GRborders`). |
| `3_LoadData.R` | Charge et nettoie les  données brutes |
| `4_MainMap.R` | Carte interactive principale :  grille, points d'observation, curseur par année, filtre par source. |
| `5_SpeciesMaps.R` | Construit la fonction `get_species_map()` (carte de répartition par espèce) et `get_richness_map()` (carte de richesse spécifique par cellule). |
| `6_PresenceMois.R` | Fonctions de graphique de période d'activité par mois (`plot_heatmap`), utilisées dans les fiches espèces. |
| `7_GenerateSpeciesPages.R` | Génère automatiquement un fichier `.qmd` par espèce dans `species_account/` à partir de `_template.qmd` et de `DB_taxo`, puis met à jour `_quarto.yml`. |
| `8_InjectContent.R` | Insère le texte de `species_content/*.txt` (Description, Habitat, Immature, Mature, Distribution, Notes) dans la section correspondante de chaque fiche `.qmd`, sans modifier le reste de la page |
| `9_LastHoverfly.R` | Interroge l'API iNaturalist pour récupérer la dernière observation de syrphe au Luxembourg (photo incluse), utilisée dans `acknowledgement.qmd`. |
| `10_PieChart.R` | Création de pie chart pour la répartion de la tribu et la sous famille (`plot_tribe_pie`, `plot_subfamily_pie`), utilisées dans `ecology.qmd`. |
| `Taxonomie.R` | Construit `DB_taxo` (sous-famille / tribu / genre par espèce) via le Catalogue of Life. |
| `PhylogeneticGraph.R` | Arbre interactif (`collapsibleTree`) de la hiérarchie Subfamily/Tribe/Genus/espèce |
| `Climate_Maps.R`, `Geology.R`, `SoilsMap.R`, `LandOverMap.R`, `DSM.R` | Fonctions de carte pour les pages du chapitre Biophysical (climat, géologie, sols, occupation du sol). |
| `pre-render.R` | Exécution prévue avant chaque rendu du livre ; modifie certains titres dynamiquement selon le taxon concerné. |
| `InsertCitation.R` | Vide |


## Fiches espèces
 
1.  **Modèle** : `species_account/_template.qmd`, contenant des placeholders `<<species>>`, `<<authorship>>`, `<<name>>`, `<<subfamily>>`, `<<tribe>>`, `<<en>>`, `<<lb>>`, `<<fr>>`, `<<de>>`.
2.  **Remplissage taxonomique** : `7_GenerateSpeciesPages.R` remplit ces placeholders à partir de `DB_taxo` (nom, sous-famille, tribu) pour chaque espèce sans fichier existant.
3.  **Injection du texte** : `8_InjectContent.R` insère ensuite le contenu de `species_content/nom_espece.txt` dans les sections correspondantes (`## Description`, `## Habitat`, `### Immature`, `### Mature`, `## Distribution`, `## Notes`)
**Procédure d'ajout d'une nouvelle espèce** :
1. Vérification de la présence de l'espèce dans les données sources (relance de `Taxonomie.R` pour mettre à jour `DB_taxo`).
2. Exécution de `7_GenerateSpeciesPages.R` → création automatique du fichier `.qmd`, sans texte.
3. Rédaction du texte dans `species_content/nom_espece.txt`, avec les titres attendus (il appelle `8_InjectContent.R`) → insertion du texte dans la fiche.
> **Note — nom de l'auteur dans les fichiers `.txt`** : comme indiqué dans les templates, le nom de l'auteur du texte doit être écrit à chaque fois en tout début du fichier `species_content/nom_espece.txt`, avant les sections `Description`, `Habitat`, etc. Cela garantit que chaque fiche espèce affiche correctement son auteur (section `### Author {.author}` du template), au même titre que pour les autres chapitres du livre qui suivent la même convention.
 
Variables de couleur définies en tête de fichier :
 
``` scss
$primary: #5f7132 !default;        // couleur principale : liens, soulignés de titres
$body-color: #263126 !default;     // couleur du texte
$body-bg: #ffffff !default;        // couleur de fond
$headings-color: #16200f !default; // couleur des titres
$link-color: #52662d !default;     // couleur des liens
```
 
**Modification de la couleur principale** : changement de la valeur de `$primary`, par exemple :
 
``` scss
$primary: #2c5f8a !default;
```
 
Cette variable est réutilisée dans plusieurs règles du fichier (soulignement des `h2`, éléments actifs du menu).
 
**Modification de la taille de la photo d'espèce** : règle `.species-photo` plus bas dans le même fichier :
 
``` scss
.species-photo {
  max-width: 70%;
}
```
 
Une valeur de `50%` réduit la taille de la photo sur chaque fiche.
 
**Modification de la police du titre d'une fiche espèce** : définie directement dans `_template.qmd` (dupliquée dans chaque fiche déjà générée) :
 
``` css
#title-block-header .title{
    font-family:Georgia, "Times New Roman", serif;
    font-size:3rem;
}
```
 
Un changement de police doit être appliqué dans `_template.qmd` avant génération de nouvelles fiches ; les fiches déjà générées nécessitent une modification manuelle.
 

## Images
 
Toutes les images du projet sont stockées dans le dossier `images/`.
 
**Image de couverture** : le fichier doit impérativement se nommer `cover.png`. Il est appelé dans `index.qmd` (page de couverture du livre).
 
**Images d'espèces** : le nom de fichier doit être le nom scientifique de l'espèce, en minuscules, avec un underscore `_` entre le genre et l'espèce, par exemple :
 
```
images/blera_fallax.png
images/myathropa_florea.png
```
 
Ce nom correspond au même format que celui utilisé pour les fichiers `.qmd` générés dans `species_account/` (voir section *Fiches espèces*), ce qui permet de faire correspondre automatiquement chaque fiche à son image via le slug de l'espèce.
 




## Autres chapitres 

- `conservation.qmd` : 

- `history.qmd` :

- `glossary.qmd` : titre seul, pas de contenu.

- `introduction.qmd` : 

- `spatial.qmd` : analyse statistique

- `methodology.qmd` : liste des sources de données (citizen science, MNHNL, LBB, Insekteraich, Hoverfly Atlas, Monipol).

- `ecology.qmd` : contient les deux donut charts (tribus/sous-familles).

- `index.qmd` : page de couverture, affichage de `images/cover.png` (le fichier doit obligatoirement porter ce nom exact pour être trouvé par le script/le rendu).

- `1_config.R` contient un chemin local codé en dur : `C:/Users/CAG569/Desktop/Quarto/atlas-mnhnl/Atlas/data/`. Ce chemin est spécifique à un poste de travail.

- `pre-render.R` automatisation des titres avec le noms de la famille

