######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Crée / met à jour une DB de sous-famille - tribu - genre par espèce,
#                     sans refaire les appels Catalogue of Life pour les espèces déjà connues.


############ Filtrage ----
DB$Certainty <- !grepl("\\?", DB$ID)
sum(DB$Certainty, na.rm = TRUE)

############ espèces à traiter (données sources) ----

species_list <- DB %>% 
  filter(Certainty) %>% 
  pull(ID) %>% 
  unique() %>% 
  as.character()

############ Cache existant ----
chemin_cache <- here::here("Atlas", "data", "DB_taxo.rds")
if (file.exists(chemin_cache)) {
  DB_taxo <- readRDS(chemin_cache)
} else {
  DB_taxo <- tibble(
    verbatim_name = character(),
    name          = character(),
    authorship    = character(),
    Subfamily     = character(),
    Tribe         = character(),
    Genus         = character()
  )
}

############ Espèces déjà connues vs nouvelles ----

species_list <- species_list[!is.na(species_list) & species_list != ""]
species_manquantes <- setdiff(species_list, DB_taxo$verbatim_name)

message(length(species_manquantes), " nouvelle(s) espèce(s) à interroger sur Catalogue of Life (",
        length(species_list) - length(species_manquantes), " déjà en cache).")

############ Catalogue of Life : uniquement pour les nouvelles espèces ----
if (length(species_manquantes) > 0) {
  
  
  message("Interrogation de l'API Catalogue of Life...")
  matches <- purrr::map_dfr(species_manquantes, function(sp) {
    res <- rcol::col_match(sp)
    res$verbatim_name <- sp  # Alignement manuel
    
    if ("names_index_id" %in% names(res)) {
      res$names_index_id <- as.character(res$names_index_id)
    }
    
    return(res)
  })
  
  ############ extraction d'un rang taxonomique donné ----
  extract_rank_local <- function(classif, target_rank) {
    if (is.null(classif) || !is.data.frame(classif) || !"rank" %in% names(classif)) {
      return(NA_character_)
    }
    row <- classif %>% filter(tolower(rank) == tolower(target_rank))
    if (nrow(row) == 0) return(NA_character_)
    row$name[1]
  }
  
  ############ Nouvelles lignes DB_taxo ----
  nouvelles_lignes <- matches %>%
    filter(!is.na(usage_id)) %>%
    mutate(
      Genus     = stringr::word(verbatim_name, 1),
      Subfamily = map_chr(classification, extract_rank_local, target_rank = "subfamily"),
      Tribe     = map_chr(classification, extract_rank_local, target_rank = "tribe")
    ) %>%
    select(verbatim_name, name, authorship, Subfamily, Tribe, Genus)
  
  
  non_resolues <- setdiff(species_manquantes, nouvelles_lignes$verbatim_name)
  if (length(non_resolues) > 0) {
    warning(
      "Espèce non résolue par Catalogue of Life : \n",
      paste(paste0("- ", non_resolues), collapse = "\n")
    )
    
    
    lignes_manquees <- tibble(
      verbatim_name = non_resolues,
      name          = NA_character_,
      authorship    = NA_character_,
      Subfamily     = NA_character_,
      Tribe         = NA_character_,
      Genus         = stringr::word(non_resolues, 1)
    )
    nouvelles_lignes <- bind_rows(nouvelles_lignes, lignes_manquees)
  }
  
  ############ Fusion ----
  DB_taxo <- bind_rows(DB_taxo, nouvelles_lignes) %>% 
    distinct(verbatim_name, .keep_all = TRUE)
  
  saveRDS(DB_taxo, chemin_cache)
  message("Cache mis à jour avec succès.")
  
} else {
  message("Aucune nouvelle espèce.")
}