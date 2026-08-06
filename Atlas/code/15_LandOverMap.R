

plot_land_cover_lux <- function(datapath = "Atlas/data/LandCover_Luxembourg_status_2024.tif",
                                agg_fact = 100,  
                                cache_path = "Atlas/data/lc_lux_cache.tif") {
  
  land_cover_colors <- c(
    "10" = "#E40102", "20" = "#FFA902", "30" = "#73DDFE", "60" = "#014DA7",
    "70" = "#267400", "80" = "#37A800", "91" = "#55FF00", "92" = "#FFFF01",
    "93" = "#FF73DE"
  )
  land_cover_labels <- c(
    "10" = "Buildings", "20" = "Other constructed areas", "30" = "Bare soil",
    "60" = "Water", "70" = "Trees", "80" = "Bushes",
    "91" = "Permanent herbaceous vegetation", "92" = "Seasonal herbaceous vegetation",
    "93" = "Vineyards")
  
  if (file.exists(cache_path)) {
    lc_agg <- rast(cache_path)
  } else {
    message("Agrégation en cours (une seule fois)...")
    lc_agg <- aggregate(rast(datapath), fact = agg_fact, fun = "modal")
    writeRaster(lc_agg, cache_path, overwrite = TRUE)
  }
  
  levels(lc_agg) <- data.frame(
    id = as.integer(names(land_cover_labels)),
    Land_Cover = land_cover_labels
  )
  colors_by_label <- setNames(land_cover_colors, land_cover_labels[names(land_cover_colors)])
  
  ggplot() +
    geom_spatraster(data = lc_agg) +
    scale_fill_manual(values = colors_by_label, name = "Land Cover", na.translate = FALSE) +
    annotation_scale(location = "br", width_hint = 0.25, style = "bar", text_cex = 0.7) +
    coord_sf(crs = "EPSG:2169", expand = FALSE) +
    theme_void() +
    theme(panel.background = element_rect(fill = "white", color = NA),
      plot.background  = element_rect(fill = "white", color = NA),legend.position = c(0.98, 0.98),
      legend.justification = c("right", "top"),
      legend.background = element_rect(fill = alpha("white", 0.8), color = "grey70"), legend.title = element_text(face = "bold", size = 10),
      legend.text = element_text(size = 8), legend.key.size = unit(0.4, "cm"))
}

plot_land_cover_lux()