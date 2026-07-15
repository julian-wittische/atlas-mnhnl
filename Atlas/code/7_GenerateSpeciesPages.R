######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : génération automatique des fiches espèces (.qmd) depuis DB3 à partir de _template.qmd

library(glue)
library(here)
here::i_am("atlas-mnhnl.Rproj")
source(here::here("Atlas", "code", "0_Initialisation.R"))

slugify <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "-", x)
  gsub("^-|-$", "", x)
}

# Lecture du template une seule fois
template_path <- here::here("Atlas","species_account", "_template.qmd")
template_text <- paste(readLines(template_path, encoding = "UTF-8"), collapse = "\n")

especes <- "Episyrphus balteatus"

for (sp in especes) {
  
  slug <- slugify(sp)
  
  qmd_content <- glue(
    template_text,
    species = sp,
    slug = slug,
    .open = "<<",
    .close = ">>"
  )
  
  fichier <- here::here("Atlas",  "species_account", paste0(slug, ".qmd"))
  
  if (file.exists(fichier)) {
    file.remove(fichier)
  }
  
  writeLines(qmd_content, fichier, useBytes = TRUE)
  cat("Créé :", fichier, "\n")
}

