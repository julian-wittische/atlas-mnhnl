######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : relier habitat (grassland/forest/other) et richesse spécifique
#   via des graphiques ternaires (ggtern) : par cellule puis par observation(buffer 500m)

############ Reprojection des observations dans le système de la grille ----
DB_sf <- st_transform(DB3_sf, st_crs(rtp_sf))


############ Richesse spécifique par cellule (jointure spatiale) ----
richness_par_cellule <- DB_sf %>%
  st_join(rtp_sf, join = st_within) %>%
  st_drop_geometry() %>%
  filter(!is.na(layer)) %>%
  group_by(layer) %>%
  summarise(Richness = n_distinct(ID)) %>%
  rename(CellID = layer)


############ Données d'occupation du sol (rasters Copernicus) ----

# rasters de couverture prairie (Grassland) et de densité de couvert arboré (Tree Cover
# Density), millésime 2024, pour le Luxembourg
grassland <- rast("Atlas/data/Grassland/20240101/CLMS_HRLVLCC_GRA_LU_0.tif")
forest <- rast("Atlas/data/TreeCover/20240101/CLMS_HRLVLCC_TCD_LU_0.tif")

grassland
forest

# vérification de la distribution des valeurs de chaque raster
freq(grassland)
freq(forest)

# le raster forest est un pourcentage  -> binarisé en présence/absence 0/1
forest_binary <- forest > 0 

# reprojection , méthode "near" (plus proche voisin) 
grassland_2169 <- project(grassland, "EPSG:2169", method = "near")  
forest_2169 <- project(forest_binary, "EPSG:2169", method = "near")

rtp_vect <- vect(rtp)

############ Proportion de prairie/forêt par cellule (moyenne du raster sur chaque polygone) ----
grassland_pct <- terra::extract(grassland_2169, rtp_vect, fun = mean, na.rm = TRUE)
forest_pct <- terra::extract(forest_2169, rtp_vect, fun = mean, na.rm = TRUE)
 

############ habitat_richness ----
habitat_richness <- data.frame(CellID = rtp$layer,  Grassland = pmin(grassland_pct[, 2] * 100, 100), Forest = pmin(forest_pct[, 2] * 100, 100)) %>%
  mutate(Other = pmax(100 - Grassland - Forest, 0),
          total = Grassland + Forest + Other, Habitat_A = Grassland / total * 100,
          Habitat_B = Forest / total * 100,   Habitat_C = Other / total * 100) %>%
  select(CellID, Habitat_A, Habitat_B, Habitat_C) %>%
  left_join(richness_par_cellule, by = "CellID")

############ Ternary plot : habitat vs richesse par cellule ----
ggtern(data = habitat_richness, aes(x = Habitat_A, y = Habitat_B, z = Habitat_C)) +
  geom_point(size = 3, alpha = 0.5, aes(colour = Richness)) +
  labs(x = "Grassland (%)", y = "Forest (%)", z = "Other (%)", colour = "Species richness") +
  scale_colour_viridis(option = "plasma", begin = 0, end = 0.95) +
  theme_bw() + theme_showarrows() +
  theme(tern.axis.title.T = element_blank(), tern.axis.title.L = element_blank(),tern.axis.title.R = element_blank(),
    tern.axis.arrow = element_blank(),legend.title = element_text(size = 12),legend.text = element_text(size = 10), tern.axis.arrow.text.T = element_text(size = 10),
    tern.axis.arrow.text.L = element_text(size = 10), tern.axis.arrow.text.R = element_text(size = 10)
  )


############ Même logique par observation (buffer 500m autour de chaque point) ----
# on calcule l'habitat autour de chaque observation, via un buffer de 500m
DB <- DB %>% mutate(.obs_row_id = row_number())
obs_vect_2169 <- vect(DB, geom = c("Long", "Lat"), crs = "EPSG:4326") %>%
  project("EPSG:2169")
obs_buffer <- buffer(obs_vect_2169, width = 500)

grassland_pct <- terra::extract(grassland_2169, obs_buffer, fun = mean, na.rm = TRUE)[, 2]
forest_pct    <- terra::extract(forest_2169, obs_buffer, fun = mean, na.rm = TRUE)[, 2]

habitat_par_observation_df <- DB %>%
  mutate(
    Grassland = pmin(grassland_pct * 100, 100),
    Forest    = pmin(forest_pct * 100, 100),
    Other     = pmax(100 - Grassland - Forest, 0),
    total     = Grassland + Forest + Other,
    Habitat_A = Grassland / total * 100,
    Habitat_B = Forest / total * 100,
    Habitat_C = Other / total * 100
  ) %>%
  select(.obs_row_id, Species = ID, Habitat_A, Habitat_B, Habitat_C)

