######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Load geology data and create an interactive maps

source("0_Initialisation.R")

###### Geology data ----

#### Lecture des couches géologiques ----

symbole  <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/1")  # symboles stratigraphiques
uniteGeo <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/6")  # unités géologiques (polygones)
failles  <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/2")  # failles (lignes)
contours <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/3")  # courbes de niveau

#### Reprojection des couches dans le CRS ----
uniteGeo <- st_transform(uniteGeo, crs = st_crs(lux_borders))
contours <- st_transform(contours, crs = st_crs(lux_borders))
failles  <- st_transform(failles,  crs = st_crs(lux_borders))
symbole  <- st_transform(symbole,  crs = st_crs(lux_borders))

###### Geology map ----

#### Carte des unités géologiques + failles en rouge + contours 
m2 <- mapview(uniteGeo, zcol = "CODESTRATUNIT",
              col.regions = colorRampPalette(RColorBrewer::brewer.pal(12, "Set3"))(n_niveaux),
              legend = FALSE, homebutton = FALSE, popup = FALSE) +
  # mapview(contours, color = "#F5F5DC", lwd = 1, legend = FALSE, homebutton = FALSE) +
  mapview(failles, color = "red", lwd = 1, legend = FALSE, homebutton = FALSE)

# Ajout des labels 
m2@map <- m2@map %>%
  addLabelOnlyMarkers(
    data = symbole,
    label = ~ABREVSTRAT,
    group = "Labels",
    labelOptions = labelOptions(
      noHide = TRUE,
      direction = "center",
      textOnly = TRUE,
      style = list("font-size" = "9px", "font-weight" = "bold", "color" = "black")
    )
  ) %>%
  groupOptions("Labels", zoomLevels = 14:52)
