library(taxize)


#DB3$Certainty <- 

DB3$Certainty <- !(DB3$ID == grep("\\?", DB3$ID, value=TRUE))
sum(DB3$Certainty, na.rm=T)




species_list <- unlist(unique(DB3[DB3$Certainty,"ID"]))
taxon <- gna_verifier(species_list , capitalize = TRUE)