############ Ternary plot par espèce : habitat autour des observations d'une espèce ----
# un point = une observation
plot_habitat_ternaire <- function(espece, data = habitat_par_observation_df) {
  df_espece <- data %>% filter(Species == espece)
  if (nrow(df_espece) == 0) {
    stop(paste("Espèce non trouvée:", espece))
  }
  ggtern(data = df_espece, aes(x = Habitat_A, y = Habitat_B, z = Habitat_C)) +
    geom_point(size = 3, alpha = 0.6, color = "#E40102") +
    labs(title = paste("Habitats ternaires —", espece, 
                       "(n =", nrow(df_espece), "obs)"),
         x = "Grassland (%)", y = "Forest (%)", z = "Other (%)") +
    theme_bw() + theme_showarrows() +
    theme(
      tern.axis.title.T = element_blank(), 
      tern.axis.title.L = element_blank(), 
      tern.axis.title.R = element_blank(),
      tern.axis.arrow = element_blank(),
      legend.title = element_text(size = 12), 
      legend.text = element_text(size = 10),
      tern.axis.arrow.text.T = element_text(size = 10), 
      tern.axis.arrow.text.L = element_text(size = 10), 
      tern.axis.arrow.text.R = element_text(size = 10),
      plot.title = element_text(face = "bold", size = 14)
    )
}

############ Essais sur quelques espèces ----
plot_habitat_ternaire("Volucella zonaria")
plot_habitat_ternaire("Myathropa florea")
plot_habitat_ternaire("Blera fallax")

#######################################################################

############ Variante avec land cover vectoriel ----
# lc <- st_read("Atlas/data/LandCover_Luxembourg_2018_2021_2024.gdb",
#               layer = "LandCover_Luxembourg_2018_2021_2024") %>%
#   st_transform(2169) %>%
#   mutate(HabitatClass = case_when(
#     LC2024 %in% c("70", "80")       ~ "Forest",
#     LC2024 %in% c("91", "92", "93") ~ "Grassland",
#     LC2024 %in% c("10", "20", "30", "60") ~ "Other",
#     TRUE ~ NA_character_
#   )) %>%
#   filter(!is.na(HabitatClass)) %>%
#   select(HabitatClass)

############ Nouveaux buffers 500m ----
obs_buffer_lc <- DB %>%
  mutate(obs_id = row_number()) %>%
  st_as_sf(coords = c("Long", "Lat"), crs = 4326) %>%
  st_transform(2169) %>%
  st_buffer(dist = 500)


############ Proportion de chaque classe d'habitat (vectoriel) par observation ----

habitat_par_observation <- st_intersection(obs_buffer_lc, lc) %>%
  mutate(area = as.numeric(st_area(geometry))) %>% # aire
  st_drop_geometry() %>%
  group_by(obs_id, ID, HabitatClass) %>% # groupe par observation + classe
  summarise(area = sum(area), .groups = "drop") %>%  # fusion
  group_by(obs_id, ID) %>%
  mutate(pct = area / sum(area) * 100) %>% #% /observation
  ungroup() %>%
  select(obs_id, ID, HabitatClass, pct) %>%
  pivot_wider(names_from = HabitatClass, values_from = pct, values_fill = 0) # une colonne par classe

############ Ternary plot  ----
plot_habitat_ternaire_lc <- function(espece, data = habitat_par_observation) {
  
  df_espece <- data %>% filter(ID == espece)
  
  if (nrow(df_espece) == 0) {
    stop(paste("Espèce non trouvée:", espece))
  }
  
  ggtern(data = df_espece, aes(x = Grassland, y = Forest, z = Other)) +
    geom_point(size = 3, alpha = 0.6, color = "#E40102") +
    labs(title = paste("Habitats ternaires (land cover) —", espece,
                       "(n =", nrow(df_espece), "obs)"),
         x = "Grassland (%)", y = "Forest (%)", z = "Other (%)") +
    theme_bw() + theme_showarrows() +
    theme(
      tern.axis.title.T = element_blank(),
      tern.axis.title.L = element_blank(),
      tern.axis.title.R = element_blank(),
      tern.axis.arrow = element_blank(),
      legend.title = element_text(size = 12),
      legend.text = element_text(size = 10),
      tern.axis.arrow.text.T = element_text(size = 10),
      tern.axis.arrow.text.L = element_text(size = 10),
      tern.axis.arrow.text.R = element_text(size = 10),
      plot.title = element_text(face = "bold", size = 14)
    )
}

# plot_habitat_ternaire_lc("Volucella zonaria")











