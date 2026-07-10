###### Function ----


blockCheckboxSP<- function(id, value, label) {
  tags$div(class = "checkbox",
           tags$label(
             tags$input(type = "checkbox", name = id, value = value, checked = "checked" ),
             tags$span(label)
           )
  )
}



filter_checkboxSP <- function (id, label, sharedData, group, allLevels = FALSE, inline = FALSE, 
                               columns = 1) 
{
  options <- makeGroupOptions(sharedData, group, allLevels)
  labels <- options$items$label
  values <- options$items$value
  options$items <- NULL
  makeCheckbox <- if (inline) 
    inlineCheckboxSP
  else blockCheckboxSP
  htmltools::browsable(htmltools::attachDependencies(tags$div(id = id, 
                                                              class = "form-group crosstalk-input-checkboxgroup crosstalk-input", 
                                                              tags$label(class = "control-label", `for` = id, label), 
                                                              tags$div(class = "crosstalk-options-group", columnize(columns, 
                                                                                                                    mapply(labels, values, FUN = function(label, value) {
                                                                                                                      makeCheckbox(id, value, label)
                                                                                                                    }, SIMPLIFY = FALSE, USE.NAMES = FALSE))), tags$script(type = "application/json", 
                                                                                                                                                                           `data-for` = id, jsonlite::toJSON(options, dataframe = "columns", 
                                                                                                                                                                                                             pretty = TRUE))), c(list(jqueryLib()), crosstalkLibs())))
}

inlineCheckboxSP <- function(id, value, label) {
  tags$label(
    class = "checkbox-inline",
    tags$input(
      type = "checkbox",
      name = id,
      value = value,
      checked = "checked"
    ),
    tags$span(label)
  )
}



attach(loadNamespace("crosstalk"), name = "crosstalk_all")



###### Base map ######

mapviewOptions(fgb = FALSE)

base_map <- leaflet() %>%
  addProviderTiles("OpenStreetMap", group = "OSM") %>%
  addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
  addLayersControl(baseGroups = c("OSM", "Satellite"),
                   options = layersControlOptions(collapsed = FALSE))

m <- mapView(rtp,
             method = "ngb", 
             na.color = rgb(0, 0, 255, max = 255, alpha = 0),
             query.type = "click",
             trim = TRUE,
             legend = FALSE,
             map = base_map,      
             alpha.regions = 0,
             alpha = 0.3,
             lwd = 2,
             color = "red")


DB_sf_wgs84 <- st_transform(DB_sf, crs = 4326)
DB_sf_wgs84$YearPost20XX <- DB_sf_wgs84$Year
DB_sf_wgs84$YearPost20XX[DB_sf_wgs84$YearPost20XX<2016] <- 2016

DB_shared <- SharedData$new(DB_sf_wgs84, group = "lux_group")


m@map <- m@map %>%
  addCircleMarkers(
    data = DB_shared,
    popup = ~paste0(ID, " (", Source, ", ", YearPost20XX, ")"),
    radius = 1,
    color = "blue",
    fillOpacity = 0.7
  )

# Adding filters

slider <- filter_slider(
  id = "year_filter",
  label = "Year (cumulated observations)",
  sharedData = DB_shared,
  column = ~YearPost20XX,
  step = 1,
  animate = TRUE,
  sep = " ",
  ticks=TRUE,
  width="10cm"
)

source_filter <- filter_checkboxSP(
  id = "source_filter",
  label = "Data sources",
  sharedData = DB_shared,
  group = ~Source,
  inline = TRUE,
  allLevels = FALSE,
  columns = 1
)
carte1 <- bscols(widths = c(12, 12, 12), slider, source_filter, m@map)


###### Geology map ----


m2 <-  mapview(uniteGeo, zcol = "CODESTRATUNIT", col.regions = colorRampPalette(RColorBrewer::brewer.pal(12, "Set3"))(n_niveaux), legend = FALSE, homebutton = FALSE,  popup = FALSE) +
      #mapview(contours, color = "#F5F5DC",lwd = 1,  legend = FALSE,  homebutton = FALSE) +
      mapview( failles, color = "red",  lwd = 1,legend = FALSE, homebutton = FALSE ) 
  

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
  groupOptions("Labels", zoomLevels = 14:52
  ) 

