######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Création d'une table des catégories IUCN)




redList <- read_xlsx("data/EuropeanRedList.xlsx", sheet = 1) %>%
  rename(
    European_Category = `European\r\nCategory`,
    European_Criteria  = `European Criteria`,
    European_Endemic   = `European\r\nEndemic`,
    EU27_Category       = `EU27\r\nCategory`,
    EU27_Criteria        = `EU27 Criteria`,
    EU27_Endemic          = `EU27\r\nEndemic`
  ) %>%
  mutate(Species = paste(Genus, Species))

# catégorie IUCN -> nom de fichier image
iucn_img_code <- function(category) {
  category <- str_trim(as.character(category))
  if (is.na(category) || category == "" || category == "NA") {
    return("NE")   
  }
  category
}

# Renvoie les codes image pour une espèce donnée 
get_iucn_status <- function(species_name) {
  row <- redList %>% filter(Species == species_name)
  if (nrow(row) == 0) {
    return(list(europe = "NE", eu27 = "NE"))  # espece absente de la table
  }
  list(
    europe = iucn_img_code(row$European_Category[1]),
    eu27   = iucn_img_code(row$EU27_Category[1])
  )
}

