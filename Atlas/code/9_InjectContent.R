######################## PROJECT: Atlas Template
# Script objective : injecte le texte rédactionnel (species_content/) dans les fiches .qmd générées, en écrasant tout contenu déjà présent sous chaque titre

library(here)
here::i_am("atlas-mnhnl.Rproj")

############ Titres reconnus dans le fichier texte ----
titres <- c("## Description", "## Habitat", "### Immature", "### Mature", "## Distribution")

############ Fonction : parse un fichier texte en liste titre -> contenu ----
parse_contenu <- function(chemin_txt) {
  lignes <- readLines(chemin_txt, encoding = "UTF-8", warn = FALSE)
  sections <- list()
  titre_courant <- NULL
  buffer <- c()
  
  for (ligne in lignes) {
    if (ligne %in% titres) {
      if (!is.null(titre_courant)) {
        sections[[titre_courant]] <- paste(buffer, collapse = "\n")
      }
      titre_courant <- ligne
      buffer <- c()
    } else {
      buffer <- c(buffer, ligne)
    }
  }
  if (!is.null(titre_courant)) {
    sections[[titre_courant]] <- paste(buffer, collapse = "\n")
  }
  sections
}

############ Fonction : remplace tout le contenu entre un titre et le suivant ----
injecter_contenu <- function(qmd_lines, sections) {
  ############ Repère toutes les lignes de titre (n'importe quel niveau), pour délimiter les sections
  heading_idx <- which(grepl("^#{1,6} ", qmd_lines))
  
  resultat <- c()
  i <- 1
  n <- length(qmd_lines)
  
  while (i <= n) {
    ligne <- qmd_lines[i]
    resultat <- c(resultat, ligne)
    
    if (ligne %in% names(sections)) {
      ############ Trouve la fin de la section actuelle : prochain titre après i, ou fin de fichier
      idx_dans_headings <- which(heading_idx == i)
      prochain_titre <- heading_idx[heading_idx > i][1]
      fin_section <- if (is.na(prochain_titre)) n + 1 else prochain_titre
      
      ############ Saute (ignore) l'ancien contenu entre le titre et le prochain titre
      i <- fin_section - 1
      
      ############ Insère le nouveau texte à la place
      texte <- trimws(sections[[ligne]])
      if (nchar(texte) > 0) {
        resultat <- c(resultat, "", texte, "")
      }
    }
    i <- i + 1
  }
  resultat
}

############ Boucle sur toutes les fiches espèces ----
fichiers_qmd <- list.files(here::here("Atlas", "species_account"), pattern = "\\.qmd$", full.names = FALSE)
fichiers_qmd <- setdiff(fichiers_qmd, c("_template.qmd", "PLACEHOLDER.qmd"))

for (f in fichiers_qmd) {
  slug <- sub("\\.qmd$", "", f)
  chemin_txt <- here::here("Atlas", "species_content", paste0(slug, ".txt"))
  
  if (!file.exists(chemin_txt)) {
    cat("Pas de contenu texte pour :", slug, "(ignoré)\n")
    next
  }
  
  chemin_qmd <- here::here("Atlas", "species_account", f)
  qmd_lines <- readLines(chemin_qmd, encoding = "UTF-8", warn = FALSE)
  sections <- parse_contenu(chemin_txt)
  qmd_final <- injecter_contenu(qmd_lines, sections)
  
  writeLines(qmd_final, chemin_qmd)
  cat("Contenu inséré dans :", f, "\n")
}

