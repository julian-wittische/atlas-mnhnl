############ Graphique smooth ----
grille <- expand.grid(Month = 1:12, Quart = 1:4) %>%
  arrange(Month, Quart) %>%
  mutate(Position = row_number())
base <- grille$Position[grille$Quart == 1]

plot_activite_smooth <- function(species_name, data = DB) {
  presence <- prepare_presence(species_name, data)
  ggplot(presence, aes(x = Position, y = n)) +
    geom_area(stat = "smooth", fill = "lightblue", span = 1/3, alpha = 0.6, se = FALSE,
              xseq = seq(min(presence[presence$n > 0, "Position"]), max(presence[presence$n > 0, "Position"]), 1)) +
    scale_x_continuous(limits = c(1, 48), breaks = base, labels = month.abb, expand = c(0.1, 0.1)) +
    scale_y_continuous(limits = c(0, NA), expand = c(0, 0)) +
    geom_vline(xintercept = range(presence[presence$n > 0, "Position"])) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_text(size = 15),
      axis.text.y = element_blank(),
      axis.title = element_blank(),
      axis.ticks.y = element_blank(),
      axis.title.y = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_blank()
    )
}

install.packages("rredlist")
library(rredlist)
rredlist::rl_use_iucn()
rl_species_latest(genus = "Eristalis", species = "tenax")




############ Graphique bâtons par source ----
plot_activite_source <- function(species_name, data = DB) {
  presence <- prepare_presence(species_name, data)
  ggplot(presence, aes(x = Position, y = prop, fill = Source2)) +
    geom_col(width = 0.85) +
    scale_fill_manual(name = NULL, values = c("Citizen science" = "lightgreen", "Other" = "lightblue"), na.translate = FALSE) +
    scale_x_continuous(limits = c(1, 48), breaks = base, labels = month.abb, expand = c(0.1, 0.1)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_text(size = 15),
      axis.text.y = element_blank(),
      axis.title = element_blank(),
      axis.ticks.y = element_blank(),
      panel.grid = element_blank(),
      legend.position = "top",
      legend.text = element_text(size = 15)
    )
}

# # radieus 500m
# grassland_500m <- terra::extract(grassland_2169, pts_2169, buffer = 500, fun = mean, na.rm = TRUE)
# forest_500m    <- terra::extract(forest_2169,    pts_2169, buffer = 500, fun = mean, na.rm = TRUE)
# 
# # DB_habitat_500m
# DB_habitat_500m <- DB %>%
#   mutate( Grassland_pct = grassland_500m[[2]], Forest_pct = forest_500m[[2]],  Other_pct= 1 - Grassland_pct - Forest_pc ) %>%
#   mutate(Habitat_Dominant = case_when(
#     Grassland_pct >= Forest_pct & Grassland_pct >= Other_pct ~ "Grassland",
#     Forest_pct >= Grassland_pct & Forest_pct >= Other_pct    ~ "Forest",
#     TRUE ~ "Other" ))

# grassland_focal <- focal(grassland_2169, w = 16 , fun = mean, na.rm = TRUE)
# forest_focal    <- focal(forest_2169,    w = 16 , fun = mean, na.rm = TRUE)
# (autre variante commentée, focal() plutôt que adjacent() -- non utilisée)