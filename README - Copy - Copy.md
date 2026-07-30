# Documentation du template d'atlas biodiversité

## Vue d'ensemble

Ce projet est un template, en Quarto et R, pour construire un atlas de biodiversité. 
Le sommaire du livre est défini dans `_quarto.yml`, dans le sous-dossier `Atlas/`. 
Chaque chapitre est un fichier `.qmd`, contenant à la fois du texte et des blocs de code R qui génèrent automatiquement cartes, graphiques et tableaux. 
Le dossier `code/` contient les scripts R communs : préparation des données, fonctions de cartographie, génération des fiches espèces. 
Le fichier `style.scss` définit l'apparence visuelle du site (couleurs, tailles, espacements).

Racine du projet R : `atlas-mnhnl` (fichier `atlas-mnhnl.Rproj`).

## Comment lancer le rendu du livre


En ligne de commande dans le Terminal, depuis la racine du projet :
```bash
quarto render Atlas
```

Le rendu produit un dossier `Atlas/_book/` avec la version HTML navigable du livre (une page par chapitre) ainsi que les librairies JS/CSS.

Le dossier `Atlas/_freeze/` contient le cache de Quarto : les résultats déjà calculés pour un chapitre sont réutilisés tant que son code n'a pas changé, ce qui évite de recalculer à chaque rendu. Si un rendu ne reflète pas un changement fait dans un script, supprimer le sous-dossier concerné dans `_freeze/`.

Le script `pre-render.R` s'exécute automatiquement avant le rendu du livre. Il enchaîne, dans l'ordre :
1. `Taxonomie.R` : construit `DB_taxo` (sous-famille, tribu, genre par espèce) à partir des données d'observation et du Catalogue of Life.
2. `7_GenerateSpeciesPages.R` : génère une fiche `.qmd` pour chaque nouvelle espèce à partir de `_template.qmd` et `DB_taxo`, met à jour `_quarto.yml`, puis appelle `8_InjectContent.R` pour insérer le texte rédigé dans `species_content/`.
3. Mise à jour dynamique des titres du livre et des chapitres (`ecology.qmd`, `history.qmd`, `conservation.qmd`) en fonction du taxon.

## Configuration locale (`1_config.R`)

Le chemin vers le dossier de données (`DATAPATH`) est défini dans `1_config.R` et propre à chaque poste de travail. `code/ConfigTEMPLATE.txt` sert de modèle pour créer ce fichier localement : on en copie le contenu dans `1_config.R` et on adapte le chemin.

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
└── code/                 → scripts R (voir section Scripts)
```

## `_quarto.yml`

Structure résumée :

```yaml
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

La liste `chapters:` détermine l'ordre exact des pages du livre. Les blocs `part:` créent une sous-section dans un chapitre. La ligne `theme: light: [zephyr, style.scss]` applique le thème de base puis les personnalisations faite dans `style.scss`.

**Ajout d'un chapitre standard** : création du fichier `.qmd` correspondant, puis ajout de son chemin dans la liste `chapters:` à la position voulue.

**Cas des fiches espèces** : l'ajout de chemins sous `part: Species accounts` est automatisé par `7_GenerateSpeciesPages.R` et remis à jour à chaque rendu par `pre-render.R` (voir section Scripts).

## Contenu d'un fichier `.qmd`

Exemple : `biophysical/climate.qmd`.

```markdown
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
```

