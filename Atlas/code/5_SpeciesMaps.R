######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : cartes par espèce et carte de richesse spécifique

###### Données ----

build_master_dataset <- function(BC, HN, MD, rtp) {
  
  ## Bycatch (deja charge par 3_LoadData.R, pas de re-lecture) ---
  bycatch <- BC
  bycatch$Observateur <- bycatch$Collecteur
  bycatch$Identifieur <- bycatch$IDENTIFIER
  bycatch$Origin      <- bycatch$Source
  bycatch$URL         <- NA_character_
  colnames(bycatch)[colnames(bycatch) == "Année"] <- "Year"
  
  ## Hand netting (deja charge) ---
  handnetting <- HN
  handnetting$Observateur <- handnetting$Collecteur
  handnetting$Identifieur <- handnetting$IDENTIFIER
  handnetting$Origin      <- handnetting$Source
  handnetting$URL         <- NA_character_
  colnames(handnetting)[colnames(handnetting) == "Année"] <- "Year"
  
  ## MNHNL (deja charge) ---
  mnhnl <- MD
  mnhnl$ID          <- mnhnl$preferred
  mnhnl$Observateur <- mnhnl$Recorders
  mnhnl$Identifieur <- mnhnl$Determiner
  mnhnl$Origin <- ifelse(
    startsWith(mnhnl$Observation_Key, "INAT_"), "Inaturalist",
    ifelse(startsWith(mnhnl$Observation_Key, "oOrg_"), "Observation.org", "MNHNL"))
  mnhnl$URL <- ifelse(
    mnhnl$Origin == "Inaturalist",
    paste0("https://www.inaturalist.org/observations/", sub("^INAT_", "", mnhnl$Observation_Key)),
    ifelse(
      mnhnl$Origin == "Observation.org",
      paste0("https://observation.org/observation/", sub("^oOrg_", "", mnhnl$Observation_Key), "/"),
      NA_character_))
  
  ## Assemblage (identique a avant) ---
  cols_keep <- c("Latitude", "Longitude", "ID", "Source", "Origin", "Year", "Date", "Observateur", "Identifieur", "URL")
  master_data <- rbind(bycatch[, cols_keep], handnetting[, cols_keep])
  colnames(master_data)[1:2] <- c("Lat", "Long")
  mnhnl_subset <- mnhnl[, c("Lat", "Long", "ID", "Source", "Origin", "Year", "Date", "Observateur", "Identifieur", "URL")]
  master_data <- rbind(master_data, mnhnl_subset)
  
  master_data[(master_data$Origin %in% c("Inaturalist", "Observation.org")), "Source"] <- "Citizen science"
  master_data[!(master_data$Source %in% c("Citizen science", "Hand netting", "Malaise traps", "Pan traps")), "Source"] <- "MNHNL"
  
  master_data <- master_data[c(-517), ] # problematic WBA sample
  
  master_data$Long <- as.numeric(master_data$Long)
  master_data$Lat  <- as.numeric(master_data$Lat)
  master_data$Year <- as.numeric(master_data$Year)
  
  master_data <- master_data[complete.cases(master_data[, c("Long", "Lat", "Year")]), ]
  
  ## la grille ---
  master_sf <- st_as_sf(master_data, coords = c("Long", "Lat"), crs = 4326, remove = FALSE)
  rtp_sf    <- st_as_sf(rtp)
  rtp_sf    <- st_transform(rtp_sf, st_crs(master_sf))
  master_sf <- st_join(master_sf, rtp_sf)
  master_data$Cell <- master_sf$layer
  master_data
}

DB4 <- build_master_dataset(BC, HN, MD, rtp)






