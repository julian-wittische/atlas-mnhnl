country_labels_cell <- data.frame(
  name = c("FRANCE", "BELGIUM", "GERMANY"),
  x = c(57000, 52000, 90000), 
  y = c(58000, 133000, 120000)   
)




effort_cell <- HN %>%
  distinct(Cell, Station, Date)  %>%
  count(Cell, name = "Nb_sorties") %>%
  arrange(desc(Nb_sorties))

effort_cell



#nb insecte collecté map / par sorties

#nb espece

carte_effort_cell <- function(effort_cell, rtp, lux_borders, GR2169_c) {
  
  lux_sf <- st_transform(st_as_sf(lux_borders), 2169)
  rtp_sf <- st_transform(st_as_sf(rtp), 2169)
  rtp_join <- rtp_sf %>%
    left_join(effort_cell, by = c("layer" = "Cell"))
  centroids <- st_centroid(rtp_join)
  
  ggplot() +
    geom_sf(data = rtp_join, aes(fill = Nb_sorties), color = "black", linewidth = 0.6) +
    geom_sf_text(data = centroids, aes(label = Nb_sorties), size = 3, color = "black") +
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









nb_insectes_cell <- HN %>%
  filter(!is.na(Cell)) %>%
  count(Cell, name = "Nb_insectes")

ratio_cell <- nb_insectes_cell %>%
  left_join(effort_cell, by = "Cell") %>%
  mutate(Ratio = Nb_insectes / Nb_sorties) %>%
  arrange(desc(Ratio))

ratio_cell


carte_ratio_cell <- function(ratio_cell, rtp, lux_borders, GR2169_c) {
  
  lux_sf <- st_transform(st_as_sf(lux_borders), 2169)
  rtp_sf <- st_transform(st_as_sf(rtp), 2169)
  
  rtp_join <- rtp_sf %>%
    left_join(ratio_cell, by = c("layer" = "Cell"))
  
  centroids <- st_centroid(rtp_join)
  
  ggplot() +
    geom_sf(data = rtp_join, aes(fill = Ratio), color = "black", linewidth = 0.3) +
    geom_sf_text(data = centroids, aes(label = round(Ratio, 1)), size = 3, color = "black") +
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





nb_especes_cell <- HN %>%
  filter(!is.na(Cell)) %>%
  group_by(Cell) %>%
  summarise(Nb_especes = n_distinct(ID))

ratio_especes_cell <- nb_especes_cell %>%
  left_join(effort_cell, by = "Cell") %>%
  mutate(Ratio = Nb_especes / Nb_sorties) %>%
  arrange(desc(Ratio))

ratio_especes_cell

carte_ratio_especes_cell <- function(ratio_especes_cell, rtp, lux_borders, GR2169_c) {
  
  lux_sf <- st_transform(st_as_sf(lux_borders), 2169)
  rtp_sf <- st_transform(st_as_sf(rtp), 2169)
  
  rtp_join <- rtp_sf %>%
    left_join(ratio_especes_cell, by = c("layer" = "Cell"))
  
  centroids <- st_centroid(rtp_join)
  
  ggplot() +
    geom_sf(data = rtp_join, aes(fill = Ratio), color = "black", linewidth = 0.3) +
    geom_sf_text(data = centroids, aes(label = round(Ratio, 1)), size = 3, color = "black") +
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