Éléments :
- `# Climate` : titre principal du chapitre.
- Bloc `setup` : charge `0_Initialisation.R`, qui charge les librairies et les scripts communs essentiels (config, bordures, données, cartes principales, graphiques d'activité). Les scripts spécifiques à un chapitre (ici `14_ClimateMaps.R`) ne sont pas chargés dans `0_Initialisation.R` mais directement dans le `.qmd` qui en a besoin.
- `## Annual Mean Temperature` : titre de niveau 2.
- Le bloc de code appelle une fonction déjà définie dans `code/` (`plot_bio1_map`) ; le résultat s'affiche directement dans la page.
- `#| echo: false` masque le code R dans le rendu final. `#| fig.height` / `#| fig.width` fixent les dimensions de la figure.

Principe général : une page `.qmd` n'effectue quasiment aucun calcul directement ; elle appelle des fonctions déjà écrites dans `code/`.

## Scripts (`code/`)

Ordre de chargement des scripts essentiels, défini dans `0_Initialisation.R` :

```r
source("1_config.R")
source("utils.R")
source("2_LoadBorders.R")
source("3_LoadData.R")
source("4_MainMap.R")
source("5_SpeciesMaps.R")
source("6_PresenceMois.R")
```

Les scripts au-delà de ceux-ci (génération des fiches espèces, cartes biophysiques, taxonomie, arbre phylogénétique) sont chargés directement dans les `.qmd` qui en ont besoin, pas dans l'initialisation globale.

| Script | Rôle |
|---|---|
| `0_Initialisation.R` | Charge l'ensemble des librairies R, puis les scripts essentiels listés ci-dessus. |
| `1_config.R` | Définit `DATAPATH`, propre à chaque poste (voir section Configuration locale). |
| `utils.R` | Fonctions réutilisées ailleurs dans le projet, par exemple `filter_checkboxSP` (cases à cocher personnalisées des cartes interactives, basées sur crosstalk). |
| `2_LoadBorders.R` | Construit la grille de 5 km sur le Luxembourg (`rtp`), les frontières nationales (`lux_borders`) et régionales (`GRborders`). |
| `3_LoadData.R` | Charge et nettoie les données d'observation brutes, construit les tables combinées utilisées par le reste du pipeline. |
| `4_MainMap.R` | Carte interactive principale : grille, points d'observation, curseur par année, filtre par source. |
| `5_SpeciesMaps.R` | Construit `get_species_map()` (carte de répartition par espèce) et `get_richness_map()` (carte de richesse spécifique par cellule). |
| `6_PresenceMois.R` | Fonctions de graphique de période d'activité par mois (`plot_heatmap`), utilisées dans les fiches espèces. |
| `7_GenerateSpeciesPages.R` | Génère automatiquement un fichier `.qmd` par espèce dans `species_account/` à partir de `_template.qmd` et de `DB_taxo`, puis met à jour `_quarto.yml`. Vérifie aussi le statut taxonomique de chaque nom (accepté, synonyme, non trouvé) via le Catalogue of Life, et écarte les noms de genre seul ou les doublons. |
| `8_InjectContent.R` | Insère le texte de `species_content/*.txt` (Author, Description, Habitat, Immature, Mature, Distribution, Notes) dans la section correspondante de chaque fiche `.qmd`, sans modifier le reste de la page. Une sauvegarde `.bak` de la fiche est créée avant chaque écriture. |
| `9_LastHoverfly.R` | Interroge l'API iNaturalist pour récupérer la dernière observation de syrphe au Luxembourg (photo incluse), utilisée dans `acknowledgement.qmd`. |
| `10_PieChart.R` | Création de pie charts pour la répartition de la tribu et de la sous-famille (`plot_tribe_pie`, `plot_subfamily_pie`), destinées à `ecology.qmd`. |
| `11_Geology.R` | Fonctions de carte géologique et de sa légende (`plot_carte_geologique`, `plot_legende_geologique`), utilisées dans `geo_topography.qmd`. |
| `12_SoilsMap.R` | Fonctions de carte des sols et de sa légende (`plot_carte_sols`, `plot_legende_sols`). |
| `13_DSM.R` | Carte d'altitude (modèle numérique de surface). Actuellement non appelée dans `geo_topography.qmd` (chapitre Altitude vide). |
| `14_ClimateMaps.R` | Cartes climatiques : température annuelle moyenne, précipitations, et un sélecteur de variables BIOCLIM en HTML. |
| `15_LandOverMap.R` | Carte d'occupation du sol, prévue pour `land_use_cover.qmd` (chapitre actuellement vide). |
| `Taxonomie.R` | Construit `DB_taxo` (nom, sous-famille, tribu, genre par espèce) via le Catalogue of Life. |
| `PhylogeneticGraph.R` | Arbre interactif (`collapsibleTree`) de la hiérarchie Subfamily/Tribe/Genus/espèce. |
| `pre-render.R` | Met à jour les titres dynamiques du livre et la liste des fiches espèces dans `_quarto.yml`, à chaque rendu. |

## Fiches espèces

1. **Modèle** : `species_account/_template.qmd`, contenant des placeholders `<<species>>`, `<<authorship>>`, `<<name>>`, `<<subfamily>>`, `<<tribe>>`, `<<en>>`, `<<lb>>`, `<<fr>>`, `<<de>>`.
2. **Remplissage taxonomique** : `7_GenerateSpeciesPages.R` remplit ces placeholders à partir de `DB_taxo` (nom, sous-famille, tribu) et du Catalogue of Life (noms vernaculaires EN/LB/FR/DE) pour chaque espèce sans fichier existant.
3. **Injection du texte** : `8_InjectContent.R`  insère le contenu de `species_content/nom_espece.txt` dans les sections correspondantes (`### Author`, `## Description`, `## Habitat`, `### Immature`, `### Mature`, `## Distribution`, `## Notes`).

**Procédure d'ajout d'une nouvelle espèce** :
1. Vérifier que l'espèce a au moins une observation avec un ID certain  dans les données sources 
1. Créer un fichier par espece et rédiger le texte dans `species_content/nom_espece.txt`, avec les titres attendus
2. Ajouter une photo pour chaque espece nommée `images/nom_espece.png` minuscules, underscore entre genre et espèce).
4. Lancer le rendu Quarto Book (`quarto render Atlas`)

