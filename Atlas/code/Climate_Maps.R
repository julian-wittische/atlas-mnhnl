######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : 2 cartes : températures et précipitations moyennes par an


################# Données climatiques WorldClim ----
bioclim_lux <- worldclim_country(country = "Luxembourg", var = "bio", res = 0.5, path = tempdir())

################# Frontière nationale du Luxembourg ----
lux_borders <- gb_get_adm0("Luxembourg")
lux_borders <- st_transform(lux_borders, crs = "EPSG:2169")
lux_borders <- as(lux_borders, "Spatial")

################# carte BIO1 (température moyenne annuelle) ----
plot_bio1_map <- function(bioclim_lux, lux_borders) {
  bio1 <- bioclim_lux[["wc2.1_30s_bio_1"]]
  
  lux_borders_wgs84 <- st_transform(st_as_sf(lux_borders), crs = 4326)
  lux_borders_vect <- vect(lux_borders_wgs84)
  
  bio1_lux <- mask(crop(bio1, lux_borders_vect), lux_borders_vect)
  
  ggplot() +
    geom_spatraster(data = bio1_lux) +
    scale_fill_gradientn(
      colours = c("lightblue", "yellow", "red"),
      name = "°C",
      na.value = NA
    ) +
    geom_sf(data = st_as_sf(lux_borders), fill = NA, color = "black", linewidth = 0.4) +
    coord_sf(crs = "EPSG:2169") +
    theme_void() +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      legend.position = c(0.85, 0.79),
      panel.background = element_rect(fill = "white", color = NA),
      plot.title = element_text(hjust = 0, size = 14)
    )
}

################# carte BIO12 (précipitations annuelles) ----
plot_bio12_map <- function(bioclim_lux, lux_borders) {
  bio12 <- bioclim_lux[["wc2.1_30s_bio_12"]]
  
  lux_borders_wgs84 <- st_transform(st_as_sf(lux_borders), crs = 4326)
  lux_borders_vect <- vect(lux_borders_wgs84)
  
  bio12_lux <- mask(crop(bio12, lux_borders_vect), lux_borders_vect)
  
  ggplot() +
    geom_spatraster(data = bio12_lux) +
    scale_fill_gradientn(
      colours = c("lightyellow", "#99F0FA", "#200DBA"),
      name = "mm",
      na.value = NA
    ) +
    geom_sf(data = st_as_sf(lux_borders), fill = NA, color = "black", linewidth = 0.4) +
    coord_sf(crs = "EPSG:2169") +
    theme_void() +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      legend.position = c(0.85, 0.79),
      panel.background = element_rect(fill = "white", color = NA),
      plot.title = element_text(hjust = 0, size = 14)
    )
}

