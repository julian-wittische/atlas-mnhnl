plot_land_cover <- function(datapath,
                            annee = 2024,
                            layer_land_cover = "LandCover_Luxembourg_status_2024",
                            layer_legend = "LandCover_legend",
                            frac_echantillon = 0.05) {
  
  fichier_gdb <- file.path(datapath, "LandCover_Luxembourg_2018_2021_2024.gdb")
  
  land_cover <- st_read(fichier_gdb, layer = layer_land_cover, quiet = TRUE)
  legend <- st_read(fichier_gdb, layer = layer_legend, quiet = TRUE)
  
  land_cover_colors <- c(
    "10" = "#E40102",  # Buildings
    "20" = "#FFA902",  # Other constructed areas
    "30" = "#73DDFE",  # Bare soil
    "60" = "#014DA7",  # Water
    "70" = "#267400",  # Trees
    "80" = "#37A800",  # Bushes
    "91" = "#55FF00",  # Permanent herbaceous vegetation
    "92" = "#FFFF01",  # Seasonal herbaceous vegetation
    "93" = "#FF73DE"   # Vineyards
  )
  
  land_cover_labels <- c(
    "10" = "Buildings",
    "20" = "Other constructed areas",
    "30" = "Bare soil",
    "60" = "Water",
    "70" = "Trees",
    "80" = "Bushes",
    "91" = "Permanent herbaceous vegetation",
    "92" = "Seasonal herbaceous vegetation",
    "93" = "Vineyards"
  )
  
  col_annee <- paste0("LC", annee)
  
  land_cover_lux <- st_intersection(land_cover, st_geometry(lux_borders_sf))

  land_cover_lux <- land_cover_lux %>%
    mutate(
      LC_chr = as.character(.data[[col_annee]]),
      LC_chr = factor(LC_chr, levels = names(land_cover_colors))
    )
  
  land_cover_sample <- land_cover_lux %>%
    sample_frac(frac_echantillon)
  
  ggplot() +
    geom_sf(data = land_cover_sample, aes(fill = LC_chr), color = NA) +
    scale_fill_manual(
      values = land_cover_colors,
      labels = land_cover_labels[levels(land_cover_sample$LC_chr)],
      name = "Land Cover",
      na.translate = FALSE
    ) +
    geom_sf(data = GR2169_c, fill = NA, color = "grey30", linewidth = 0.4) +
    geom_text(data = country_labels, aes(x = x, y = y, label = name),
              size = 3, color = "grey40", fontface = "italic") +
    annotation_scale(
      location = "br",
      width_hint = 0.25,
      style = "bar",
      text_cex = 0.7
    ) +
    coord_sf(crs = "EPSG:2169",
             xlim = c(bbox_2169["xmin"], bbox_2169["xmax"]),
             ylim = c(bbox_2169["ymin"], bbox_2169["ymax"]),
             expand = FALSE) +
    theme_void() +
    theme(
      panel.background = element_rect(fill = "white", color = NA),
      plot.background  = element_rect(fill = "white", color = NA),
      legend.position = c(0.98, 0.98),
      legend.justification = c("right", "top"),
      legend.background = element_rect(fill = alpha("white", 0.8), color = "grey70"),
      legend.title = element_text(face = "bold", size = 10),
      legend.text = element_text(size = 8),
      legend.key.size = unit(0.4, "cm")
    )
}
