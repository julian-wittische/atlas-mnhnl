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
      mapview( failles, color = "red",  lwd = 1,legend = FALSE,homebutton = FALSE ) 
  

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




