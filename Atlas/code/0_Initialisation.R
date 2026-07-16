######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Load libraries


############ Reading files ----
library(readxl)

############ GIS ----
library(sf)
library(sp)
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
library(cowplot)

############ Data manipulation ----
library(tidyverse)
library(dplyr)
library(lubridate)
library(rcol)


source(here::here("Atlas", "code", "1_config.R"))
source(here::here("Atlas", "code", "utils.R"))
source(here::here("Atlas", "code", "2_LoadBorders.R"))
source(here::here("Atlas", "code", "3_LoadData.R"))
source(here::here("Atlas", "code", "4_MainMap.R"))
source(here::here("Atlas", "code", "5_SpeciesMaps.R"))
source(here::here("Atlas", "code", "6_PresenceMois.R"))
