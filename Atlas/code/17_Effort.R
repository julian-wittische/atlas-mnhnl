######################## PROJECT: Atlas - Chapitre Spatial analysis
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : calculer et cartographier, par cellule de la grille 5km,
#   l'effort d'échantillonnage (nb de sorties), le nombre d'insectes collectés,
#   le nombre d'espèces, et les ratios associés (insectes/sortie, espèces/sortie)


############ Préparation des labels de pays pour les cartes ---
# coordonnées (EPSG:2169) où afficher le nom des pays voisins sur les cartes statiques
country_labels_cell <- data.frame(
  name = c("FRANCE", "BELGIUM", "GERMANY"),
  x = c(57000, 52000, 90000), 
  y = c(58000, 133000, 120000)   
)

############ Effort d'échantillonnage par cellule ----
# une "sortie" =  combinaison unique Cellule/Station/Date dans HN
# (évite de compter plusieurs fois la même sortie si plusieurs insectes y ont été collectés)
effort_cell <- HN %>%
  distinct(Cell, Station, Date)  %>%
  count(Cell, name = "Nb_sorties") %>%
  arrange(desc(Nb_sorties))

effort_cell

############ Carte de l'effort d'échantillonnage (nb de sorties par cellule) ----
carte_effort_cell <- function(effort_cell, rtp, lux_borders, GR2169_c) {
  # reprojection des fonds de carte
  lux_sf <- st_transform(st_as_sf(lux_borders), 2169)
  rtp_sf <- st_transform(st_as_sf(rtp), 2169)
  # jointure des cellules de la grille avec le nb de sorties
  rtp_join <- rtp_sf %>%
    left_join(effort_cell, by = c("layer" = "Cell"))
  centroids <- st_centroid(rtp_join)
  
  ggplot() +
    geom_sf(data = rtp_join, aes(fill = Nb_sorties), color = "black", linewidth = 0.6) +
    geom_sf_text(data = centroids, aes(label = Nb_sorties), size = 3.5, color = "black") +
    geom_sf(data = lux_sf, fill = NA, color = "black", linewidth = 0.5) +
    geom_sf(data = GR2169_c, fill = NA, color = "grey", linewidth = 0.5) +
    scale_fill_gradient(name = NULL, low = "white", high = "red", na.value = "grey90") +
    geom_text(data = country_labels_cell, aes(x = x, y = y, label = name),
              size = 6, color = "grey40", fontface = "italic") +
    theme_void() +
    annotation_scale(location = "bl", width_hint = 0.2,
                     style = "ticks", text_cex = 1,
                     line_width = 1, height = unit(0.3, "cm"),
                     pad_x = unit(1.7, "cm"), pad_y = unit(2, "cm")) +
    annotation_north_arrow(location = "tr", which_north = "true",
                           style = north_arrow_fancy_orienteering(),
                           height = unit(1.8, "cm"), width = unit(1.8, "cm"),
                           pad_x = unit(2, "cm"), pad_y = unit(2, "cm")) +
    theme(
      legend.position = c(0.80, 0.75),
      legend.justification = c(0, 1))
}


############ Nombre d'observations collectés par cellule et ratio par sortie ----
# nb total de lignes HN (= nb observation) par cellule, hors cellules non renseignées
nb_insectes_cell <- HN %>%
  filter(!is.na(Cell)) %>%
  count(Cell, name = "Nb_insectes")

# ratio insectes/sortie = intensité de capture par sortie
ratio_cell <- nb_insectes_cell %>%
  left_join(effort_cell, by = "Cell") %>%
  mutate(Ratio = Nb_insectes / Nb_sorties) %>%
  arrange(desc(Ratio))

ratio_cell

