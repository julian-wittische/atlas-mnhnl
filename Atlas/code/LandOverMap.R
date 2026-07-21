plot_land_cover <- function(datapath,
                            annee = 2024,
                            layer_land_cover = "LandCover_Luxembourg_status_2024",
                            layer_legend = "LandCover_legend",
                            frac_echantillon = 0.05) {
  
  fichier_gdb <- file.path(datapath, "LandCover_Luxembourg_2018_2021_2024.gdb")
  
  land_cover <- sf::st_read(fichier_gdb, layer = layer_land_cover, quiet = TRUE)
  legend <- sf::st_read(fichier_gdb, layer = layer_legend, quiet = TRUE)
  
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
  
  # Préparer les données (mutate AVANT le sample, sinon la colonne factor est absente de l'échantillon)
  land_cover <- land_cover %>%
    dplyr::mutate(
      LC_chr = as.character(.data[[col_annee]]),
      LC_chr = factor(LC_chr, levels = names(land_cover_colors))
    )
  
  land_cover_sample <- land_cover %>%
    dplyr::sample_frac(frac_echantillon)
  
  ggplot2::ggplot(land_cover_sample) +
    ggplot2::geom_sf(ggplot2::aes(fill = LC_chr), color = NA) +
    ggplot2::scale_fill_manual(
      values = land_cover_colors,
      labels = land_cover_labels[levels(land_cover_sample$LC_chr)],
      name = "Land Cover",
      na.translate = FALSE
    ) +
    ggspatial::annotation_scale(
      location = "br",
      width_hint = 0.25,
      style = "bar",
      text_cex = 0.7
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.background  = ggplot2::element_rect(fill = "white", color = NA),
      legend.position = c(0.98, 0.98),
      legend.justification = c("right", "top"),
      legend.background = ggplot2::element_rect(fill = ggplot2::alpha("white", 0.8), color = "grey70"),
      legend.title = ggplot2::element_text(face = "bold", size = 10),
      legend.text = ggplot2::element_text(size = 8),
      legend.key.size = ggplot2::unit(0.4, "cm")
    )
}