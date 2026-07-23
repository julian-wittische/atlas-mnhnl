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
  
  lux_sf_2169 <- st_transform(st_as_sf(lux_borders), crs = 2169)
  zone_totale <- st_as_sfc(bbox_2169)
  masque_hors_lux <- st_difference(zone_totale, st_union(lux_sf_2169))
  
  ggplot() +
    geom_spatraster(data = bio1_lux) +
    scale_fill_gradientn(
      colours = c("#2C7BB6", "#ABD9E9", "#FFFFBF", "#FDAE61", "#D7191C"),
      name = "°C",
      na.value = NA,
      guide = guide_colorbar(barwidth = 2, barheight = 8)
    ) +
    geom_sf(data = masque_hors_lux, fill = "white", color = NA) +
    geom_sf(data = lux_sf_2169, fill = NA, color = "black", linewidth = 0.4) +
    geom_sf(data = GR2169_c, fill = NA, color = "grey30", linewidth = 0.4) +
    geom_text(data = country_labels, aes(x = x, y = y, label = name),
              size = 6, color = "grey40", fontface = "italic") +
    coord_sf(crs = "EPSG:2169",
             xlim = c(bbox_2169["xmin"], bbox_2169["xmax"]),
             ylim = c(bbox_2169["ymin"], bbox_2169["ymax"]),
             expand = FALSE) +
    theme_void() +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      legend.position = c(0.90, 0.90),
      panel.background = element_rect(fill = "white", color = NA),
      legend.title = element_text(size = 16),     
      legend.text = element_text(size = 13),      
      legend.key.size = unit(1.2, "cm"), 
    )
}

################# carte BIO12 (précipitations annuelles) ----
plot_bio12_map <- function(bioclim_lux, lux_borders) {
  bio12 <- bioclim_lux[["wc2.1_30s_bio_12"]]
  
  lux_borders_wgs84 <- st_transform(st_as_sf(lux_borders), crs = 4326)
  lux_borders_vect <- vect(lux_borders_wgs84)
  
  bio12_lux <- mask(crop(bio12, lux_borders_vect), lux_borders_vect)
  
  lux_sf_2169 <- st_transform(st_as_sf(lux_borders), crs = 2169)
  zone_totale <- st_as_sfc(bbox_2169)
  masque_hors_lux <- st_difference(zone_totale, st_union(lux_sf_2169))
  
  ggplot() +
    geom_spatraster(data = bio12_lux) +
    scale_fill_gradientn(
      colours =  c("white", "#C7E9C0", "#7FCDBB", "#2C7FB8", "#084081"),
      name = "mm",
      na.value = NA,
      guide = guide_colorbar(barwidth = 2, barheight = 8)
    ) +
    geom_sf(data = masque_hors_lux, fill = "white", color = NA) +
    geom_sf(data = lux_sf_2169, fill = NA, color = "black", linewidth = 0.4) +
    geom_sf(data = GR2169_c, fill = NA, color = "grey30", linewidth = 0.4) +
    geom_text(data = country_labels, aes(x = x, y = y, label = name),
              size = 5, color = "grey40", fontface = "italic") +
    coord_sf(crs = "EPSG:2169",
             xlim = c(bbox_2169["xmin"], bbox_2169["xmax"]),
             ylim = c(bbox_2169["ymin"], bbox_2169["ymax"]),
             expand = FALSE) +
    theme_void() +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      legend.position = c(0.90, 0.90),
      panel.background = element_rect(fill = "white", color = NA),
      legend.title = element_text(size = 16),     
      legend.text = element_text(size = 13),      
      legend.key.size = unit(1.2, "cm"), 
    )
}

################# Multiple choices map ----

bio_vars <- data.frame(
  num   = 1:19,
  layer = paste0("wc2.1_30s_bio_", 1:19),
  title = c("Annual Mean Temperature", "Mean Diurnal Temperature Range","Isothermality",
  "Temperature Seasonality", "Maximum Temperature of Warmest Month", "Minimum Temperature of Coldest Month", "Annual Temperature Range",
    "Mean Temperature of Wettest Quarter","Mean Temperature of Driest Quarter", "Mean Temperature of Warmest Quarter", "Mean Temperature of Coldest Quarter",  "Annual Precipitation",
    "Precipitation of Wettest Month", "Precipitation of Driest Month",
    "Precipitation Seasonality", "Precipitation of Wettest Quarter", "Precipitation of Driest Quarter", "Precipitation of Warmest Quarter",
    "Precipitation of Coldest Quarter"
  ),
  unit = c(
    rep("°C", 11),
    rep("mm", 3),
    "Coefficient of Variation",
    rep("mm", 4)
  ),
  stringsAsFactors = FALSE
)



