######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Arbre avec taxonomie


###### Liste des espèces ----
species <- unique(DB3$ID)

###### Catalogue of Life ----
matches <- col_match_checklist(species)


###### Fonction d'extraction du rang taxonomique ----
extract_rank <- function(id, rank) {
  if (is.na(id)) return(NA_character_)
  x <- tryCatch(
    rcol::col_classification(id),
    error = function(e) NULL )
  if (is.null(x) || !"rank" %in% names(x)) return(NA_character_)
  x %>%
    filter(tolower(rank) == !!rank) %>%
    pull(name) %>%
    first()
}


###### Création de la table pour l'arbre taxonomique ----
tree_data <- matches %>%
  filter(!is.na(usage_id)) %>%
  mutate(Genus = word(str_replace(verbatim_name, "_", " "), 1),Subfamily = map_chr(usage_id, extract_rank, "subfamily"), Tribe = map_chr(usage_id, extract_rank, "tribe") ) %>%
  select(Subfamily,Tribe, Genus, name) %>%
  mutate(across(everything(), ~replace_na(as.character(.), "Unknown")) ) %>%
  distinct()


###### Arbre taxonomique ----
collapsibleTree(tree_data,hierarchy = c("Subfamily", "Tribe", "Genus", "name"),root = "Syrphidae",collapsed = TRUE,zoomable = TRUE,height = 1500, width = "100%", fontSize = 12,linkLength = 400
)

