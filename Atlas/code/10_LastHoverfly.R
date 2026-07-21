
taxon_id <- content(GET("https://api.inaturalist.org/v1/taxa", query = list(q = "Syrphidae", rank = "family")))$results[[1]]$id

place_id <- content(GET("https://api.inaturalist.org/v1/places/autocomplete",query = list(q = "Luxembourg")))$results[[1]]$id


obs <- content(GET("https://api.inaturalist.org/v1/observations",  query = list(taxon_id = taxon_id, place_id = place_id,  
                                                                                photos = "true", order_by = "created_at",
                                                                                order = "desc", per_page = 1)))$results[[1]]


download.file(sub("square", "large", obs$photos[[1]]$url), "Atlas/last_syrphidae.jpg", mode = "wb")

species <- obs$taxon$name
obs <- cat("Observed the", obs$observed_on, "by", obs$user$login)


