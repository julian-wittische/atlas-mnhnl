# Description des fichiers

Cette documentation décrit l'emplacement et le rôle de chaque fichier du projet `atlas-mnhnl`

------------------------------------------------------------------------

## 1. Configuration du livre Quarto

### `Atlas/_quarto.yml`

- **Rôle** : fichier de configuration du projet Quarto (type `book`). Définit le titre, l'ordre des chapitres, la sidebar, la bibliographie (`references.bib`) et les options de rendu HTML et/ou pdf.

- Le bloc `chapters: - species_account/...` est celui que le script `7_GenerateSpeciesPages.R` (voir plus bas) modifie automatiquement pour y insérer les nouvelles fiches espèces.

------------------------------------------------------------------------

## 2. Pages `.qmd` (contenu du livre)

Situées dans `Atlas/`

### `index.qmd`

- **Description** : page de couverture du livre.
- **Rôle** : affiche l'image `images/cover.png`

### `acknowledgement.qmd`

- **Description** : page de remerciements pour les sciences participatives.
- **Rôle** : liste tous les observateurs, les separent en 2 classes : inat+obs.org vs autres sources, et affiche la dernière observation enregistrée

### `biophysical/geo_topography.qmd`

- **Description** : sous-section consacrée à la géologie, l'altitude et la pédologie
- **Rôle** : Vue géographique de la répartition de ces 3 domaines

### `biophysical/climate.qmd`

- **Description** : sous-section consacrée à la couverture des sols
- **Rôle** : Vue géographique de la couverture des sols

### `biophysical/land_use_cover.qmd`

- **Description** : sous-section consacrée au climat
- **Rôle** : Vue géographique de la température et des précipitations annuelles moyennes

### `conservation.qmd`

- **Description** : chapitre sur la conservation des syrphes au Luxembourg.
- **Rôle** : actuellement à l'état d'ébauche — une seule sous-section rédigée, sur l'importance des plateformes de sciences participatives.

### `ecology.qmd`

- **Description** : chapitre "Ecology of Luxembourg Hoverflies".
- **Rôle** :

### `glossary.qmd`

- **Description** : glossaire du livre.
- **Rôle** : définitions des termes techniques

### `history.qmd`

- **Description** : chapitre sur l'historique des observations au Luxembourg.
- **Rôle** : destiné à retracer l'histoire du recensement des espèces

### `introduction.qmd`

- **Description** : introduction générale du livre.
- **Rôle** : présente le contexte

### `methodology.qmd`

- **Description** : chapitre méthodologie.
- **Rôle** : décrit les sources de données utilisées dans l'atlas

### `statistics.qmd`

- **Description** : chapitre statistiques.
- **Rôle** : réservé pour les statistiques

### `references.qmd`

- **Description** : page de bibliographie.
- **Rôle** : génère automatiquement la liste complète des références citées

### `species_account/*.qmd`

- **Description** : fiches espèces, une par espèce
- **Rôle** : Vue complète sur chaque espèce / générées automatiquement par `7_GenerateSpeciesPages.R` à partir du `_template.qmd`

------------------------------------------------------------------------

## 3. Scripts R — dossier `Atlas/code/`

### `0_Initialisation.R`

- **Description** : script d'initialisation
- **Rôle** : charge toutes les librairies nécessaires, puis charge les scripts utiles

### `1_config.R`

- **Description** : fichier de configuration locale.
- **Rôle** : définit `DATAPATH`, le chemin local vers le dossier de données (`Atlas/data/`) (chemin propre à chaque poste)

### `2_LoadBorders.R`

- **Description** : script de préparation des couches géographiques de référence.
- **Rôle** : construit la bbox de la Grande Région, charge ses frontières, construit une grille raster de 5 km sur le Luxembourg, récupère la frontière nationale et numérote les cellules valides — cette grille sert de base à toutes les cartes par cellule du projet.

### `3_LoadData.R`

- **Description** : script de chargement et nettoyage des données d'observation.
- **Rôle** : charge et harmonise trois sources d'observations — **Bycatch**, **Hand netting** et **MNHNL**

### `4_MainMap.R`

- **Description** : script de construction de la carte interactive principale.
- **Rôle** : assemble un fond de carte, superpose la grille et les points d'observation

### `5_SpeciesMaps.R`

- **Description** : script de génération des cartes par espèce et de la carte de richesse spécifique.
- **Rôle** : La carte par espèce permet d'avoir une vue sur les observations (vue différente selon le zoom + infos au clic). La carte de richesse spécifique permet d'avoir une vue d'ensemble des observations

### `6_PresenceMois.R`

- **Description** : script de génération des graphiques de présence par mois
- **Rôle** : Prépare, pour une espèce donnée, les comptes d'observations par quart de mois et par type de source, produit un histogramme empilé par source et une heatmap du nombre d'observations par quart de mois utilise les fiches espèces.

### `7_GenerateSpeciesPages.R`

- **Description** : script de génération automatique des fiches espèces.
- **Rôle** : Permet de générer automatiquement les pages de `species_account/*.qmd`, met à jour le `quarto.yml`

### `8_InjectContent.R`

- **Description** : script d'injection du texte descriptif dans les fiches espèces.
- **Rôle** : Mettre à jour les textes dans les chapitres species account, directement lancé dans `7_GenerateSpeciesPages.R` à partir des fichiers texte de `species_content/*`

### `9_LastHoverfly.R`

- **Description** : script de récupération de la dernière observation
- **Rôle** : interroge l'API iNaturalist pour récupérer l'id taxonomique de la famille choisie. Télécharge la photo dans `Atlas/last_syrphidae.jpg`, utilisée par `acknowledgement.qmd`.

### `10_PieChart.R`

- **Description** : génération de 2 pie chart taxonomique
- **Rôle** : voir la dispersion des tribus (couleur par sous-famille) et sous-familles

### `ConfigTEMPLATE.txt`

- **Description** : exemple de fichier de config
- **Rôle** : sert de modèle à copier localement sous le nom `config.R` pour définir `DATAPATH`

### `DSM.R`

- **Description** : script de génération de la carte d'altitude.
- **Rôle** : Génère 2 cartes d'altitude, une statique, une dynamique

### `Geology.R`

- **Description** : script de génération des cartes géologiques.
- **Rôle** : Génère 2 cartes de géologie, une statique, une dynamique

### `pre-render.R`

- **Description** : script de pré-rendu du livre Quarto.
- **Rôle** : il met à jour dynamiquement les titres de plusieurs fichiers selon une variable `taxon`

### `SoilsMap.R`

- **Description** : script de génération de la carte des sols.
- **Rôle** : Générer une carte statique + légende

### `Taxonomie.R`

- **Description** : script de construction de la table de référence taxonomique.
- **Rôle** : Construit `DB_taxo` (`verbatim_name`, `name`, `authorship`, `Subfamily`, `Tribe`, `Genus`) en filtrant les espèces valides, en interrogeant le Catalogue of Life (`col_match_checklist`) et en extrayant la sous-famille et la tribu.

### `PhylogeneticGraph.R`

- **Description** : script de conception d un graphe interactif avec les taxon
- **Rôle** : Voir les differents rang taxonomique de facon interactive


### `utils.R`

- **Description** : fonctions utiles
- **Rôle** : regroupe des fonctions réutilisées dans plusieurs scripts.

------------------------------------------------------------------------

## 4. Texte Species Account — dossier `species_content/`

- **Description** : Dossier contenant tous les fichiers texte de chaque espèce pour le chapitre Species Account
- **Rôle** : Permet d'insérer dans chaque page le texte voulu
