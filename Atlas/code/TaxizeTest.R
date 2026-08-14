library(taxize)


DB$Certainty <- !(DB$ID == grep("\\?", DB$ID, value=TRUE))
sum(DB3$Certainty, na.rm=T)


species_list <- unlist(unique(DB[DB$Certainty,"ID"]))
taxon <- gna_verifier(species_list , capitalize = TRUE)

# Find synonyms

synonyms("Blera fallax", db ="nbn")
gna_verifier(species_list , capitalize = TRUE)

remotes::install_github("CatalogueOfLife/rcol")

library(rcol)

col_synonyms(col_match("Blera fallax")$usage_id)$label
col_usage((col_match("Blera fallax")$usage_id))
col_vernacular((col_match("Chrysotoxum bicinctum")$usage_id))