bio_vars$palette <- list(
  
  # Temperature variables (cold → warm)
  c("#2C7BB6", "#ABD9E9", "#FFFFBF", "#FDAE61", "#D7191C"), # BIO1
  c("#4575B4", "#91BFDB", "#FFFFBF", "#FC8D59", "#D73027"), # BIO2
  c("#313695", "#74ADD1", "#FFFFBF", "#FDAE61", "#A50026"), # BIO3
  c("#74ADD1", "#ABD9E9", "#FFFFBF", "#FDAE61", "#D73027"), # BIO4
  c("#2C7BB6", "#ABD9E9", "#FEE090", "#F46D43", "#A50026"), # BIO5
  c("#313695", "#4575B4", "#91BFDB", "#E0F3F8", "#FFFFBF"), # BIO6
  c("#4575B4", "#91BFDB", "#FFFFBF", "#FC8D59", "#D73027"), # BIO7
  c("#2C7BB6", "#ABD9E9", "#FFFFBF", "#FDAE61", "#D7191C"), # BIO8
  c("#2C7BB6", "#ABD9E9", "#FFFFBF", "#FDAE61", "#D7191C"), # BIO9
  c("#2C7BB6", "#ABD9E9", "#FEE090", "#F46D43", "#A50026"), # BIO10
  c("#313695", "#4575B4", "#91BFDB", "#E0F3F8", "#FFFFBF"), #BIO11
  c("white", "#C7E9C0", "#7FCDBB", "#2C7FB8", "#084081"), #BIO12
  c("#F7FCF0", "#C7E9C0", "#7FCDBB", "#2C7FB8", "#084081"), # BIO13
  c("#FFF7BC", "#FEC44F", "#FE9929", "#D95F0E", "#993404"), # BIO14
 c("#F7FCF5", "#C7E9C0", "#74C476", "#238B45", "#00441B"), # BIO1
  c("#F7FCF0", "#C7E9C0", "#7FCDBB", "#2C7FB8", "#084081"), # BIO16
  c("#FFF7BC", "#FEC44F", "#FE9929", "#D95F0E", "#993404"), # BIO17
  c("#FFF7BC", "#FEC44F", "#FE9929", "#D95F0E", "#993404"), # BIO18

  c("#F7FCF0", "#C7E9C0", "#7FCDBB", "#2C7FB8", "#084081"))  # BIO19



plot_bio_map <- function(bioclim_lux, lux_borders, var_num,
                         label_size = 4,
                         legend_title_size = 11,
                         legend_text_size = 9,
                         legend_key_cm = 0.8) {
  
  meta <- bio_vars[bio_vars$num == var_num, ]
  if (nrow(meta) == 0) stop("Invalid BIO variable number: ", var_num)
  
  # Raster layer
  bio_layer <- bioclim_lux[[meta$layer]]
  
  # Luxembourg borders
  lux_sf   <- st_transform(st_as_sf(lux_borders), 2169)
  lux_vect <- vect(st_transform(lux_sf, 4326))
  
  # Crop + mask
  bio_lux <- bio_layer |>
    crop(lux_vect) |>
    mask(lux_vect)
  
  # Mask outside Luxembourg
  zone_totale <- st_as_sfc(bbox_2169)
  masque_hors_lux <- st_difference(zone_totale, st_union(lux_sf))
  
  ggplot() +
    geom_spatraster(data = bio_lux) +
    
    scale_fill_gradientn(
      colours = meta$palette[[1]],
      name = meta$unit,
      na.value = NA,
      guide = guide_colorbar(barwidth = 1, barheight = 5)
    ) +
    
    geom_sf(data = masque_hors_lux, fill = "white", color = NA) +
    geom_sf(data = lux_sf, fill = NA, color = "black", linewidth = 0.4) +
    geom_sf(data = GR2169_c, fill = NA, color = "grey30", linewidth = 0.4) +
    
    geom_text(
      data = country_labels,
      aes(x, y, label = name),
      size = label_size,
      color = "grey40",
      fontface = "italic"
    ) +
    
    coord_sf(
      crs = "EPSG:2169",
      xlim = c(bbox_2169["xmin"], bbox_2169["xmax"]),
      ylim = c(bbox_2169["ymin"], bbox_2169["ymax"]),
      expand = FALSE
    ) +
    
    labs(title = meta$title) +
    
    theme_void() +
    theme(
      plot.title = element_text(
        size = 14,
        face = "bold",
        hjust = 0.5
      ),
      plot.background  = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      plot.margin      = margin(5, 5, 5, 5),
      
      legend.position  = c(0.90, 0.88),
      legend.title     = element_text(size = legend_title_size),
      legend.text      = element_text(size = legend_text_size),
      legend.key.size  = unit(legend_key_cm, "cm")
    )
}
