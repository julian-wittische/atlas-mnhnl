######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : génération automatique des fiches espèces (.qmd) depuis DB3 à partir de _template.qmd


library(dplyr)
library(stringr)
library(here)
library(yaml)

here::i_am("atlas-mnhnl.Rproj")

############ 1. Préparation et tri des espèces ----
# Ordre : Sous-famille, Tribu, Genre, épithète -> détermine l'ordre des
# fiches à l'intérieur de "Species accounts"
species_df <- DB_taxo %>%
  filter(!is.na(Subfamily), !is.na(Tribe)) %>%
  arrange(Subfamily, Tribe, Genus, name) %>%
  mutate(
    slug        = tolower(str_replace_all(name, "[^A-Za-z0-9]+", "_")),
    fichier_qmd = paste0(slug, ".qmd")
  )

############ 2. Génération d'une fiche .qmd par espèce depuis le template ----
chemin_template  <- here("Atlas", "species_account", "_template.qmd")
lignes_template  <- readLines(chemin_template, encoding = "UTF-8", warn = FALSE)

for (i in seq_len(nrow(species_df))) {
  sp <- species_df[i, ]
  chemin_sortie <- here("Atlas", "species_account", sp$fichier_qmd)
  
  # Idempotence : si la fiche existe déjà (ex. déjà remplie par le script
  # d'injection de texte species_content/), on ne l'écrase pas
  if (file.exists(chemin_sortie)) {
    cat("Fiche déjà existante, non écrasée :", sp$fichier_qmd, "\n")
    next
  }
  
  lignes_fiche <- lignes_template
  lignes_fiche <- str_replace_all(lignes_fiche, fixed("<<species>>"), sp$name)
  lignes_fiche <- str_replace_all(lignes_fiche, fixed("<<authorship>>"), sp$authorship)
  lignes_fiche <- str_replace_all(lignes_fiche, fixed("<<slug>>"), sp$slug)
  lignes_fiche <- str_replace_all(lignes_fiche, fixed("<<subfamily>>"), sp$Subfamily)
  lignes_fiche <- str_replace_all(lignes_fiche, fixed("<<tribe>>"), sp$Tribe)
  
  writeLines(lignes_fiche, chemin_sortie)
}

cat(nrow(species_df), "espèces traitées (fiches déjà existantes préservées).\n")

############ 3. Liste ordonnée des chemins de fiches espèces ----
chemins_especes <- as.list(file.path("species_account", species_df$fichier_qmd))

############ 4. Mise à jour de _quarto.yml (bloc "part: Species accounts") ----
chemin_yml  <- here("Atlas", "_quarto.yml")
quarto_yml  <- yaml::read_yaml(chemin_yml)

idx_part_especes <- which(vapply(
  quarto_yml$book$chapters,
  function(ch) is.list(ch) && identical(ch$part, "Species accounts"),
  logical(1)
))

if (length(idx_part_especes) != 1) {
  stop(
    "Impossible de trouver un unique bloc 'part: Species accounts' dans ",
    "_quarto.yml (trouvé : ", length(idx_part_especes), " occurrence(s)). ",
    "Vérifie la structure du fichier avant de continuer."
  )
}

quarto_yml$book$chapters[[idx_part_especes]]$chapters <- chemins_especes

yaml::write_yaml(
  quarto_yml,
  chemin_yml,
  handlers = list(logical = yaml::verbatim_logical)  
)
