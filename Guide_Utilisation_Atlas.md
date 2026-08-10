------------------------------------------------------------------------

# Guide pas-à-pas : utiliser le template et générer le livre

Ce guide explique ce qu'il faut faire pour faire fonctionner le template.

------------------------------------------------------------------------

## Étape 1 — Récupérer le dossier du projet

Le dossier du projet s'appelle `atlas-mnhnl` (il contient un fichier `atlas-mnhnl.Rproj`, le dossier `Atlas/`, etc.).

Vérifier que le dossier contient bien :

\- le fichier `atlas-mnhnl.Rproj`

\- le sous-dossier `Atlas/` (avec `_quarto.yml`, `code/`, `species_account/`, etc.)

------------------------------------------------------------------------

## Étape 2 — Ouvrir le projet dans RStudio

1.  Ouvrir RStudio.
2.  Menu **File → Open Project...**
3.  Aller chercher le fichier `atlas-mnhnl.Rproj`

------------------------------------------------------------------------

## Étape 3 — Installer les librairies R nécessaires

Le projet utilise plusieurs librairies. Cliquer dans la console les commandes d'installation des librairies utilisées par le projet.

------------------------------------------------------------------------

## Étape 4 — Configurer le chemin vers les données (`1_config.R`)

1.  Dans RStudio, ouvrir le dossier `Atlas/code/`.
2.  Ouvrir le fichier `ConfigTEMPLATE.txt`.
3.  Copier tout son contenu.
4.  Créer un nouveau fichier nommé exactement `1_config.R` dans le même dossier (`Atlas/code/`), et coller le contenu dedans.
5.  Dans ce nouveau fichier `1_config.R`, modifier la ligne qui définit `DATAPATH` pour qu'elle pointe vers l'endroit exact, où se trouve le dossier de données.
6.  Changer le nom du taxon en fonction de l'atlas voulu

## Étape 5 — Vérifier les images nécessaires

Dans le dossier `Atlas/images/`, vérifier que sont présentes au minimum : - `cover.png` (image de couverture du livre, nom obligatoire) - une image par espèce déjà ajoutée, nommée en minuscules avec un underscore entre le genre et l'espèce (exemple : `blera_fallax.png`) - les pictogrammes de statut de conservation (CR, EN, EW, EX, LC, NT, VU)

------------------------------------------------------------------------

## Étape 6 — Vérifier les données et rédiger le texte des espèces

1.  Conformité des données : Vérifier que les données pointées par DATAPATH permettent bien à 3_LoadData.R de produire une table DB avec exactement les colonnes attendues : Lat, Long, ID (nom scientifique), Source, Year, Date, Cell. Pour les popups détaillés des cartes, DB_full doit en plus contenir Origin, Observateur, Identifieur, URL.

2.  Rédaction du texte par espèce Pour chaque espèce, vérifier qu'elle a au moins une observation avec une identification certaine, puis créer/compléter species_content/nom_espece.txt avec les titres exacts reconnus par 8_InjectContent.R : \### Author, \## Description, \## Habitat, \### Immature, \### Mature, \## Distribution, \## Notes.

------------------------------------------------------------------------

## Étape 7 — Lancer le rendu du livre

1.  Dans RStudio, ouvrir le **Terminal**

2.  Se placer à la racine du projet (le Terminal s'ouvre normalement déjà au bon endroit si le projet `.Rproj` est ouvert).

3.  Taper :

    ```         
    quarto render Atlas
    ```

------------------------------------------------------------------------

## Étape 8 — Consulter le livre généré

Une fois le rendu terminé :

1.  Aller dans le dossier `Atlas/_book/`
2.  Ouvrir le fichier `index.html`

------------------------------------------------------------------------

## Étape 9 — Relancer le rendu après une modification

Si on modifie un fichier `.qmd`, un script R, ou les données, il faut refaire l'étape 7 (`quarto render Atlas`) pour que le changement apparaisse dans le livre.

> Si un changement fait dans un script ne semble pas apparaître dans le livre après un nouveau rendu, c'est probablement à cause du cache de Quarto (`Atlas/_freeze/`). Il faut supprimer le sous-dossier correspondant au chapitre concerné dans `_freeze/`, puis relancer `quarto render Atlas`.

------------------------------------------------------------------------

## Étape 10 — Ajouter une nouvelle espèce (opt)

1.  Vérifier que l'espèce a au moins une observation avec une identification certaine dans les données.
2.  Créer un fichier texte dans `Atlas/species_content/`, nommé selon l'espèce, contenant le texte rédigé sous les bons titres (Author, Description, Habitat, etc.).
3.  Ajouter une photo de l'espèce dans `Atlas/images/`, nommée en minuscules avec un underscore entre genre et espèce.
4.  Relancer `quarto render Atlas` (étape 6) : la fiche `.qmd` de la nouvelle espèce est générée automatiquement, et le texte est inséré dedans.

------------------------------------------------------------------------

## Étape 11 — Publier le livre en ligne
