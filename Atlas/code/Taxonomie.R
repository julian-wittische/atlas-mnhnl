######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Crée une DB pour avoir la sous famille-tribu-genre de l'espece

############ Filtrage  ----
DB3$Certainty <- !grepl("\\?", DB3$ID)
sum(DB3$Certainty, na.rm = TRUE)

############ espèces à traiter ----
species_list <- unlist(unique(DB3[DB3$Certainty, "ID"]))
# une ligne par espèce
DB_taxo <- tibble(ID = species_list)

############ Catalogue of Life ----
matches <- col_match_checklist(species_list)
# Test exploratoire
test_classif <- rcol::col_classification(matches$usage_id[1])
str(test_classif)

############ extraction d'un rang taxonomique donné ----
extract_rank <- function(usage_id, target_rank) {
  if (is.na(usage_id)) return(NA_character_)
  classif <- tryCatch(rcol::col_classification(usage_id), error = function(e) NULL)
  if (is.null(classif) || !is.data.frame(classif) || !"rank" %in% names(classif)) {
    return(NA_character_)
  }
  row <- classif %>% filter(tolower(rank) == target_rank)
  if (nrow(row) == 0) return(NA_character_)
  row$name[1]
}

############ DB_taxo ----
DB_taxo <- matches %>%
  filter(!is.na(usage_id)) %>%
  mutate(
    Genus     = word(verbatim_name, 1),
    Subfamily = map_chr(usage_id, extract_rank, target_rank = "subfamily"),
    Tribe     = map_chr(usage_id, extract_rank, target_rank = "tribe")
  ) %>%
  select(verbatim_name, name, authorship, Subfamily, Tribe, Genus)
