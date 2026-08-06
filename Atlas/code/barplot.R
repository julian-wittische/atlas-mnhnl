

# proportion de forest et prairies par cellules

grassland_pct <- terra::extract(grassland_2169, rtp_vect, fun = mean, na.rm = TRUE)
forest_pct <- terra::extract(forest_2169, rtp_vect, fun = mean, na.rm = TRUE)


habitat_richness <- habitat_richness %>%
  mutate(Habitat_Dominant = case_when(
    Habitat_A >= Habitat_B & Habitat_A >= Habitat_C ~ "Grassland",
    Habitat_B >= Habitat_A & Habitat_B >= Habitat_C ~ "Forest",
    TRUE ~ "Other"
  ))


# par cellule

DB_habitat <- DB %>%
  left_join(habitat_richness %>% select(CellID, Habitat_Dominant),
            by = c("Cell" = "CellID"))

# # par radius de 100m
# 
pts <- vect(DB2, geom = c("Long", "Lat"), crs = "EPSG:4326")
pts_2169 <- project(pts, "EPSG:2169")
# 
# # radieus 100m
# grassland_100m <- terra::extract(grassland_2169, pts_2169, buffer = 500, fun = mean, na.rm = TRUE)
# forest_100m    <- terra::extract(forest_2169,    pts_2169, buffer = 500, fun = mean, na.rm = TRUE)
# 
# # DB2_habitat_100m
# DB2_habitat_100m <- DB %>%
#   mutate( Grassland_pct = grassland_100m[[2]], Forest_pct = forest_100m[[2]],  Other_pct= 1 - Grassland_pct - Forest_pc ) %>%
#   mutate(Habitat_Dominant = case_when(
#     Grassland_pct >= Forest_pct & Grassland_pct >= Other_pct ~ "Grassland",
#     Forest_pct >= Grassland_pct & Forest_pct >= Other_pct    ~ "Forest",
#     TRUE ~ "Other" ))

# grassland_focal <- focal(grassland_2169, w = 16 , fun = mean, na.rm = TRUE)
# forest_focal    <- focal(forest_2169,    w = 16 , fun = mean, na.rm = TRUE)

cells <- cells(forest_2169, pts_2169)

forest_2169[cells[,2]]
sizeN <- 7 # /!\ WARNING: MUST BE ODD
ifelse(sizeN  %% 2 == 1, print("Okkk"), print("MUST BE ODD"))


sizeN

direN <- rep(1,sizeN^2)
direN[trunc((sizeN^2)/2)+1] <- 0
neigh <- matrix(direN, sizeN)

adj_grassland <- adjacent(grassland_2169, cells[,2], directions = 16, include = TRUE)

adj_grassland <- adjacent(grassland_2169, cells[,2], directions = neigh, include = TRUE)


adj_forest <- adjacent(forest_2169,    cells[,2], directions = 16, include = TRUE)

# Notes : la première colonne réfère aux cellules focales

rowMeans(adj_grassland, na.rm = TRUE)
colMeans(grassland_2169[adj_grassland[1,]])



grassland_pct_adj <- sapply(1:nrow(adj_grassland), function(i) {
  colMeans(grassland_2169[adj_grassland[i, ]], na.rm = TRUE)
})

forest_pct_adj <- sapply(1:nrow(adj_forest), function(i) {
  colMeans(forest_2169[adj_forest[i, ]], na.rm = TRUE)
})



DB2_habitat_adj <- DB2 %>%
  mutate(Grassland_pct = grassland_pct_adj, Forest_pct= forest_pct_adj, Other_pct= pmax(1 - Grassland_pct - Forest_pct, 0)) %>%
  mutate(Habitat_Dominant = case_when(Grassland_pct >= Forest_pct & Grassland_pct >= Other_pct ~ "Grassland",
                                      Forest_pct >= Grassland_pct & Forest_pct >= Other_pct ~ "Forest", TRUE ~ "Other")
   )





mean(DB2_habitat_adj$Grassland_pct, na.rm=TRUE)
mean(DB2_habitat_adj$Forest_pct, na.rm=TRUE)
mean(DB2_habitat_adj$Other_pct, na.rm=TRUE)









plot_habitat_espece <- function(espece, data = DB2_habitat) {
  
  df <- data %>%
    filter(ID == espece) %>%
    count(Habitat_Dominant, name = "n") %>%
    mutate(
      espece = espece,
      pct = 100 * n / sum(n)
    )
 
  
  ggplot(df, aes(x = espece, y = pct, fill = Habitat_Dominant)) +
    geom_col(width = 0.6, color = "black", linewidth = 0.8) +
    geom_text(
      aes(label = paste0(round(pct), "%")), position = position_stack(vjust = 0.5), size = 4, fontface = "bold", color = "black"  ) +
    coord_flip() +
    scale_y_continuous(
      limits = c(0, 100),
      breaks = seq(0, 100, 10),
      expand = c(0, 0)
    ) +
    scale_fill_manual(values = c(
      "Grassland" = "yellow",  "Forest"   = "darkgreen", "Other" = "grey" )) +
    labs(
      title = paste("Habitats —", espece),
      x = NULL, y = NULL, fill = NULL ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", size = 15, margin = margin(b = 14)),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = 10),
      axis.ticks.x = element_line(color = "black"),
      axis.line.x = element_line(color = "black"),
      panel.grid = element_blank(),
      legend.position = "right",
      legend.direction = "vertical",
      legend.text = element_text(size = 12, face = "bold"),
      legend.key.size = unit(1.3, "lines"),
      legend.spacing.y = unit(0.5, "cm"),
      plot.margin = margin(t = 15, r = 10, b = 10, l = 10)
    )
}


plot_habitat_espece("Volucella zonaria", data = DB2_habitat)
plot_habitat_espece("Volucella zonaria", data = DB2_habitat_adj)

plot_habitat_espece("Episyrphus balteatus", data = DB2_habitat)
plot_habitat_espece("Helophilus hybridus", data = DB2_habitat_adj)


DB2_habitat <- DB2[DB2$Source == "Hand netting",] %>%
  left_join(habitat_richness %>% select(CellID, Habitat_Dominant),
            by = c("Cell" = "CellID"))


### test 


r <- 16
n <- 2 * r + 1
c <- r + 1
grille <- expand.grid(row = 1:n, col = 1:n)
grille$dist <- abs(grille$row - c) + abs(grille$col - c)
grille$type <- ifelse(grille$dist == 0, "centre", ifelse(grille$dist <= r, "x", "h"))

ggplot(grille, aes(col, -row, fill = type)) +
  geom_tile(color = "grey70") +
  scale_fill_manual(values = c(centre = "black", x = "grey60", h = "white")) +
  coord_fixed() +
  theme_void() +
  theme(legend.position = "none")



