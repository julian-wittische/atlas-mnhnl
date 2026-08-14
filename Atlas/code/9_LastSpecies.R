######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Va chercher les informations de la dernière observation de Inaturalist et génère la photo de l espece

source(here::here("Atlas", "code", "1_config.R"))


# Taxon (famille)
taxon_id <- content(GET("https://api.inaturalist.org/v1/taxa",
                        query = list(q = taxon, rank = "family")))$results[[1]]$id

#  Lieu : Luxembourg
# place_id <- content(GET("https://api.inaturalist.org/v1/places/autocomplete",
#                         query = list(q = "Luxembourg")))$results[[1]]$id

# Il est préférable de mettre manuellement le place_id pour avoir une meilleure précision des frontières
place_id <- 120582 # Grand-Duché de Luxembourg

# Dernière observation avec photo
obs_data <- content(GET("https://api.inaturalist.org/v1/observations",
                        query = list(taxon_id = taxon_id, place_id = place_id,
                                     photos = "true", order_by = "created_at",
                                     order = "desc", per_page = 1, photo_licensed = TRUE)))$results[[1]]

# Téléchargement de la photo (chemin ancré via here::here)
download.file(sub("square", "medium", obs_data$photos[[1]]$url),
              here::here("Atlas", "last_observation.jpg"), mode = "wb")

# Valeurs utilisées dans le .qmd
species <- obs_data$taxon$name

observer <- if (!is.null(obs_data$user$name) && nzchar(obs_data$user$name)) {
  obs_data$user$name} else {
  obs_data$user$login}

obs <- paste("Observed the", obs_data$observed_on, "by", observer)
obs_url <- obs_data$uri

format_license <- function(code) {
  if (is.null(code) || is.na(code) || !nzchar(code)) return(NA_character_)
  code <- tolower(code)
  # cc-xx-xx-... -> CC XX-XX-...
  if (startsWith(code, "cc-")) return(paste0("CC ", toupper(sub("^cc-", "", code))))
  # code inconnu = majuscules
  toupper(code)
}

obs_license <- format_license(obs_data$photos[[1]]$license_code)
