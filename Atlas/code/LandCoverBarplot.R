

library(terra)
library(sf)
library(terra)
library(dplyr)
library(ggplot2)


pts_sf <- st_as_sf(DB2, coords = c("Long", "Lat"), crs = 4326) %>%
  st_transform(2169)
pts_sf$point_id <- seq_len(nrow(pts_sf))
buffers <- st_buffer(pts_sf, 500)


lc_raster <- rast("Atlas/data/LandCover_Luxembourg_status_2024.tif")

lc_low_res <- aggregate(lc_raster, fact = 5000, fun = "modal")

ext_data <- terra::extract(lc_low_res, vect(buffers))



lc_values <- terra::extract(lc_raster, vect(buffers), fun = "modal") 


lc_freq <- terra::extract(lc_raster, vect(buffers), fun = "freq")


recode_lc <- function(x) {
  case_when(
    x %in% c(10, 20) ~ "Built",  x %in% c(70, 80) ~ "Forest",
    x %in% c(91, 92, 93) ~ "Herbaceous",
    x == 30 ~ "Bare soil",  x == 60 ~ "Water",
    TRUE ~ NA_character_)
}


DB2_landcover <- DB2 %>%
  mutate(point_id = row_number()) %>%
  left_join( lc_values %>% mutate(Habitat_Dominant = recode_lc(lyr1)),by = c("point_id")
  )


plot_habitat_espece <- function(espece, data = DB2_landcover) {
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

plot_habitat_espece("Volucella zonaria")