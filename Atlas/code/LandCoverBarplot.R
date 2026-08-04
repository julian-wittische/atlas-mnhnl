library(sf)
library(dplyr)
library(ggplot2)




land_cover <- st_read("Atlas/data/LandCover_Luxembourg_2018_2021_2024.gdb",
                      layer = "LandCover_Luxembourg_status_2024")



pts_sf <- st_as_sf(DB2, coords = c("Long", "Lat"), crs = 4326) %>%
  st_transform(2169)
pts_sf$point_id <- seq_len(nrow(pts_sf))
buffers <- st_buffer(pts_sf, dist = 500)



bbox_buffers <- st_bbox(buffers)
land_cover_crop <- st_crop(land_cover, bbox_buffers)


land_cover_grouped <- land_cover_crop %>%
  mutate(
    LC_char = as.character(LC2024),
    Group = case_when(
      LC_char %in% c("10", "20")       ~ "Built",
      LC_char %in% c("70", "80")       ~ "Forest",
      LC_char %in% c("91", "92", "93") ~ "Herbaceous",
      LC_char == "30"                  ~ "Bare soil",
      LC_char == "60"                  ~ "Water",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(Group)) %>%
  st_make_valid()

# Dissoudre par groupe
land_cover_grouped <- land_cover_grouped %>%
  group_by(Group) %>%
  summarise(.groups = "drop") %>%
  st_make_valid()


inter <- st_intersection(
  buffers %>% select(point_id),
  land_cover_grouped %>% select(Group)
)

inter$area_m2 <- as.numeric(st_area(inter))

area_by_group <- inter %>%
  st_drop_geometry() %>%
  group_by(point_id, Group) %>%
  summarise(area_m2 = sum(area_m2), .groups = "drop")

total_by_point <- area_by_group %>%
  group_by(point_id) %>%
  summarise(area_tot = sum(area_m2), .groups = "drop")

pct_wide <- area_by_group %>%
  left_join(total_by_point, by = "point_id") %>%
  mutate(pct = area_m2 / area_tot) %>%
  select(point_id, Group, pct) %>%
  tidyr::pivot_wider(names_from = Group, values_from = pct, values_fill = 0)

group_cols <- setdiff(names(pct_wide), "point_id")

pct_wide <- pct_wide %>%
  rowwise() %>%
  mutate(Habitat_Dominant = group_cols[which.max(c_across(all_of(group_cols)))]) %>%
  ungroup()

DB2_landcover <- DB2 %>%
  mutate(point_id = seq_len(nrow(DB2))) %>%
  left_join(pct_wide, by = "point_id")

# Barplot


plot_habitat_espece_lc <- function(espece, data = DB2_landcover) {
  
  lc_colors <- c(
    "Built"       = "#E40102",
    "Forest"      = "#267400",
    "Herbaceous"  = "#55FF00",
    "Bare soil"   = "#73DDFE",
    "Water"       = "#014DA7"
  )
  
  df <- data %>%
    filter(ID == espece) %>%
    count(Habitat_Dominant, name = "n") %>%
    mutate(espece = espece, pct = 100 * n / sum(n))
  
  ggplot(df, aes(x = espece, y = pct, fill = Habitat_Dominant)) +
    geom_col(width = 0.6, color = "black", linewidth = 0.8) +
    geom_text(aes(label = paste0(round(pct), "%")),
              position = position_stack(vjust = 0.5),
              size = 4, fontface = "bold", color = "black") +
    coord_flip() +
    scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 10), expand = c(0, 0)) +
    scale_fill_manual(values = lc_colors) +
    labs(title = paste("Habitats (land cover 500 m) —", espece), x = NULL, y = NULL, fill = NULL) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", size = 15, margin = margin(b = 14)),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = 10),
      axis.ticks.x = element_line(color = "black"),
      axis.line.x = element_line(color = "black"),
      panel.grid = element_blank(),
      legend.position = "right"
    )
}

plot_habitat_espece_lc("Volucella zonaria")