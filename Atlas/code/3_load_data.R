# load libraries and datapath before this script
source("Atlas/code/1_config.R")

#import database from different tab of the doc
BC1 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"),sheet=3)
BC2 <- read_xlsx(paste0(DATAPATH,"ID_Bycatch sorting_20260611.xlsx"),sheet=7)
BC3 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"),sheet=8)
BC6 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"),sheet=11)
BC7 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"),sheet=12)

HN1 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"),sheet=1)
HN2 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"),sheet=2)
HN3 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"),sheet=3)
HN4 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"),sheet=4)
HN5 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"),sheet=5)

# add origine of the data = Source
BC1$Source <- "Pan traps"
BC2$Source <- "Pan traps"
BC3$Source <- "Malaise traps"
BC6$Source <- "Malaise traps"
BC7$Source <- "Pan traps"

MD <- read.csv(paste0(DATAPATH,"Mdata.csv"), header=TRUE, encoding="latin1")
colnames(MD)[17] <- "Source"
MD$Year <- format(as.Date(MD$date_start, format="%d/%m/%Y"),"%Y")

# combine them
BC <- rbind(BC1, BC2)
BC <- rbind(BC, BC3)
BC <- rbind(BC, BC6)
BC <- rbind(BC, BC7)

HN <- rbind(HN1, HN2)
HN <- rbind(HN, HN4)
HN <- rbind(HN, HN5)

# add origine of the data = Source
HN$Source <-"Hand netting"

DB <- rbind(BC, HN)

# check the number of individuals
sum(DB[, 19], na.rm = TRUE)

# Keep only necessary data
DB<- DB[,c(2,3,17,29,8)]
colnames(DB)[1] <- "Lat"
colnames(DB)[2] <- "Long"
colnames(DB)[5] <- "Year"

MD <- MD[,c(11,12,5,17,28)]
colnames(MD)[3] <- "ID"

DB <- rbind(DB,MD)
DB[(DB$Source %in% c("Inaturalist", "Observation.org")), "Source"] <- "Citizen science"
DB[!(DB$Source %in% c("Citizen science","Hand netting","Malaise traps","Pan traps")),"Source"] <- "MNHNL"
DB<- DB[c(-517),] # problematic WBA's sample

DB$Long <- as.numeric(DB$Long)
DB$Lat <- as.numeric(DB$Lat)
DB$Year <- as.numeric(DB$Year)

DB <- DB[complete.cases(DB$Long),]
DB <- DB[complete.cases(DB$Lat),]
DB <- DB[complete.cases(DB$Year),]

source("Atlas/code/2_load_borders.R")

###### Make DB spatial ----
DB_sf <- st_as_sf(DB,coords=c("Long", "Lat"), crs = st_crs(4326))

DB_sf <- DB_sf %>%
  st_crop(bbox) %>%
  st_transform("EPSG:2169")

# rm(BC1, BC2, BC3, BC6, BC7, HN1, HN2, HN3, HN4, HN5, BC, HN, MD)


# ###### Geology ---
# 
# symbole  <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/1")
# uniteGeo <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/6")
# failles  <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/2")
# contours <- st_read("OAPIF:https://features.geoportail.lu/", layer = "2167/3")
# 
# 
# uniteGeo <- st_transform(uniteGeo, crs = st_crs(lux_borders))
# contours <- st_transform(contours, crs = st_crs(lux_borders))
# failles  <- st_transform(failles,  crs = st_crs(lux_borders))
# symbole  <- st_transform(symbole,  crs = st_crs(lux_borders))


###### Species Account ---

DB2 <- rbind(BC, HN)

DB2<- DB2[,c(2,3, 4 ,17,29,8)]
colnames(DB2)[1] <- "Lat"
colnames(DB2)[2] <- "Long"
colnames(DB2)[6] <- "Year"

DB2$Long <- as.numeric(DB2$Long)
DB2$Lat <- as.numeric(DB2$Lat)
DB2$Year <- as.numeric(DB2$Year)

# make MD spatial
MD_sf <- st_as_sf(MD,  coords = c("Long", "Lat"), crs = 4326)
MD_sf <- st_transform(MD_sf, 2169)

# grille
rtp_sf <- st_as_sf(rtp)
rtp_sf <- st_transform(rtp_sf, st_crs(MD_sf))

# jointure
MD_sf <- st_join(MD_sf, rtp_sf)

# nouvelle colonne
MD <- cbind(MD, Cell = MD_sf$layer)
MD <- MD[, c("Lat", "Long", "Cell", "ID", "Source", "Year")]

DB2 <- rbind(DB2,MD)
DB2$Cell <- as.numeric(DB2$Cell)
DB2[(DB2$Source %in% c("Inaturalist", "Observation.org")), "Source"] <- "Citizen science"
DB2[!(DB2$Source %in% c("Citizen science","Hand netting","Malaise traps","Pan traps")),"Source"] <- "MNHNL"
DB2<- DB2[c(-517),] # problematic WBA's sample


DB2 <- DB2[complete.cases(DB2[,c("Long","Lat","Cell","Year")]),]

