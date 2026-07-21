######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Crée une DB pour avoir la sous famille-tribu-genre de l'espece

############ Filtrage des occurrences certaines ----
DB3$Certainty <- !(DB3$ID == grepl("\\?", DB3$ID, value=TRUE))
sum(DB3$Certainty, na.rm=T)

############ 2. Liste des espèces à traiter ----
species_list <- unlist(unique(DB3[DB3$Certainty,"ID"]))
# une ligne par espèce
DB_taxo <- tibble(ID = species_list)

############ 3. Matching taxonomique (Catalogue of Life) ----


matches <- col_match_checklist(species_list)
# Test exploratoire
test_classif <- rcol::col_classification(matches$usage_id[1])
str(test_classif)   

############ 4. Fonction d'extraction d'un rang taxonomique donné ----
extract_rank <- function(usage_id, target_rank) {
  classif <- rcol::col_classification(usage_id)
  row <- classif %>% filter(tolower(rank) == target_rank)
  if (nrow(row) == 0) return(NA_character_)
  row$name[1]
}

############ 5. Construction DB_taxo ----
DB_taxo <- matches %>%
  filter(!is.na(usage_id)) %>%
  mutate(
    Genus     = word(verbatim_name, 1),
    Subfamily = map_chr(usage_id, extract_rank, target_rank = "subfamily"),
    Tribe     = map_chr(usage_id, extract_rank, target_rank = "tribe")
  ) %>%
  select(verbatim_name, name, authorship, Subfamily, Tribe, Genus)

