

# Vecteur

pts_sf <- st_as_sf(DB, coords = c("Long", "Lat"), crs = 4326) %>%
  st_transform(2169) %>%
  mutate(point_id = row_number())

buffers <- st_buffer(pts_sf, 500)

land_cover <- st_read("Atlas/data/LandCover_Luxembourg_2018_2021_2024.gdb",
                      layer = "LandCover_Luxembourg_status_2024", quiet = TRUE)


#object avec les points saqns le buffer

land_cover <- land_cover %>%
  st_transform(2169) %>%
  st_make_valid() %>%
  mutate(Habitat_Dominant = case_when(
    LC2024 %in% c(10, 20)      ~ "Built",
    LC2024 %in% c(70, 80)      ~ "Forest",
    LC2024 %in% c(91, 92, 93)  ~ "Herbaceous",
    LC2024 == 30                ~ "Bare soil",
    LC2024 == 60                ~ "Water"
  )) %>%
  filter(!is.na(Habitat_Dominant)) %>%
  select(Habitat_Dominant)  # %>%
 # st_simplify(dTolerance = 10, preserveTopology = TRUE) # reduire le nombre de vecteurs

DB_landcover_vecteur <- st_join(buffers, land_cover, largest = TRUE) %>%
  st_drop_geometry()



# Raster
pts_sf <- st_as_sf(DB, coords = c("Long", "Lat"), crs = 4326) %>%
  st_transform(2169) %>%
  mutate(point_id = row_number())

buffers <- st_buffer(pts_sf, 500)

lc_raster <- rast("Atlas/data/LandCover_Luxembourg_status_2024.tif") # %>%
  # terra::aggregate(fact = 50, fun = "modal")

lc_values <- terra::extract(lc_raster, vect(buffers), fun = "modal") %>%
  rename(point_id = ID)    # extrait la classe majeure du radius choisi

recode_lc <- function(x) {
  case_when(
    x %in% c(10, 20)      ~ "Built",
    x %in% c(70, 80)      ~ "Forest",
    x %in% c(91, 92, 93)  ~ "Herbaceous",
    x == 30               ~ "Bare soil",
    x == 60                ~ "Water",
    TRUE                  ~ NA_character_
  )
}

DB_landcover_raster <- pts_sf %>%
  st_drop_geometry() %>%
  left_join(lc_values %>% mutate(Habitat_Dominant = recode_lc(LandCover_Luxembourg_status_2024)),
            by = "point_id")





plot_habitat_espece <- function(espece, data) {
  lc_colors <- c("Built" = "#E40102", "Forest" = "#267400", "Herbaceous" = "#55FF00",
                 "Bare soil" = "#73DDFE", "Water" = "#014DA7")
  df <- data %>%
    filter(ID == espece) %>%
    count(Habitat_Dominant, name = "n") %>%
    mutate(espece = espece, pct = 100 * n / sum(n))
  ggplot(df, aes(x = espece, y = pct, fill = Habitat_Dominant)) +
    geom_col(width = 0.6, color = "black", linewidth = 0.8) +
    geom_text(aes(label = paste0(round(pct), "%")), position = position_stack(vjust = 0.5),
              size = 4, fontface = "bold", color = "black") +
    coord_flip() +
    scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 10), expand = c(0, 0)) +
    scale_fill_manual(values = lc_colors) +
    labs(title = paste("Habitats (land cover 500 m) —", espece), x = NULL, y = NULL, fill = NULL) +
    theme_minimal(base_size = 13) +
    theme(plot.title = element_text(face = "bold", size = 15, margin = margin(b = 14)),
          axis.text.y = element_blank(), axis.text.x = element_text(size = 10))
}

plot_habitat_espece("Volucella zonaria", data = DB_landcover_vecteur)
plot_habitat_espece("Volucella zonaria", data = DB_landcover_raster)
