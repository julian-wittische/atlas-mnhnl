###### Spatial object ----
bbox <- st_bbox(c(xmin = 5.7, xmax = 6.55, ymax = 50.2, ymin = 49.4), crs = st_crs(4326))
GRborders <- st_read(paste0(DATAPATH,"GRborders.gpkg"))


lux5km <- raster(nrows=12, ncols=17, xmn=48000, xmx=108000, ymn=55000, ymx=140000,
                 crs=CRS('+init=EPSG:2169'), resolution=5000, vals=1:204)

lux_borders <- gb_get_adm0("Luxembourg")
lux_borders <- st_transform(lux_borders, crs="EPSG:2169")
lux_borders <- as(lux_borders, "Spatial")

lux_raster <- rasterize(lux_borders, lux5km, mask=TRUE, getCover=TRUE)
lux_raster[lux_raster==0] <- NA
cell_number_lux <- lux_raster
cell_number_lux[!is.na(cell_number_lux)] <- 1:length(cell_number_lux[!is.na(cell_number_lux)])
rtp <- rasterToPolygons(cell_number_lux, digits=20)
