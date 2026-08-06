

communes <- st_read("Atlas/data/communes4326.geojson")
communes_2169 <- st_transform(communes, 2169)


carte_especes_commune <- function(DB, communes_data = communes_2169) {
  
  DB_sf <- st_as_sf(DB, coords = c("Long", "Lat"), crs = 4326) %>%
    st_transform(2169)
  
  richness <- DB_sf %>%
    st_join(communes_data) %>%
    st_drop_geometry() %>%
    group_by(COMMUNE) %>%
    summarise(n = n_distinct(ID), .groups = "drop")
  
  communes_join <- communes_data %>%
    left_join(richness, by = "COMMUNE")
  
  centroids <- st_centroid(communes_join)
  
  ggplot() +
    geom_sf(data = communes_join, aes(fill = n), color = "black", linewidth = 0.3) +
    geom_sf_text(data = centroids, aes(label = n), size = 2.5, color = "black") +
    geom_sf(data = GR2169_c, fill = NA, color = "grey", linewidth = 0.5) +
    scale_fill_gradient(name = NULL, low = "white", high = "red") +
    geom_text(data = country_labels, aes(x = x, y = y, label = name),
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
    theme(legend.position = c(0.76, 0.69), legend.justification = c(0, 1))
    
}

carte_especes_commune(DB)


carte_obs_commune <- function(DB, communes_data = communes_2169) {
  
  DB_sf <- st_as_sf(DB, coords = c("Long", "Lat"), crs = 4326) %>%
    st_transform(2169)
  
  richness <- DB_sf %>%
    st_join(communes_data) %>%
    st_drop_geometry() %>%
    group_by(COMMUNE) %>%
    summarise(n = n(), .groups = "drop")  
  
  communes_join <- communes_data %>%
    left_join(richness, by = "COMMUNE")
  
  centroids <- st_centroid(communes_join)
  
  ggplot() +
    geom_sf(data = communes_join, aes(fill = n), color = "black", linewidth = 0.3) +
    geom_sf_text(data = centroids, aes(label = n), size = 2.5, color = "black") +
    geom_sf(data = GR2169_c, fill = NA, color = "grey", linewidth = 0.5) +
    scale_fill_gradient(name = NULL, low = "white", high = "red") +
    geom_text(data = country_labels, aes(x = x, y = y, label = name),
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
    theme(legend.position = c(0.76, 0.69), legend.justification = c(0, 1))
}

carte_obs_commune(DB)

