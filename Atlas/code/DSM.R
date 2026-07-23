######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Create and a static and an interactive geology map 



carte_altitude <- function(datapath, fact_aggregation = 100) {
  fichier_tif <- paste0(datapath, "MNS_Lidar2024.tif")
  dsm <- rast(fichier_tif)
  
  dsm_agg <- aggregate(dsm, fact = fact_aggregation, fun = "mean")
  
  lux_borders_vect_dsm <- vect(st_transform(lux_borders_sf, crs(dsm_agg)))
  dsm_agg <- mask(crop(dsm_agg, lux_borders_vect_dsm), lux_borders_vect_dsm)
  
  breaks <- c(-Inf, 150, 250, 350, 450, 550, Inf)
  etiquettes <- c("< 150", "150-250", "250-350", "350-450", "450-550", "> 550")
  couleurs <- c("#6AA85B", "#9DB84A", "#dbcc46", "#c9973a", "#a87334", "#704B29")
  
  slope <- terrain(dsm_agg, "slope", unit = "radians")
  aspect <- terrain(dsm_agg, "aspect", unit = "radians")
  
  hillshade_df <- shade(slope, aspect, angle = 45, direction = 315) |>
    as.data.frame(xy = TRUE) |> 
    rename(shade = 3)
  
  matrice_reclass <- matrix(c(breaks[-7], breaks[-1], 1:6), ncol = 3)
  
  alt_df <- classify(dsm_agg, rcl = matrice_reclass) |>
    as.data.frame(xy = TRUE) |> 
    rename(classe = 3) |>
    mutate(classe = factor(classe, levels = 1:6, labels = etiquettes))
  
  zone_totale <- st_as_sfc(bbox_2169)
  masque_hors_lux <- st_difference(zone_totale, st_union(lux_borders_sf))
  
  carte <- ggplot() +
    geom_raster(data = hillshade_df, aes(x, y, fill = shade), show.legend = FALSE) +
    scale_fill_gradient(low = "black", high = "white", guide = "none") +
    new_scale_fill() +
    geom_raster(data = alt_df, aes(x, y, fill = classe), alpha = 0.6) +
    scale_fill_manual(name = "Altitude (m)", values = setNames(couleurs, etiquettes), na.translate = FALSE) +
    geom_sf(data = masque_hors_lux, fill = "white", color = NA) +
    geom_sf(data = lux_borders_sf, fill = NA, color = "black", linewidth = 0.4) +
    geom_sf(data = GR2169_c, fill = NA, color = "grey30", linewidth = 0.4) +
    geom_text(data = country_labels, aes(x = x, y = y, label = name),
              size = 3, color = "grey40", fontface = "italic") +
    coord_sf(crs = "EPSG:2169",
             xlim = c(bbox_2169["xmin"], bbox_2169["xmax"]),
             ylim = c(bbox_2169["ymin"], bbox_2169["ymax"]),
             expand = FALSE) +
    theme_void() +
    theme(
      plot.background = element_rect(fill = "white", color = NA), legend.position = c(0.85, 0.80), 
      legend.title = element_text(size = 8), legend.text = element_text(size = 7), legend.key.size = unit(0.4, "cm"),
      plot.margin = margin(0, 0, 0, 0, "cm"))
  
  return(carte)
}

# 
# 
# 
# 
# 
# 
# # 3D map
# x |>
#   # sphere_shade(texture= "imhof4",sunangle = 45) |>
#   height_shade(
#     texture = (grDevices::colorRampPalette(c("#6AA85B",  "#dbcc46", "#a87334")))(256)
#   ) |> 
#   add_shadow(ray_shade(x), 0.5)|>
#   add_shadow(ambient_shade(x, maxsearch = 30), 0) |> 
#   plot_3d(
#     x,
#     zscale = 10,
#     fov = 0,
#     theta = 135,
#     zoom = 0.75,
#     phi = 45,
#     windowsize = c(1000, 800)
#   ) 
# Sys.sleep(0.2)
# render_snapshot()
# 
# 
# # 3D map with scale and compass
# render_camera(fov = 0, theta = 60, zoom = 0.75, phi = 45)
# render_scalebar(
#   limits = c(0, 5, 10),
#   label_unit = "km",
#   position = "W",
#   y = 50,
#   scale_length = c(0.33, 1)
# )
# render_compass(position = "E")
# 
# 
# 
# # render_highquality()
# 
# 
# x |> 
#   sphere_shade(sunangle = 45) |>
#   plot_3d(
#     x,
#     zscale = 10,
#     fov = 0,
#     theta = 72,
#     zoom = 0.68,
#     phi = 40,
#     shadowdepth = -100,
#     soliddepth = -100,
#     windowsize = c(1000, 800)
#   )
# 
# render_scalebar(
#   limits = c(0, 5, 10),
#   label_unit = "km",
#   position = "W",
#   y = 50,
#   scale_length = c(0.33, 1)
# )
# 
# render_compass(position = "E")
# Sys.sleep(0.2)
# render_highquality(samples = 16, scale_text_size = 24) 