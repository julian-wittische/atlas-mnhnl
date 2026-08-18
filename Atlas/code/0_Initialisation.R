######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Load libraries


############ Lecture / écriture de fichiers ----
library(readxl)
library(openxlsx)
library(here)
library(glue)
library(jsonlite)

############ Rendu / rapport ----
library(knitr)
library(httr)          # appels API (Catalogue of Life, iNaturalist...)

############ GIS ----
library(sf)
library(sp)
library(raster)
library(terra)
library(geobounds)
library(geodata)       

############ Cartes interactives / widgets ----
library(leaflet)
library(leaflet.extras2)
library(mapview)
library(crosstalk)
library(htmltools)
library(htmlwidgets)

############ Plotting ----
library(ggplot2)
library(ggrepel)
library(ggspatial)
library(ggnewscale)
library(cowplot)
library(patchwork)
library(RColorBrewer)
library(colorspace)
library(rayshader)

############ Data manipulation ----
library(tidyverse)
library(dplyr)
library(purrr)
library(stringr)
library(lubridate)
library(scales)
library(tidyterra)

############ Taxonomie / bibliographie ----
# install.packages("pak")
# pak::pak("CatalogueOfLife/rcol")
library(rcol)           # Catalogue of Life/ rtools needed
library(taxize)
library(bib2df)

############ Graphiques spécialisés  ----
library(collapsibleTree)
library(ggtern)
library(viridis)
library(vegan)


source(here::here("Atlas", "code", "1_config.R"))
source(here::here("Atlas", "code", "utils.R"))
source(here::here("Atlas", "code", "2_LoadBorders.R"))
source(here::here("Atlas", "code", "3_LoadData.R"))
source(here::here("Atlas", "code", "4_MainMap.R"))
source(here::here("Atlas", "code", "5_SpeciesMaps.R"))
source(here::here("Atlas", "code", "6_PresenceMois.R"))


