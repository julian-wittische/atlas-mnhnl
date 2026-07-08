# load libraries and datapath before this script
source("code/1_config.R")

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

source("code/2_load_borders.R")

###### Make DB spatial ----
DB_sf <- st_as_sf(DB,coords=c("Long", "Lat"), crs = st_crs(4326))

DB_sf <- DB_sf %>%
  st_crop(bbox) %>%
  st_transform("EPSG:2169")

rm(BC1, BC2, BC3, BC6, BC7, HN1, HN2, HN3, HN4, HN5, BC, HN, MD)

