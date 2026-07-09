DSM <- rast(paste0(DATAPATH, "MNS_Lidar2024.tif"))


crs(DSM, describe = TRUE)

DSM_50m <- aggregate(DSM, fact = 100, fun = "mean")
x <- raster_to_matrix(DSM_50m)

# 3D map
x |>
  # sphere_shade(texture= "imhof4",sunangle = 45) |>
  height_shade(
    texture = (grDevices::colorRampPalette(c("#6AA85B",  "#dbcc46", "#a87334")))(256)
  ) |> 
  add_shadow(ray_shade(x), 0.5)|>
  add_shadow(ambient_shade(x, maxsearch = 30), 0) |> 
  plot_3d(
    x,
    zscale = 10,
    fov = 0,
    theta = 135,
    zoom = 0.75,
    phi = 45,
    windowsize = c(1000, 800)
  ) 
Sys.sleep(0.2)
render_snapshot()
























# 3D map with scale and compass
render_camera(fov = 0, theta = 60, zoom = 0.75, phi = 45)
render_scalebar(
  limits = c(0, 5, 10),
  label_unit = "km",
  position = "W",
  y = 50,
  scale_length = c(0.33, 1)
)
render_compass(position = "E")



# render_highquality()


x |> 
  sphere_shade(sunangle = 45) |>
  plot_3d(
    x,
    zscale = 10,
    fov = 0,
    theta = 72,
    zoom = 0.68,
    phi = 40,
    shadowdepth = -100,
    soliddepth = -100,
    windowsize = c(1000, 800)
  )

render_scalebar(
  limits = c(0, 5, 10),
  label_unit = "km",
  position = "W",
  y = 50,
  scale_length = c(0.33, 1)
)

render_compass(position = "E")
Sys.sleep(0.2)
render_highquality(samples = 16, scale_text_size = 24) 