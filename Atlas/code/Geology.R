######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Load geology data and create a static and an interactive map



###### Geology data ----

#### Lecture des couches géologiques ----

symbole  <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/1")  # symboles stratigraphiques
uniteGeo <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/6")  # unités géologiques (polygones)
failles  <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/2")  # failles (lignes)
contours <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/3")  # courbes de niveau

#### Reprojection des couches dans le CRS ----
uniteGeo <- st_transform(uniteGeo, crs = st_crs(lux_borders))
contours <- st_transform(contours, crs = st_crs(lux_borders))
failles  <- st_transform(failles,  crs = st_crs(lux_borders))
symbole  <- st_transform(symbole,  crs = st_crs(lux_borders))

n_niveaux <- nlevels(factor(uniteGeo$CODESTRATUNIT))


#### Carte des unités géologiques + failles en rouge + contours 
m2 <- mapview(uniteGeo, zcol = "CODESTRATUNIT",
              col.regions = colorRampPalette(RColorBrewer::brewer.pal(12, "Set3"))(n_niveaux),
              legend = FALSE, homebutton = FALSE, popup = FALSE) +
  # mapview(contours, color = "#F5F5DC", lwd = 1, legend = FALSE, homebutton = FALSE) +
  mapview(failles, color = "red", lwd = 1, legend = FALSE, homebutton = FALSE)

# Ajout des labels 
m2@map <- m2@map %>%
  addLabelOnlyMarkers(
    data = symbole,
    label = ~ABREVSTRAT,
    group = "Labels",
    labelOptions = labelOptions(
      noHide = TRUE,
      direction = "center",
      textOnly = TRUE,
      style = list("font-size" = "9px", "font-weight" = "bold", "color" = "black")
    )
  ) %>%
  groupOptions("Labels", zoomLevels = 14:52)

###### Static Geology map ----

.preparer_legende_geo <- function(uniteGeo) {
  base_df <- uniteGeo |>
    sf::st_drop_geometry() |>
    distinct(ERE_FR, GROUPING1_FR, NOMUNIT_FR, AGE_MIN) |>
    mutate(across(c(ERE_FR, GROUPING1_FR, NOMUNIT_FR), \(x) na_if(str_squish(x), ""))) |>
    filter(!is.na(ERE_FR), !is.na(GROUPING1_FR), !is.na(NOMUNIT_FR)) |>
    arrange(AGE_MIN) |>
    mutate(
      ere_change = ERE_FR != lag(ERE_FR, default = "___"),
      grouping_change = ere_change | GROUPING1_FR != lag(GROUPING1_FR, default = "___"),
      row_id = row_number()
    )
  
  legende_df <- bind_rows(
    base_df |> dplyr::filter(ere_change, row_id > 1) |>
      dplyr::transmute(row_id, sub = 0, label = "", NOMUNIT_FR = NA_character_, type = "spacer"),
    base_df |> dplyr::filter(ere_change) |>
      dplyr::transmute(row_id, sub = 1, label = paste0(ERE_FR, ":"), NOMUNIT_FR = NA_character_, type = "ere"),
    base_df |> dplyr::filter(grouping_change) |>
      dplyr::transmute(row_id, sub = 2, label = paste0("  ", GROUPING1_FR, ":"), NOMUNIT_FR = NA_character_, type = "grouping"),
    base_df |>
      dplyr::transmute(row_id, sub = 3, label = paste0("    ", NOMUNIT_FR), NOMUNIT_FR = NOMUNIT_FR, type = "unit")
  ) |>
    dplyr::arrange(row_id, sub) |>
    dplyr::select(-row_id, -sub)
  
  noms_uniques <- unique(legende_df$NOMUNIT_FR[legende_df$type == "unit"])
  palette_geo  <- setNames(colorRampPalette(brewer.pal(12, "Set3"))(length(noms_uniques)), noms_uniques)
  
  list(legende_df = legende_df, palette_geo = palette_geo)
}


uniteGeo_lux <- st_intersection(uniteGeo, st_geometry(lux_borders_sf))
failles_lux  <- st_intersection(failles, st_geometry(lux_borders_sf))

plot_carte_geologique <- function(uniteGeo, failles) {
  prep <- .preparer_legende_geo(uniteGeo)
  ggplot() +
    geom_sf(data = uniteGeo, aes(fill = NOMUNIT_FR), color = NA) +
    scale_fill_manual(values = prep$palette_geo, guide = "none") +
    geom_sf(data = failles, color = "red", linewidth = 0.4) +
    geom_sf(data = GR2169_c, fill = NA, color = "grey", linewidth = 0.5) +
    geom_text(data = country_labels, aes(x = x, y = y, label = name),
              size = 6, color = "grey40", fontface = "italic") +
    annotation_scale(location = "bl", width_hint = 0.2,
                     style = "ticks", text_cex = 1,
                     line_width = 1, height = unit(0.5, "cm"),
                     pad_x = unit(0.7, "cm"), pad_y = unit(0.8, "cm")) +
    annotation_north_arrow(location = "tr", which_north = "true",
                           style = north_arrow_fancy_orienteering(),
                           height = unit(1.8, "cm"), width = unit(1.8, "cm"),
                           pad_x = unit(1.5, "cm"), pad_y = unit(1, "cm")) +
    theme_void() +
    theme(legend.position = "none") +
    coord_sf(crs = "EPSG:2169",
             xlim = c(bbox_2169["xmin"], bbox_2169["xmax"]),
             ylim = c(bbox_2169["ymin"], bbox_2169["ymax"]),
             expand = FALSE)
}



plot_carte_geologique(uniteGeo_lux, failles_lux)

plot_legende_geologique <- function(uniteGeo,
                                    ncol_legende = 2,
                                    cex_legende = 0.6,
                                    x_intersp = 0.5,
                                    y_intersp = 0.8) {
  prep <- .preparer_legende_geo(uniteGeo)
  legende_df <- prep$legende_df
  palette_geo <- prep$palette_geo
  
  fill_col <- ifelse(legende_df$type == "unit", palette_geo[legende_df$NOMUNIT_FR], NA_character_)
  font_vec <- ifelse(legende_df$type %in% c("ere", "grouping"), 2L, 1L)

  par(mar = c(0, 0, 0, 0), xpd = TRUE)
  plot.new()
  legend( "center", legend = legende_df$label, fill = fill_col, border = NA,
    text.font = font_vec, ncol = ncol_legende, cex = cex_legende, bty = "n",  x.intersp = x_intersp, y.intersp = y_intersp,
    text.width = max(strwidth(legende_df$label, cex = cex_legende)) )
}


###### Description table ----

tableau_unites <- uniteGeo %>%
  st_drop_geometry() %>%
  dplyr::select(CODESTRATUNIT, NOMUNIT_FR, DESCUNIT_FR, AGE_MIN) %>%
  dplyr::distinct() %>%
  dplyr::arrange(AGE_MIN) %>%
  dplyr::filter(!is.na(DESCUNIT_FR)) %>% 
  dplyr::filter(!is.na(CODESTRATUNIT)) %>% 
  dplyr::rename( "Code" = CODESTRATUNIT,"Unité géologique" = NOMUNIT_FR,"Description" = DESCUNIT_FR)

tableau_unites <- tableau_unites[, c("Code", "Unité géologique", "Description")]