m2


###### Species Account Map ----

DB2s <- DB2[which(DB2$ID == "Blera fallax"),]


rtp_wgs84 <- st_transform(rtp_sf, 4326)

# Precense in one cell
presence_cell <- unique(DB2s$Cell)
rtp_presence <- subset(rtp_wgs84, layer %in% presence_cell)
DB_sf <- st_as_sf(DB2s, coords = c("Long", "Lat"), crs = 4326)

# Data sources summary per cell
source_cell <- DB2s |> 
  group_by(Cell, Source) |> 
  summarise(
    Number = n(),
    .groups = "drop"
  )

source_summary <- source_cell |>
  group_by(Cell) |>
  summarise(
    Source_summary = paste0(Source, ": ", Number, collapse = "<br>"),
    .groups = "drop"
  )


# Observations per cell

obs_cell <- DB2s |> 
  group_by(Cell) |> 
  summarise(
    Observation=n(),
    .groups = "drop")


# rtp presence

rtp_presence <- merge(
  rtp_presence,
  obs_cell,
  by.x = "layer",
  by.y = "Cell"
)

rtp_presence <- merge(
  rtp_presence,
  source_summary,
  by.x = "layer",
  by.y = "Cell"
)


m3 <- mapView(
  rtp,
  method = "ngb", 
  na.color = rgb(0, 0, 255, max = 255, alpha = 0),
  query.type = "click",
  trim = TRUE,
  legend = FALSE,
  map = base_map,
  popup = FALSE,
  alpha.regions = 0,
  alpha = 0.3,
  lwd = 2,
  color = "red",
  layer.name = "Grid"
) + 
  
  mapView(
    rtp_presence,
    color = "red",
    col.regions = col_presence,
    alpha.regions = 0.5,
    lwd = 1,
    label = rtp_presence$layer,
    legend = FALSE,
    popup = paste0(
      rtp_presence$Observation,
      " records<br>","<br>",
      rtp_presence$Source_summary
    ),
    layer.name = "Cells"
  ) +
  
  mapView(
    DB_sf,
    col.regions ="red",
    color = "red",
    cex = 4,
    legend = FALSE,
    layer.name = "Points",
    alpha.regions = 1
    , popup = paste0("<strong>Source : ",DB2s$Source,"<br>"
                    # , "Identifier : ", DB2$ID 
                     )
  )


m3@map <- m3@map %>%
  groupOptions("Cells", zoomLevels = 0:11) %>%
  groupOptions( "Points",zoomLevels = 12:52 )

m3






###### Species Richness Map ----

DB_rich <- DB2





# nb species + species list per cell
richness_cell <- DB_rich |>
  group_by(Cell) |>
  summarise(Richness = n_distinct(ID), Species_list = paste(unique(ID), collapse = "<br>"),
            .groups = "drop")



# subset cell
rtp_richness <- subset( rtp_wgs84, layer %in% richness_cell$Cell)

# info grid
rtp_richness <- merge( rtp_richness,  richness_cell,by.x = "layer",by.y = "Cell")
rtp_centroid <- st_centroid(rtp_richness[,c("layer","Richness")])


# map

m4 <- mapView(
  rtp,
  method = "ngb", 
  na.color = rgb(0, 0, 255, max = 255, alpha = 0),
  query.type = "click",
  trim = TRUE,
  legend = FALSE,
  map = base_map,
  popup = FALSE,
  alpha.regions = 0,
  alpha = 0.3,
  lwd = 2
) + 
  
  mapView(
  rtp_richness,
  label = rtp_richness$layer,
  zcol = "Richness",
  col.regions = colorRampPalette(
    c("white", "orange", "red")
  )(50),
  alpha.regions = 0.7,
  lwd = 1,
  legend = TRUE,
  popup = paste0(
    rtp_richness$Species_list),
    layer.name = "Number of species recorded") 

rtp_centroid

m4@map <- m4@map %>%
  addLabelOnlyMarkers(
    data = rtp_centroid,
    label = ~Richness,
    group = "Labels",
    labelOptions = labelOptions(
      noHide = TRUE,
      direction = "center",
      textOnly = TRUE,
      style = list("font-size" = "10px", "font-weight" = "bold", "color" = "black")
    ))
 
m4
