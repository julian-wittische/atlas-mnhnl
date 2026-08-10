plot_land_cover_lux_vecteur <- function(land_cover) {
  
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
  
  ggplot(land_cover) +
    geom_sf(aes(fill = Habitat_Dominant), color = NA) +
    scale_fill_manual(values = land_cover_colors, labels = land_cover_labels, name = "Land Cover") +
    annotation_scale(location = "br", width_hint = 0.25, style = "bar", text_cex = 0.7) +
    coord_sf(crs = 2169, expand = FALSE) +
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
plot_land_cover_lux_vecteur(land_cover) 