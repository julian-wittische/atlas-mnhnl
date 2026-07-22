######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : injecte le texte (species_content/) dans les fiches species account


############ Titres reconnus dans le fichier texte ----

titres_reconnus <- c("## Description", "## Habitat", "### Immature", "### Mature",
                     "## Distribution", "## Notes")

############ Sauvegarde du texte  ----
lire_sections_texte <- function(chemin_txt) {

  lignes_source <- c(readLines(chemin_txt, encoding = "UTF-8", warn = FALSE), "## __FIN__")
  
  contenu_par_titre <- list()
  titre_en_cours <- NULL
  lignes_du_titre <- c()
  
  cloturer_section <- function() {
    if (is.null(titre_en_cours)) {
      
      if (any(nzchar(trimws(lignes_du_titre)))) {
        warning("Texte avant le premier titre reconnu, ignore dans : ", chemin_txt, call. = FALSE)
      }
      return(invisible(NULL))
    }
    if (titre_en_cours %in% names(contenu_par_titre)) {
      warning("Titre '", titre_en_cours, "' apparait plusieurs fois dans : ", chemin_txt,
              " -- seule la derniere occurrence est conservee", call. = FALSE)
    }
    contenu_par_titre[[titre_en_cours]] <<- paste(lignes_du_titre, collapse = "\n")
  }
  
  for (ligne_source in lignes_source) {
    if (ligne_source %in% titres_reconnus || ligne_source == "## __FIN__") {
      cloturer_section()
      titre_en_cours <- ligne_source
      lignes_du_titre <- c()
    } else {
      lignes_du_titre <- c(lignes_du_titre, ligne_source)
    }
  }
  contenu_par_titre
}
############ Ne pas supprimer les chunk  ----
garder_bloc <- function(lignes_qmd, i, nb_lignes) {
  debut_bloc <- i
  i <- i + 1
  while (i <= nb_lignes && !grepl("^```$|^:::$", lignes_qmd[i])) {
    i <- i + 1}
  if (i <= nb_lignes) i <- i + 1
  list(lignes_bloc = lignes_qmd[debut_bloc:(i - 1)], i_suivant = i)
}
############ Remplace le contenu de chaque titre dans le .qmd ----

#   - "insertion" : rien avant
#   - "mise_a_jour" : texte different
#   - "aucun_changement" : texte identique
#   - NA  : rien a signaler
remplacer_sections <- function(lignes_qmd, contenu_par_titre) {
  
  lignes_qmd_modifiees <- c()
  statut_par_titre <- list()
  i <- 1
  nb_lignes <- length(lignes_qmd)
  
  while (i <= nb_lignes) {
    ligne_actuelle <- lignes_qmd[i]
    lignes_qmd_modifiees <- c(lignes_qmd_modifiees, ligne_actuelle)
    
    if (!(ligne_actuelle %in% names(contenu_par_titre))) {
      i <- i + 1
      next }
    i <- i + 1
    
    # insertion du nouveau texte
    texte_a_inserer <- trimws(contenu_par_titre[[ligne_actuelle]])
    if (nchar(texte_a_inserer) > 0) {
      lignes_qmd_modifiees <- c(lignes_qmd_modifiees, "", texte_a_inserer, "")}
    
    ancien_texte_lignes <- c()
    while (i <= nb_lignes && !grepl("^#{1,6} ", lignes_qmd[i])) {
      if (grepl("^:::|^```", lignes_qmd[i])) {
        bloc <- garder_bloc(lignes_qmd, i, nb_lignes)
        lignes_qmd_modifiees <- c(lignes_qmd_modifiees, bloc$lignes_bloc)
        i <- bloc$i_suivant}
      else {
        ancien_texte_lignes <- c(ancien_texte_lignes, lignes_qmd[i])
        i <- i + 1}}
    
    ancien_texte <- trimws(paste(ancien_texte_lignes, collapse = "\n"))
    
    statut_par_titre[[ligne_actuelle]] <- if (nchar(ancien_texte) == 0 && nchar(texte_a_inserer) > 0) {
      "insertion"
    } else if (nchar(ancien_texte) > 0 && ancien_texte != texte_a_inserer) {
      "mise_a_jour"
    } else if (nchar(ancien_texte) > 0 && ancien_texte == texte_a_inserer) {
      "aucun_changement"
    } else {
      NA_character_
    }
  }
  
  list(lignes = lignes_qmd_modifiees, statuts = statut_par_titre)
}
############ Remplir fiches espèces ----
fichiers_qmd <- list.files(here::here("Atlas", "species_account"), pattern = "\\.qmd$", full.names = FALSE)
fichiers_qmd <- setdiff(fichiers_qmd, c("_template.qmd", "PLACEHOLDER.qmd"))

for (fichier_qmd in fichiers_qmd) {
  slug <- sub("\\.qmd$", "", fichier_qmd)
  chemin_txt <- here::here("Atlas", "species_content", paste0(slug, ".txt"))
  
  if (!file.exists(chemin_txt)) {
    cat("Pas de contenu texte pour :", slug, "(ignoré)\n")
    next
  }
  
  chemin_qmd <- here::here("Atlas", "species_account", fichier_qmd)
  lignes_qmd <- readLines(chemin_qmd, encoding = "UTF-8", warn = FALSE)
  contenu_par_titre <- lire_sections_texte(chemin_txt)
  
  
  titres_inattendus <- setdiff(names(contenu_par_titre), c(titres_reconnus, "## __FIN__"))
  if (length(titres_inattendus) > 0) {
    cat("Titres non reconnus dans", slug, ":", paste(titres_inattendus, collapse = ", "), "\n")
  }
  
  resultat_remplacement <- remplacer_sections(lignes_qmd, contenu_par_titre)
  lignes_qmd_final <- resultat_remplacement$lignes
  statuts <- resultat_remplacement$statuts
  

  statuts_valides <- statuts[!vapply(statuts, is.na, logical(1))]
  
  if (length(statuts_valides) == 0) {

  } else if ("mise_a_jour" %in% statuts_valides) {
    cat("Mise a jour de :", slug, "\n")
  } else if ("insertion" %in% statuts_valides) {
    cat("Insertion dans :", slug, "\n")
  } else {
    cat("Aucun changement pour :", slug, "\n")
  }
  
  
  file.copy(chemin_qmd, paste0(chemin_qmd, ".bak"), overwrite = TRUE)
  
  
  con <- file(chemin_qmd, open = "w", encoding = "UTF-8")
  writeLines(lignes_qmd_final, con, useBytes = TRUE)
  close(con)
}

