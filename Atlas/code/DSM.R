
carte_altitude <- function(datapath, fact_aggregation = 100) {
  fichier_tif <- paste0(datapath, "MNS_Lidar2024.tif")
  dsm <- terra::rast(fichier_tif)
  

  dsm_agg <- terra::aggregate(dsm, fact = fact_aggregation, fun = "mean")
  

  breaks <- c(-Inf, 150, 250, 350, 450, 550, Inf)
  etiquettes <- c("< 150", "150-250", "250-350", "350-450", "450-550", "> 550")
  couleurs <- c("#6AA85B", "#9DB84A", "#dbcc46", "#c9973a", "#a87334", "#704B29")
  

  slope <- terra::terrain(dsm_agg, "slope", unit = "radians")
  aspect <- terra::terrain(dsm_agg, "aspect", unit = "radians")
  
  hillshade_df <- terra::shade(slope, aspect, angle = 45, direction = 315) |>
    as.data.frame(xy = TRUE) |> 
    dplyr::rename(shade = 3)
  

  matrice_reclass <- matrix(c(breaks[-7], breaks[-1], 1:6), ncol = 3)
  
  alt_df <- terra::classify(dsm_agg, rcl = matrice_reclass) |>
    as.data.frame(xy = TRUE) |> 
    dplyr::rename(classe = 3) |>
    dplyr::mutate(classe = factor(classe, levels = 1:6, labels = etiquettes))
  

  carte <- ggplot2::ggplot() +
    ggplot2::geom_raster(data = hillshade_df, ggplot2::aes(x, y, fill = shade), show.legend = FALSE) +
    ggplot2::scale_fill_gradient(low = "black", high = "white", guide = "none") +
    ggnewscale::new_scale_fill() +
    ggplot2::geom_raster(data = alt_df, ggplot2::aes(x, y, fill = classe), alpha = 0.6) +
    ggspatial::annotation_scale(location = "bl", unit_category = "metric", style = "ticks") +
    ggplot2::scale_fill_manual(name = "Altitude (m)", values = stats::setNames(couleurs, etiquettes), na.translate = FALSE) +
    ggplot2::coord_equal() +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      legend.position = c(0.85, 0.75)
    )
  
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