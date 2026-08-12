######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Interactive and static map

############ Base map ----

mapviewOptions(fgb = FALSE)  # désactive le format fgb

############ Carte choix (OSM / satellite) ----
base_map <- leaflet() %>%
  addProviderTiles("OpenStreetMap", group = "OSM") %>%
  addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
  addLayersControl(baseGroups = c("OSM", "Satellite"),
                   options = layersControlOptions(collapsed = FALSE))

############ Superposition de la grille sur la carte ----
m <- mapView(rtp,
             method = "ngb", na.color = rgb(0, 0, 255, max = 255, alpha = 0),
             query.type = "click",
             trim = TRUE,legend = FALSE,
             map = base_map,alpha.regions = 0,
             alpha = 0.3, lwd = 2, color = "red")


############ Données d'observation ----

############ Reprojection des observations en WGS84 ----
DB_sf_wgs84 <- st_transform(DB_sf, crs = 4326)

############ Regroupement des années antérieures à 2016 ----
DB_sf_wgs84$YearPost20XX <- DB_sf_wgs84$Year
DB_sf_wgs84$YearPost20XX[DB_sf_wgs84$YearPost20XX < 2016] <- 2016

############ Objet partagé crosstalk ----
# permet de lier la carte, le curseur annee et le filtre source (memes donnees, meme groupe "lux_group")
DB_shared <- SharedData$new(DB_sf_wgs84, group = "lux_group")

############ Ajout des points d'observation ----
m@map <- m@map %>%
  addCircleMarkers(
    data = DB_shared,
    popup = ~paste0(ID, " (", Source, ", ", YearPost20XX, ")"),
    radius = 1,
    color = "blue",
    fillOpacity = 0.7
  )

############ Adding filters ----
############ Curseur par année ----
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

############ Filtre par source de données ----
source_filter <- filter_checkboxSP(
  id = "source_filter",
  label = "Data sources",
  sharedData = DB_shared,
  group = ~Source,
  inline = TRUE,
  allLevels = FALSE,
  columns = 1
)

############ Assemblage final ----

############ Carte + slider + filtre empilés ----
carte1 <- bscols(widths = c(12, 12, 12), slider, source_filter, m@map)

lux_borders_sf <- st_as_sf(lux_borders)

first_cs_year <- DB_sf %>%
  filter(Source == "Citizen science") %>%
  pull(Year) %>%
  min(na.rm = TRUE)
DB_2169 <- st_transform(DB_sf, crs = 2169)


DB_pre_cs <- DB_2169 %>%
  filter(Year < first_cs_year)



############ Carte statique MNHNL seule, avant le début du citizen science ----


p <- ggplot() +
  geom_sf(data = lux_borders_sf, fill = "white", color = "black", linewidth = 0.3) +
  geom_sf(data = DB_pre_cs, aes(color = Source), size = 1, alpha = 0.7) +
  ggtitle(paste("Avant", first_cs_year)) +
  theme_void() +
  annotation_scale(location = "bl", width_hint = 0.2,
                   style = "ticks", text_cex = 0.6,
                   line_width = 0.5, height = unit(0.2, "cm"),
                   pad_x = unit(0.8, "cm"), pad_y = unit(1, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering(),
                         height = unit(1, "cm"), width = unit(1, "cm"),
                         pad_x = unit(1, "cm"), pad_y = unit(1, "cm")) +
  geom_sf(data = GR2169_c, fill = NA, color = "grey", linewidth = 0.5) +
  geom_text(data = country_labels, aes(x = x, y = y, label = name),
            size = 3, color = "grey40", fontface = "italic") +
  theme_void() +
  theme(legend.position = c(0.7, 0.85),
        legend.background = element_blank(),
        legend.title = element_text(size = 7),
        legend.text = element_text(size = 6),
        legend.key.size = unit(0.35, "cm"),
        legend.spacing.y = unit(0.05, "cm"))
p


############ Carte statique avec données MD, avant 2012 ----

MD_2012 <- MD %>%
  filter(Year < 2012)

MD_sf <- st_as_sf(MD_2012 , coords = c("Long", "Lat"), crs = 4326) %>%
  st_transform(crs = 2169)


MD_carte <- ggplot() +
  geom_sf(data = lux_borders_sf, fill = "white", color = "black", linewidth = 0.3) +
  geom_sf(data = MD_sf, color = "darkred", size = 5, alpha = 0.1) +
  theme_void() +
  annotation_scale(location = "bl", width_hint = 0.2,
                   line_width = 1, height = unit(0.2, "cm"),
                   style = "ticks", text_cex = 1,
                   pad_x = unit(2, "cm"), pad_y = unit(2, "cm")) +
  
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering(),
                         height = unit(1.5, "cm"), width = unit(1.5, "cm"),
                         pad_x = unit(2, "cm"), pad_y = unit(2, "cm")) +
  geom_sf(data = GR2169_c, fill = NA, color = "grey", linewidth = 0.5) +
  geom_text(data = country_labels, aes(x = x, y = y, label = name),
            size = 5, color = "grey40", fontface = "italic") 

MD_carte 

