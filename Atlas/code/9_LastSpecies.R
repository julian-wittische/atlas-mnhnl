######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Va chercher les informations de la dernière observation de Inaturalist et génère la photo de l espece

source(here::here("Atlas", "code", "1_config.R"))


# Taxon (famille)
taxon_id <- content(GET("https://api.inaturalist.org/v1/taxa",
                        query = list(q = taxon, rank = "family")))$results[[1]]$id

# Lieu : Luxembourg
place_id <- content(GET("https://api.inaturalist.org/v1/places/autocomplete",
                        query = list(q = "Luxembourg")))$results[[1]]$id

# Dernière observation avec photo
obs_data <- content(GET("https://api.inaturalist.org/v1/observations",
                        query = list(taxon_id = taxon_id, place_id = place_id,
                                     photos = "true", order_by = "created_at",
                                     order = "desc", per_page = 1)))$results[[1]]

# Téléchargement de la photo (chemin ancré via here::here)
download.file(sub("square", "large", obs_data$photos[[1]]$url),
              here::here("Atlas", "last_observation.jpg"), mode = "wb")

# Valeurs utilisées dans le .qmd
species <- obs_data$taxon$name
obs <- paste("Observed the", obs_data$observed_on, "by", obs_data$user$login)
obs_url <- obs_data$uri
