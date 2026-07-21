######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : injecte le texte (species_content/) dans les fiches species account 


############ Titres reconnus dans le fichier texte ----
titres_reconnus <- c("## Description", "## Habitat", "### Immature", "### Mature",
                     "## Distribution", "## Notes")





############ Sauvegarde duu texte  ----
lire_sections_texte <- function(chemin_txt) {
  # evite de dupliquer le code qui "clôture" la dernière section
  lignes_source <- c(readLines(chemin_txt, encoding = "UTF-8", warn = FALSE), "## __FIN__")
  
  contenu_par_titre <- list()
  titre_en_cours <- NULL
  lignes_du_titre <- c()
  
  for (ligne_source in lignes_source) {
    if (ligne_source %in% titres_reconnus || ligne_source == "## __FIN__") {
      if (!is.null(titre_en_cours)) {
        contenu_par_titre[[titre_en_cours]] <- paste(lignes_du_titre, collapse = "\n")}
      titre_en_cours <- ligne_source
      lignes_du_titre <- c() } 
      else {
      lignes_du_titre <- c(lignes_du_titre, ligne_source) }}
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
remplacer_sections <- function(lignes_qmd, contenu_par_titre) {
  
  lignes_qmd_modifiees <- c()
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
    
    # suppression de l'ancien texte + conservation chunks et sections
    while (i <= nb_lignes && !grepl("^#{1,6} ", lignes_qmd[i])) {
      if (grepl("^:::|^```", lignes_qmd[i])) {
        bloc <- garder_bloc(lignes_qmd, i, nb_lignes)
        lignes_qmd_modifiees <- c(lignes_qmd_modifiees, bloc$lignes_bloc)
        i <- bloc$i_suivant} 
        else {
        i <- i + 1}}}
  
  lignes_qmd_modifiees
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
  lignes_qmd_final <- remplacer_sections(lignes_qmd, contenu_par_titre)
  
  writeLines(lignes_qmd_final, chemin_qmd)}

