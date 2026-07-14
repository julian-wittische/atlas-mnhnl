######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Load libraries

library(here)

source(here::here("Atlas", "code", "1_config.R"))

############ Reading files ----
library(readxl)

############ GIS ----
library(sf)
library(raster)
library(terra)
library(geobounds)

############ Cartes interactives / widgets ----
library(leaflet)
library(leaflet.extras2)
library(mapview)
library(crosstalk)   
library(htmltools)
library(htmlwidgets)

############ Plotting ----
library(RColorBrewer)
library(rayshader)
library(ggplot2)

############ Data manipulation ----
library(tidyverse)
library(dplyr)


library(lubridate)