######  carte par espèce ----
get_species_map <- function(species_name, data, rtp, base_map) {
  
  ## Sélection des observations 
  species_obs <- data[which(data$ID == species_name), ]
  species_obs <- species_obs[species_obs$Long >= 5 & species_obs$Long <= 7 &
                               species_obs$Lat >= 49 & species_obs$Lat <= 51, ]
  
  ## Grille de cells
  rtp_sf     <- st_as_sf(rtp)
  rtp_wgs84  <- st_transform(rtp_sf, 4326)
  
  ## Cellules espèce observée au moins une fois
  presence_cells <- unique(species_obs$Cell)
  rtp_presence   <- subset(rtp_wgs84, layer %in% presence_cells)
  
  ## Observations ponctuelles en objet sf
  species_sf <- st_as_sf(species_obs, coords = c("Long", "Lat"), crs = 4326)
  
  ## Résumé des sources par cellule
  source_by_cell <- species_obs |>
    group_by(Cell, Source) |>
    summarise(Number = n(), .groups = "drop")
  
  source_summary_by_cell <- source_by_cell |>
    group_by(Cell) |>
    summarise(
      Source_summary = paste0(Source, ": ", Number, collapse = "<br>"),
      .groups = "drop"
    )
  
  obs_count_by_cell <- species_obs |>
    group_by(Cell) |>
    summarise(Observation = n(), .groups = "drop")
  
  rtp_presence <- merge(rtp_presence, obs_count_by_cell, by.x = "layer", by.y = "Cell")
  rtp_presence <- merge(rtp_presence, source_summary_by_cell, by.x = "layer", by.y = "Cell")
  
  ## grille + cellules + points
  species_map <- mapView(
    rtp,
    method = "ngb",
    na.color = rgb(0, 0, 255, max = 255, alpha = 0),
    query.type = "click",
    trim = TRUE,
    legend = FALSE,
    map = base_map,
    popup = FALSE,
    alpha.regions = 0,
    alpha = 0.3,
    lwd = 2,
    color = "red",
    layer.name = "Grid"
  ) +
    
    mapView(
      rtp_presence,
      color = "red",
      col.regions = "red",
      alpha.regions = 0.5,
      lwd = 1,
      label = rtp_presence$layer,
      legend = FALSE,
      popup = paste0(
        rtp_presence$Observation, " records<br>", "<br>",
        rtp_presence$Source_summary
      ),
      layer.name = "Cells"
    ) +
    
    mapView(
      species_sf,
      col.regions = "red",
      color = "red",
      cex = 4,
      legend = FALSE,
      layer.name = "Points",
      alpha.regions = 1,
      popup = paste0(
        "<strong>Source : </strong>", species_obs$Source, "<br>",
        "<strong>Date : </strong>", format(species_obs$Date, "%d/%m/%Y"), "<br>",
        "<strong>Observateur : </strong>", ifelse(is.na(species_obs$Observateur), "Inconnu", species_obs$Observateur), "<br>",
        "<strong>Identifier : </strong>", ifelse(is.na(species_obs$Identifieur), "Inconnu", species_obs$Observateur), "<br>",
        ifelse(
          species_obs$Origin == "Inaturalist" & !is.na(species_obs$URL),
          paste0("<br><a href='", species_obs$URL, "' target='_blank'>Voir sur iNaturalist</a>"),
          ""
        ),
        ifelse(
          species_obs$Origin == "Observation.org" & !is.na(species_obs$URL),
          paste0("<br><a href='", species_obs$URL, "' target='_blank'>Voir sur Observation.org</a>"),
          ""
        )
      )
    )
  
  ## Affichage par zoom 
  species_map@map <- species_map@map %>%
    groupOptions("Cells", zoomLevels = 0:11) %>%
    groupOptions("Points", zoomLevels = 12:52)
  
  species_map
}



###### Species Richness Map ----

get_richness_map <- function(data = DB2) {
  
  ############ Toutes les observations (toutes espèces confondues)
  DB_rich <- data
  
  # nb species + species list per cell
  ############ Richesse spécifique par cellule : nombre d'espèces distinctes + liste des noms
  richness_cell <- DB_rich |>
    group_by(Cell) |>
    summarise(Richness = n_distinct(ID), Species_list = paste(unique(ID), collapse = "<br>"),
              .groups = "drop")
  
  ############ Grille de cellules reprojetée en WGS84 (pour affichage leaflet)
  rtp_sf <- st_as_sf(rtp)           
  rtp_wgs84 <- st_transform(rtp_sf, 4326) 
  
  # subset cell
  ############ Cellules concernées par au moins une observation
  rtp_richness <- subset(rtp_wgs84, layer %in% richness_cell$Cell)
  
  # info grid
  ############ Fusion des infos de richesse dans la grille, puis calcul des centroïdes (pour les labels)
  rtp_richness <- merge(rtp_richness, richness_cell, by.x = "layer", by.y = "Cell")
  rtp_centroid <- st_centroid(rtp_richness[, c("layer", "Richness")])
  
  # map
  ############ Carte de richesse : grille complète (Grid) + dégradé blanc-orange-rouge selon le nombre d'espèces
  m4 <- mapView(
    rtp,
    layer.name = "Grid",
    method = "ngb",
    na.color = rgb(0, 0, 255, max = 255, alpha = 0),
    query.type = "click",
    trim = TRUE,
    legend = FALSE,
    map = base_map,
    popup = FALSE,
    alpha.regions = 0,
    alpha = 0.3,
    lwd = 2
  ) +
    
    mapView(
      rtp_richness,
      label = rtp_richness$layer,
      zcol = "Richness",
      col.regions = colorRampPalette(
        c("white", "orange", "red")
      )(50),
      alpha.regions = 0.7,
      lwd = 1,
      legend = TRUE,
      popup = paste0(
        rtp_richness$Species_list),
      layer.name = "Number of species recorded")
  
  ############ Ajout des labels numériques (richesse) au centre de chaque cellule
  m4@map <- m4@map %>%
    addLabelOnlyMarkers(
      data = rtp_centroid,
      label = ~Richness,
      group = "Labels",
      labelOptions = labelOptions(
        noHide = TRUE,
        direction = "center",
        textOnly = TRUE,
        style = list("font-size" = "18px", "font-weight" = "bold", "color" = "black")
      ))
  
  m4
}

