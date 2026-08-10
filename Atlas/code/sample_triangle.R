# 
# 
# ## FG CORRELATIONS ----
# 
# # Keep one line with all covers values per functional group 
# dom.fg2 <- itex.dec22 %>% distinct(SiteSubsitePlot, .keep_all = TRUE)
# 
# # Shrub vs Graminoid
# shrub.gram.mod <- brm(PlotGraminoidMean ~ PlotShrubMean, 
#                       data = dom.fg2, iter = 2000, chains = 4, warmup = 400, 
#                       file = "smodels/shrub_gram_mod")
# summary(shrub.gram.mod) # negative significant: more shrubs, less grams. More grams, less shrubs
# 
# # Shrub vs Forb
# shrub.forb.mod <- brm(PlotForbMean ~ PlotShrubMean, 
#                       data = dom.fg2, iter = 2000, chains = 4, warmup = 400, 
#                       file = "models/shrub_forb_mod")
# summary(shrub.forb.mod) # negative significant: more shrubs, less forbs. More forbs, less shrubs.
# 
# # Forb vs Graminoid
# gram.forb.mod <- brm(PlotGraminoidMean ~ PlotForbMean, 
#                      data = dom.fg2, iter = 2000, chains = 4, warmup = 400, 
#                      file = "models/gram_forb_mod")
# summary(gram.forb.mod) # negative significant: more grams, less forbs - more forbs, less grams.
# 
# 
# ## TERNARY PLOT (FIG 1C)
# (tern.plot <- ggtern(data = dom.fg2, aes(x = PlotForbMean, y = PlotGraminoidMean, z = PlotShrubMean)) +
#     geom_point(size = 3, alpha = 0.5, aes(colour = MeanRichness)) +
#     labs(x="Forb Cover", y="Graminoid Cover", z="Shrub Cover", colour = "Plot Richness") +
#     scale_colour_viridis(option = "plasma", begin = 0, end = 0.95) + theme_bw() + 
#     theme(legend.title = element_text(size = 26), legend.text=element_text(size = 20), 
#           tern.axis.text.T = element_text(size=22), tern.axis.text.L = element_text(size =22), 
#           tern.axis.text.R = element_text(size=22), tern.axis.title.T = element_text(size =28), 
#           tern.axis.title.L = element_text(size=28), tern.axis.title.R = element_text(size =28)))
# 
# ggsave(tern.plot, filename = "figures/Figure_1c.png", 
#        width = 25, height = 25, units = "cm")


DB_sf <- st_transform(DB3_sf, st_crs(rtp_sf))




#  Refaire le join
richness_par_cellule <- DB3_sf %>%
  st_join(rtp_sf, join = st_within) %>%
  st_drop_geometry() %>%
  filter(!is.na(layer)) %>%
  group_by(layer) %>%
  summarise(Richness = n_distinct(ID)) %>%
  rename(CellID = layer)



n_cells <- nrow(rtp)
sim_raw <- data.frame( Habitat_A = runif(n_cells, 0, 1), Habitat_B = runif(n_cells, 0, 1), Habitat_C = runif(n_cells, 0, 1))

sim_raw <- sim_raw / rowSums(sim_raw) * 100

habitat_richness <- data.frame(CellID = rtp$layer, sim_raw) %>%
  left_join(richness_par_cellule, by = "CellID")

## Graphique
(habitat.plot <- ggtern(data = habitat_richness,
                             aes(x = Habitat_A, y = Habitat_B, z = Habitat_C)) +
    geom_point(size = 3, alpha = 0.5, aes(colour = Richness)) +
    labs(x = "Habitat A", y = "Habitat B", z = "Habitat C",
         colour = "Plot richness") +
    scale_colour_viridis(option = "plasma", begin = 0, end = 0.95) +
    theme_bw()+
    theme_showarrows() +
    theme(tern.axis.title.T = element_blank(), tern.axis.title.L = element_blank(), tern.axis.title.R = element_blank(), tern.axis.arrow = element_blank(),  
      legend.title = element_text(size = 12), legend.text = element_text(size = 10),tern.axis.arrow.text.T = element_text(size = 10), tern.axis.arrow.text.L = element_text(size = 10),
      tern.axis.arrow.text.R = element_text(size = 10))
  )



library(terra)

grassland <- rast("Atlas/data/Grassland/20240101/CLMS_HRLVLCC_GRA_LU_0.tif")
forest <- rast("Atlas/data/TreeCover/20240101/CLMS_HRLVLCC_TCD_LU_0.tif")

grassland
forest


freq(grassland)
freq(forest)

forest_binary <- forest > 0 

