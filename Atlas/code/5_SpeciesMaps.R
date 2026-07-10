######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : cartes par espèce et carte de richesse spécifique


###### Species Account Map ----

############ Sélection des observations pour une espèce donnée (ici Blera fallax)
DB2s <- DB2[which(DB2$ID == "Blera fallax"),]

############ Grille de cellules reprojetée en WGS84 (pour affichage leaflet)
rtp_wgs84 <- st_transform(rtp_sf, 4326)

# Precense in one cell
############ Liste des cellules où l'espèce a été observée au moins une fois
presence_cell <- unique(DB2s$Cell)
rtp_presence <- subset(rtp_wgs84, layer %in% presence_cell)

############ Conversion des observations ponctuelles en objet sf (coordonnées -> géométrie point)
DB_sf <- st_as_sf(DB2s, coords = c("Long", "Lat"), crs = 4326)

# Data sources summary per cell
############ Nombre d'observations par cellule et par source
source_cell <- DB2s |>
  group_by(Cell, Source) |>
  summarise(
    Number = n(),
    .groups = "drop"
  )

############ Résumé texte HTML des sources par cellule (pour affichage dans le popup)
source_summary <- source_cell |>
  group_by(Cell) |>
  summarise(
    Source_summary = paste0(Source, ": ", Number, collapse = "<br>"),
    .groups = "drop"
  )

# Observations per cell
############ Nombre total d'observations par cellule (toutes sources confondues)
obs_cell <- DB2s |>
  group_by(Cell) |>
  summarise(Observation = n(),
            .groups = "drop")

# rtp presence
############ Fusion des infos (nb d'observations + résumé des sources) dans la grille de présence
rtp_presence <- merge(
  rtp_presence,
  obs_cell,
  by.x = "layer",
  by.y = "Cell"
)
rtp_presence <- merge(
  rtp_presence,
  source_summary,
  by.x = "layer",
  by.y = "Cell"
)

############ Carte à 3 couches : grille complète (Grid) + cellules avec présence (Cells) + points d'observation (Points)
m3 <- mapView(
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
    col.regions = col_presence,
    alpha.regions = 0.5,
    lwd = 1,
    label = rtp_presence$layer,
    legend = FALSE,
    popup = paste0(
      rtp_presence$Observation,
      " records<br>", "<br>",
      rtp_presence$Source_summary
    ),
    layer.name = "Cells"
  ) +
  
  mapView(
    DB_sf,
    col.regions = "red",
    color = "red",
    cex = 4,
    legend = FALSE,
    layer.name = "Points",
    alpha.regions = 1,
    popup = paste0("<strong>Source : ", DB2s$Source, "<br>"
                   # , "Identifier : ", DB2$ID
    )
  )

############ Affichage conditionnel par zoom : cellules visibles en vue large, points au zoom rapproché
m3@map <- m3@map %>%
  groupOptions("Cells", zoomLevels = 0:11) %>%
  groupOptions("Points", zoomLevels = 12:52)

m3

###### Species Richness Map ----

############ Toutes les observations (toutes espèces confondues)
DB_rich <- DB2

# nb species + species list per cell
############ Richesse spécifique par cellule : nombre d'espèces distinctes + liste des noms
richness_cell <- DB_rich |>
  group_by(Cell) |>
  summarise(Richness = n_distinct(ID), Species_list = paste(unique(ID), collapse = "<br>"),
            .groups = "drop")

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

rtp_centroid

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