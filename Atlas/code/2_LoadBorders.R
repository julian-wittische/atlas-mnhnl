######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : get borders for nice map

source("code/0_Initialisation.R")

############ Bbox for the Greater Region
bbox <- st_bbox(c(xmin = 5.7, xmax = 6.55, ymax = 50.2, ymin = 49.4),
                crs = st_crs(4326))

############ Greater Region borders
invisible(capture.output(GRborders <- st_read(paste0(DATAPATH, "GRborders.gpkg"), quiet = TRUE)))

############ Grille 5 km Luxembourg
lux5km <- raster(nrows = 12, ncols = 17,
                 xmn = 48000, xmx = 108000, ymn = 55000, ymx = 140000,
                 crs = CRS('+init=EPSG:2169'), resolution = 5000,
                 vals = 1:204)

############ Frontière nationale du Luxembourg
lux_borders <- gb_get_adm0("Luxembourg")
lux_borders <- st_transform(lux_borders, crs = "EPSG:2169")
lux_borders <- as(lux_borders, "Spatial")  # rasterize() attend un objet sp, pas sf

############ Rasterisation de la frontière sur la grille 5 km
lux_raster <- rasterize(lux_borders, lux5km, mask = TRUE, getCover = TRUE)
lux_raster[lux_raster == 0] <- NA  # on retire les cellules sans recouvrement

############ Numérotation des cellules valides 
cell_number_lux <- lux_raster
cell_number_lux[!is.na(cell_number_lux)] <- 1:length(cell_number_lux[!is.na(cell_number_lux)])

############ Conversion du raster numéroté en polygone
rtp <- rasterToPolygons(cell_number_lux, digits = 20)
