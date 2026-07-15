######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Interactive map with filters (year/sources)

###### Base map ----

mapviewOptions(fgb = FALSE)  # désactive le format fgb

############ Carte choix (OSM / satellite)
base_map <- leaflet() %>%
  addProviderTiles("OpenStreetMap", group = "OSM") %>%
  addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
  addLayersControl(baseGroups = c("OSM", "Satellite"),
                   options = layersControlOptions(collapsed = FALSE))

############ Superposition de la grille sur la carte

m <- mapView(rtp,
             method = "ngb",
             na.color = rgb(0, 0, 255, max = 255, alpha = 0),
             query.type = "click",
             trim = TRUE,
             legend = FALSE,
             map = base_map,
             alpha.regions = 0,
             alpha = 0.3,
             lwd = 2,
             color = "red")

###### Données d'observation ----

############ Reprojection des observations en WGS84
DB_sf_wgs84 <- st_transform(DB_sf, crs = 4326)

############ Regroupement des années antérieures à 2016
DB_sf_wgs84$YearPost20XX <- DB_sf_wgs84$Year
DB_sf_wgs84$YearPost20XX[DB_sf_wgs84$YearPost20XX < 2016] <- 2016

############ Objet partagé crosstalk 
DB_shared <- SharedData$new(DB_sf_wgs84, group = "lux_group")

############ Ajout des points d'observation
m@map <- m@map %>%
  addCircleMarkers(
    data = DB_shared,
    popup = ~paste0(ID, " (", Source, ", ", YearPost20XX, ")"),
    radius = 1,
    color = "blue",
    fillOpacity = 0.7
  )

###### Adding filters ----

############ Curseur par année
slider <- filter_slider(
  id = "year_filter",
  label = "Year (cumulated observations)",
  sharedData = DB_shared,
  column = ~YearPost20XX,
  step = 1,
  animate = TRUE,
  sep = " ",
  ticks = TRUE,
  width = "10cm"
)

############ Filtre par source de données
source_filter <- filter_checkboxSP(
  id = "source_filter",
  label = "Data sources",
  sharedData = DB_shared,
  group = ~Source,
  inline = TRUE,
  allLevels = FALSE,
  columns = 1
)

###### Assemblage final ----

############ Carte + slider + filtre empilés
carte1 <- bscols(widths = c(12, 12, 12), slider, source_filter, m@map)

