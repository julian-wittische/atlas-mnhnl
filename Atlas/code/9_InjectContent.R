######################## PROJECT: Atlas Template
# Script objective : injecte le texte rédactionnel (species_content/) dans les fiches .qmd générées, en écrasant tout contenu déjà présent sous chaque titre

library(here)
here::i_am("atlas-mnhnl.Rproj")

############ Titres reconnus dans le fichier texte ----
titres <- c("## Description", "## Habitat", "### Immature", "### Mature", "## Distribution", "## Notes")

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

############ remplace tout le contenu----
injecter_contenu <- function(qmd_lines, sections) {
  
  resultat <- c()
  i <- 1
  n <- length(qmd_lines)
  
  while (i <= n) {
    
    ligne <- qmd_lines[i]
    resultat <- c(resultat, ligne)
    
    if (ligne %in% names(sections)) {
      
      i <- i + 1
      
      # Ajouter le nouveau texte
      texte <- trimws(sections[[ligne]])
      if (nchar(texte) > 0) {
        resultat <- c(resultat, "", texte, "")
      }
      
      # supprimer uniquement le texte jusqu'au prochain titre
      while (i <= n && !grepl("^#{1,6} ", qmd_lines[i])) {
        
        # garder les blocs ::: et chunks R
        if (grepl("^:::|^```", qmd_lines[i])) {
          
          debut_bloc <- i
          
          # avancer jusqu'à la fin du bloc
          i <- i + 1
          while (i <= n && !grepl("^```$|^:::$", qmd_lines[i])) {
            i <- i + 1
          }
          
          if (i <= n) {
            i <- i + 1
          }
          
          resultat <- c(resultat, qmd_lines[debut_bloc:i-1])
        } else {
          i <- i + 1
        }
      }
      
      next
    }
    
    i <- i + 1
  }
  
  resultat
}

# Boucle sur toutes les fiches
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

