
fichier_gdb <- paste0(DATAPATH, "LandCover_Luxembourg_2018_2021_2024.gdb")
sf::st_layers(fichier_gdb)


land_cover_2024 <- sf::st_read(fichier_gdb, layer = "LandCover_Luxembourg_status_2024")
legend <- sf::st_read(fichier_gdb, layer = "LandCover_legend", quiet = TRUE)

land_cover_sample <- land_cover_2024 %>%
  sample_frac(0.05) 



library(sf)
library(ggplot2)
library(dplyr)

# Mapping code -> nom -> couleur (extrait de ta légende)
land_cover_colors <- c(
  "10" = "#E40102",  # Buildings
  "20" = "#FFA902",  #Other constructed areas
  "30" = "#73DDFE",  # Bare soil
  "60" = "#014DA7",  # Water
  "70" = "#267400",  # Trees
  "80" = "#37A800",  #  Bushes
  "91" = "#55FF00",  # Permanent herbaceous vegetation
  "92" = "#FFFF01", # Seasonal herbaceous vegetation
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

# Préparer les données
land_cover_2024 <- land_cover_2024 %>%
  mutate(LC2024_chr = as.character(LC2024),
         LC2024_chr = factor(LC2024_chr, levels = names(land_cover_colors)))

# Carte
ggplot(land_cover_sample) +
  geom_sf(aes(fill = LC2024_chr), color = NA) +
  scale_fill_manual(
    values = land_cover_colors,
    labels = land_cover_labels[levels(land_cover_2024$LC2024_chr)],
    name = "Land Cover",
    na.translate = FALSE
  ) +
  annotation_scale(
    location = "br",   
    width_hint = 0.25,
    style = "bar",
    text_cex = 0.7
  ) +
  theme_void() +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background  = element_rect(fill = "white", color = NA),
    legend.position = c(0.98, 0.98),
    legend.justification = c("right", "top"),
    legend.background = element_rect(fill = alpha("white", 0.8), color = "grey70"),
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 8),
    legend.key.size = unit(0.4, "cm"))






