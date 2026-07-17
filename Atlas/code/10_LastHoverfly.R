library(httr)


taxon_id <- content(GET("https://api.inaturalist.org/v1/taxa", query = list(q = "Syrphidae", rank = "family")))$results[[1]]$id

place_id <- content(GET("https://api.inaturalist.org/v1/places/autocomplete",query = list(q = "Luxembourg")))$results[[1]]$id


obs <- content(GET("https://api.inaturalist.org/v1/observations",  query = list(taxon_id = taxon_id, place_id = place_id,  photos = "true", order_by = "created_at", order = "desc", per_page = 1)))$results[[1]]

cat(obs$taxon$name, "-", obs$observed_on, "-", obs$uri, "\n")

download.file(sub(obs$photos[[1]]$url), "syrphidae.jpg", mode = "wb")