############ Carte du ratio insectes/sortie par cellule ----
# même structure que carte_effort_cell, mais coloration/label selon Ratio
carte_ratio_cell <- function(ratio_cell, rtp, lux_borders, GR2169_c) {
  
  lux_sf <- st_transform(st_as_sf(lux_borders), 2169)
  rtp_sf <- st_transform(st_as_sf(rtp), 2169)
  
  rtp_join <- rtp_sf %>%
    left_join(ratio_cell, by = c("layer" = "Cell"))
  
  centroids <- st_centroid(rtp_join)
  
  ggplot() +
    geom_sf(data = rtp_join, aes(fill = Ratio), color = "black", linewidth = 0.3) +
    geom_sf_text(data = centroids, aes(label = round(Ratio, 1)), size = 3.5, color = "black") +
    geom_sf(data = lux_sf, fill = NA, color = "black", linewidth = 0.5) +
    geom_sf(data = GR2169_c, fill = NA, color = "grey", linewidth = 0.5) +
    scale_fill_gradient(name = NULL, low = "white", high = "red", na.value = "grey90") +
    geom_text(data = country_labels_cell, aes(x = x, y = y, label = name),
              size = 6, color = "grey40", fontface = "italic") +
    theme_void() +
    annotation_scale(location = "bl", width_hint = 0.2,
                     style = "ticks", text_cex = 1,
                     line_width = 1, height = unit(0.3, "cm"),
                     pad_x = unit(1.7, "cm"), pad_y = unit(2, "cm")) +
    annotation_north_arrow(location = "tr", which_north = "true",
                           style = north_arrow_fancy_orienteering(),
                           height = unit(1.8, "cm"), width = unit(1.8, "cm"),
                           pad_x = unit(2, "cm"), pad_y = unit(2, "cm")) +
    theme(legend.position = c(0.80, 0.75), legend.justification = c(0, 1))
}


############ Nombre d'espèces par cellule et ratio par sortie ----
nb_especes_cell <- HN %>%
  filter(!is.na(Cell)) %>%
  group_by(Cell) %>%
  summarise(Nb_especes = n_distinct(ID))

# ratio espèces/sortie = richesse spécifique normalisée par l'effort
ratio_especes_cell <- nb_especes_cell %>%
  left_join(effort_cell, by = "Cell") %>%
  mutate(Ratio = Nb_especes / Nb_sorties) %>%
  arrange(desc(Ratio))

ratio_especes_cell

############ Carte du ratio espèces/sortie par cellule ----
carte_ratio_especes_cell <- function(ratio_especes_cell, rtp, lux_borders, GR2169_c) {
  
  lux_sf <- st_transform(st_as_sf(lux_borders), 2169)
  rtp_sf <- st_transform(st_as_sf(rtp), 2169)
  
  rtp_join <- rtp_sf %>%
    left_join(ratio_especes_cell, by = c("layer" = "Cell"))
  
  centroids <- st_centroid(rtp_join)
  
  ggplot() +
    geom_sf(data = rtp_join, aes(fill = Ratio), color = "black", linewidth = 0.3) +
    geom_sf_text(data = centroids, aes(label = round(Ratio, 1)), size = 3.5, color = "black") +
    geom_sf(data = lux_sf, fill = NA, color = "black", linewidth = 0.5) +
    geom_sf(data = GR2169_c, fill = NA, color = "grey", linewidth = 0.5) +
    scale_fill_gradient(name = NULL, low = "white", high = "red", na.value = "grey90") +
    geom_text(data = country_labels_cell, aes(x = x, y = y, label = name),
              size = 6, color = "grey40", fontface = "italic") +
    theme_void() +
    annotation_scale(location = "bl", width_hint = 0.2,
                     style = "ticks", text_cex = 1,
                     line_width = 1, height = unit(0.3, "cm"),
                     pad_x = unit(1.7, "cm"), pad_y = unit(2, "cm")) +
    annotation_north_arrow(location = "tr", which_north = "true",
                           style = north_arrow_fancy_orienteering(),
                           height = unit(1.8, "cm"), width = unit(1.8, "cm"),
                           pad_x = unit(2, "cm"), pad_y = unit(2, "cm")) +
    theme(legend.position = c(0.80, 0.75), legend.justification = c(0, 1))
}