grassland_2169 <- project(grassland, "EPSG:2169", method = "near")  
forest_2169 <- project(forest_binary, "EPSG:2169", method = "near")

rtp_vect <- vect(rtp)

# proportion de forest et prairies par cellules

grassland_pct <- terra::extract(grassland_2169, rtp_vect, fun = mean, na.rm = TRUE)
forest_pct <- terra::extract(forest_2169, rtp_vect, fun = mean, na.rm = TRUE)
 


# other = ce qui n est pas foret et prairie / pourcentage

habitat_richness <- data.frame(CellID = rtp$layer,  Grassland = pmin(grassland_pct[, 2] * 100, 100), Forest = pmin(forest_pct[, 2] * 100, 100)) %>%
  mutate(Other = pmax(100 - Grassland - Forest, 0),
          total = Grassland + Forest + Other, Habitat_A = Grassland / total * 100,
          Habitat_B = Forest / total * 100,   Habitat_C = Other / total * 100) %>%
  select(CellID, Habitat_A, Habitat_B, Habitat_C) %>%
  left_join(richness_par_cellule, by = "CellID")


ggtern(data = habitat_richness, aes(x = Habitat_A, y = Habitat_B, z = Habitat_C)) +
  geom_point(size = 3, alpha = 0.5, aes(colour = Richness)) +
  labs(x = "Grassland (%)", y = "Forest (%)", z = "Other (%)", colour = "Species richness") +
  scale_colour_viridis(option = "plasma", begin = 0, end = 0.95) +
  theme_bw() + theme_showarrows() +
  theme(tern.axis.title.T = element_blank(), tern.axis.title.L = element_blank(),tern.axis.title.R = element_blank(),
    tern.axis.arrow = element_blank(),legend.title = element_text(size = 12),legend.text = element_text(size = 10), tern.axis.arrow.text.T = element_text(size = 10),
    tern.axis.arrow.text.L = element_text(size = 10), tern.axis.arrow.text.R = element_text(size = 10)
  )


################3

DB <- DB %>% mutate(.obs_row_id = row_number())


obs_vect_2169 <- vect(DB, geom = c("Long", "Lat"), crs = "EPSG:4326") %>%
  project("EPSG:2169")

#  500 m
obs_buffer <- buffer(obs_vect_2169, width = 500)

# Extraction 
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

ggtern(data = habitat_par_observation_df, aes(x = Habitat_A, y = Habitat_B, z = Habitat_C)) +
  geom_point(size = 3, alpha = 0.5) +
  labs(x = "Grassland (%)", y = "Forest (%)", z = "Other (%)") +
  theme_bw() + theme_showarrows() +
  theme(
    tern.axis.title.T = element_blank(), tern.axis.title.L = element_blank(), tern.axis.title.R = element_blank(),
    tern.axis.arrow = element_blank(),
    legend.title = element_text(size = 12), legend.text = element_text(size = 10),
    tern.axis.arrow.text.T = element_text(size = 10), tern.axis.arrow.text.L = element_text(size = 10), tern.axis.arrow.text.R = element_text(size = 10)
  )


#######################################################################


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

# 500m
obs_sf <- DB %>%
  mutate(obs_id = row_number()) %>%
  st_as_sf(coords = c("Long", "Lat"), crs = 4326) %>%
  st_transform(2169)

obs_buffer <- st_buffer(obs_sf, dist = 500)

#  proportion par classe par observation
habitat_par_observation <- st_intersection(obs_buffer, lc) %>%
  mutate(area = as.numeric(st_area(geometry))) %>%
  st_drop_geometry() %>%
  group_by(obs_id, HabitatClass) %>%
  summarise(area = sum(area), .groups = "drop") %>%
  group_by(obs_id) %>%
  mutate(pct = area / sum(area) * 100) %>%
  ungroup() %>%
  select(obs_id, HabitatClass, pct) %>%
  pivot_wider(names_from = HabitatClass, values_from = pct, values_fill = 0) %>%
  left_join(st_drop_geometry(obs_sf) %>% select(obs_id, ID), by = "obs_id")

ggtern(data = habitat_par_observation, aes(x = Grassland, y = Forest, z = Other)) +
  geom_point(size = 3, alpha = 0.5) +
  labs(x = "Grassland (%)", y = "Forest (%)", z = "Other (%)") +
  theme_bw() + theme_showarrows() +
  theme(
    tern.axis.title.T = element_blank(), tern.axis.title.L = element_blank(), tern.axis.title.R = element_blank(),
    tern.axis.arrow = element_blank(),
    tern.axis.arrow.text.T = element_text(size = 10), tern.axis.arrow.text.L = element_text(size = 10), tern.axis.arrow.text.R = element_text(size = 10)
  )