### Comprendre la carte et le graphique d'une fiche espèce

La carte interactive affiche trois couches superposées, activables ou désactivables via le menu en haut à droite de la carte :
- **Grid** : la grille de cellules de 5 km utilisée pour découper le territoire luxembourgeois. Toujours visible en fond, avec un contour rouge fin.
- **Cells** : les cellules de la grille où l'espèce a été observée au moins une fois, colorées en rouge. Un clic sur une cellule ouvre une fenêtre indiquant le nombre total d'observations dans cette cellule et le détail par méthode/source de collecte.
- **Points** : les observations individuelles, affichées comme des points rouges à partir d'un certain zoom. Un clic sur un point affiche le détail de cette observation précise : la méthode de collecte (Source), la date, l'observateur, l'identificateur, et un lien direct vers la fiche iNaturalist ou Observation.org si l'observation vient de l'une de ces plateformes.

Le passage d'une couche à l'autre est automatique selon le niveau de zoom : à faible zoom, seules les cellules colorées (Cells) sont visibles ; à partir du niveau 12, les cellules disparaissent et les points individuels apparaissent.

Le graphique d'activité (heatmap) est une bande horizontale divisée en 48 segments (4 par mois, un par quart de mois : jours 1-7, 8-14, 15-21, et 22-fin de mois). Chaque segment est coloré selon le nombre d'observations enregistrées durant cette période de l'année, toutes années confondues : blanc pour aucune observation, vert de plus en plus foncé quand le nombre d'observations augmente. Ce graphique permet de voir en un coup d'œil la période de l'année où l'espèce est le plus souvent observée.

## Images

Toutes les images du projet sont stockées dans le dossier `images/`.

**Image de couverture** : le fichier doit impérativement se nommer `cover.png`. Il est appelé dans `index.qmd` (page de couverture du livre).

**Images d'espèces** : le nom de fichier doit être le nom scientifique de l'espèce, en minuscules, avec un underscore entre le genre et l'espèce, par exemple `images/blera_fallax.png`, `images/myathropa_florea.png`. Ce nom correspond au slug utilisé pour les fichiers `.qmd` de `species_account/`, ce qui permet de faire correspondre automatiquement chaque fiche à son image. Une photo est nécessaire pour chaque espèce ajoutée : sans fichier portant ce nom dans `images/`, la fiche pointera vers une image qui n'existe pas.

**Images de statut de conservation** : chaque fiche affiche trois blocs de statut (Europe, Union européenne, Luxembourg), chacun accompagné d'un pictogramme IUCN stocké dans `images/` (catégories disponibles : CR, EN, EW, EX, LC, NT, VU, plus une version spécifique Luxembourg `NTLU.png`).

## Style (`style.scss`)

Variables de couleur en tête de fichier :

```scss
$primary: #5f7132 !default;
$body-color: #263126 !default;
$body-bg: #ffffff !default;
$headings-color: #16200f !default;
$link-color: #52662d !default;
```

**Modifier la couleur principale** :
```scss
$primary: #2c5f8a !default;
```

**Modifier la taille de la photo d'espèce** (règle `.species-photo`) :
```scss
.species-photo {
  max-width: 70%;   // 50% pour réduire la taille de la photo sur chaque fiche
}
```

**Modifier la police du titre d'une fiche espèce** : définie directement dans `_template.qmd` (dupliquée dans chaque fiche déjà générée), pas dans `style.scss`. Un changement de police doit être appliqué dans `_template.qmd` avant génération de nouvelles fiches ; les fiches déjà générées nécessitent une modification manuelle.

## Data (`data/`)

Le dossier `data/` regroupe les données géographiques du Luxembourg utilisées pour les chapitres Biophysical : frontières, géologie, sols, occupation du sol.