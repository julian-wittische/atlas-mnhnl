######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Load and clean up data


############ Load and preprocess observations ----

###### Bycatch data (pan traps / malaise traps) ----
BC1 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 3)
BC2 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 7)
BC3 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 8)
BC6 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 11)
BC7 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 12)

# add origine of the data = Source
BC1$Source <- "Pan traps"
BC2$Source <- "Pan traps"
BC3$Source <- "Malaise traps"
BC6$Source <- "Malaise traps"
BC7$Source <- "Pan traps"

BC <- rbind(BC1, BC2)
BC <- rbind(BC, BC3)
BC <- rbind(BC, BC6)
BC <- rbind(BC, BC7)

BC$Longitude[BC$Longitude == 2723371] <- 5.98

###### Hand netting data ----
HN1 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 1)
HN2 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 2)
HN3 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 3)
HN4 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 4)
HN5 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 5)


HN <- rbind(HN1, HN2)
HN <- rbind(HN, HN4)
HN <- rbind(HN, HN5)

# add origine of the data = Source
HN$Source <- "Hand netting"

###### MNHNL data (Mdata) ----
MD <- read.csv(paste0(DATAPATH, "Mdata.csv"), header = TRUE, encoding = "latin1")
colnames(MD)[17] <- "Source"
MD$Year <- format(as.Date(MD$date_start, format = "%d/%m/%Y"), "%Y")

############ Combine into master observation table (DB) ----
DB <- rbind(BC, HN)

# check the number of individuals
sum(DB[, 19], na.rm = TRUE)

# Keep only necessary data
# TODO: remplacer par des noms de colonnes, indices fragiles si le fichier source change
DB <- DB[, c(2, 3, 17, 29, 8)]
colnames(DB)[1] <- "Lat"
colnames(DB)[2] <- "Long"
colnames(DB)[5] <- "Year"

MD <- MD[, c(11, 12, 5, 17, 28)]
colnames(MD)[3] <- "ID"

DB <- rbind(DB, MD)
DB[(DB$Source %in% c("Inaturalist", "Observation.org")), "Source"] <- "Citizen science"
DB[!(DB$Source %in% c("Citizen science", "Hand netting", "Malaise traps", "Pan traps")), "Source"] <- "MNHNL"

# TODO: suppression par position fixe (ligne 517) - fragile si les données source changent
DB <- DB[c(-517), ] # problematic WBA's sample

DB$Long <- as.numeric(DB$Long)
DB$Lat  <- as.numeric(DB$Lat)
DB$Year <- as.numeric(DB$Year)

DB <- DB[complete.cases(DB$Long), ]
DB <- DB[complete.cases(DB$Lat), ]
DB <- DB[complete.cases(DB$Year), ]

###### Make DB spatial ----
DB_sf <- st_as_sf(DB, coords = c("Long", "Lat"), crs = st_crs(4326))

DB_sf <- DB_sf %>%
  st_crop(bbox) %>%
  st_transform("EPSG:2169")

MD_identifier <- na.omit(unique(MD$Recorders))
MD_identifier <- MD_identifier[trimws(MD_identifier) != ""]
MD_identifier <- MD_identifier[is.na(suppressWarnings(as.numeric(MD_identifier)))]
MD_identifier <- sort(MD_identifier)

############ Build dataset for Species Account ----
DB2 <- rbind(BC, HN)


DB2 <- DB2[, c(2, 3, 4, 17, 29, 8)]
colnames(DB2)[1] <- "Lat"
colnames(DB2)[2] <- "Long"
colnames(DB2)[6] <- "Year"

DB2$Long <- as.numeric(DB2$Long)
DB2$Lat  <- as.numeric(DB2$Lat)
DB2$Year <- as.numeric(DB2$Year)

# make MD spatial
MD_sf <- st_as_sf(MD, coords = c("Long", "Lat"), crs = 4326)
MD_sf <- st_transform(MD_sf, 2169)

# grille
rtp_sf <- st_as_sf(rtp)
rtp_sf <- st_transform(rtp_sf, st_crs(MD_sf))

# jointure
MD_sf <- st_join(MD_sf, rtp_sf)

# nouvelle colonne
MD <- cbind(MD, Cell = MD_sf$layer)
MD <- MD[, c("Lat", "Long", "Cell", "ID", "Source", "Year")]

DB2 <- rbind(DB2, MD)
DB2$Cell <- as.numeric(DB2$Cell)
DB2[(DB2$Source %in% c("Inaturalist", "Observation.org")), "Source"] <- "Citizen science"
DB2[!(DB2$Source %in% c("Citizen science", "Hand netting", "Malaise traps", "Pan traps")), "Source"] <- "MNHNL"

DB2 <- DB2[c(-517), ] # problematic WBA's sample

DB2 <- DB2[complete.cases(DB2[, c("Long", "Lat", "Cell", "Year")]), ]








############ Build dataset to add date to DB ----


###### Bycatch data (pan traps / malaise traps) ---
BC1 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 3)
BC2 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 7)
BC3 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 8)
BC6 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 11)
BC7 <- read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 12)



# add origine of the data = Source
BC1$Source <- "Pan traps"
BC2$Source <- "Pan traps"
BC3$Source <- "Malaise traps"
BC6$Source <- "Malaise traps"
BC7$Source <- "Pan traps"

BC <- rbind(BC1, BC2)
BC <- rbind(BC, BC3)
BC <- rbind(BC, BC6)
BC <- rbind(BC, BC7)

BC$Longitude[BC$Longitude == 2723371] <- 5.98

# correction date 5 chiffres

date_5chiffres <- function(x) {
  x <- ifelse(tolower(x) == "na", NA, x)  # uniformiser NA
  x <- as.character(str_extract(x, "\\d+$"))
  x <- ifelse(nchar(x) == 5, paste0("0", x), x) # ajouter un 0
  ifelse(nchar(x) %in% c(6, 8) & !is.na(suppressWarnings(as.numeric(x))), x, NA)# garder valeurs exploitables
}

dmy(date_5chiffres("'020623"))

BC$Date <- dmy(date_5chiffres(BC$Date_out))

###### Hand netting data ----
HN1 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 1)
HN2 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 2)
HN3 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 3)
HN4 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 4)
HN5 <- read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 5)

HN <- rbind(HN1, HN2)
HN <- rbind(HN, HN4)
HN <- rbind(HN, HN5)

# add origine of the data = Source

HN$Source <- "Hand netting"
HN$Date <- dmy(date_5chiffres(HN$Date_out))

###### MNHNL data (Mdata) ---

MD <- read.csv(paste0(DATAPATH, "Mdata.csv"), header = TRUE, encoding = "latin1")
colnames(MD)[17] <- "Source"
MD$Year <- format(as.Date(MD$date_start, format = "%d/%m/%Y"), "%Y")
MD$Date <- as.Date(MD$date_start, format = "%d/%m/%Y")

############ Combine into master observation table (DB3) ---

DB3 <- rbind(BC, HN)

# check the number of individuals
sum(DB3[, 19], na.rm = TRUE)


# RESULT: OK

# Keep only necessary data
DB3 <- DB3[, c(2, 3, 17, 29, 8, which(colnames(DB3) == "Date"))]


colnames(DB3)[1] <- "Lat"
colnames(DB3)[2] <- "Long"
colnames(DB3)[5] <- "Year"
MD2 <- MD[, c(11, 12, 5, 17, 28, which(colnames(MD) == "Date"))]
colnames(MD2)[3] <- "ID"
DB3 <- rbind(DB3, MD2)
DB3[(DB3$Source %in% c("Inaturalist", "Observation.org")), "Source"] <- "Citizen science"
DB3[!(DB3$Source %in% c("Citizen science", "Hand netting", "Malaise traps", "Pan traps")), "Source"] <- "MNHNL"

# suppression 
DB3 <- DB3[c(-517), ] # problematic WBA's sample


DB3$Long <- as.numeric(DB3$Long)
DB3$Lat  <- as.numeric(DB3$Lat)
DB3$Year <- as.numeric(DB3$Year)
DB3 <- DB3[complete.cases(DB3$Long), ]
DB3 <- DB3[complete.cases(DB3$Lat), ]
DB3 <- DB3[complete.cases(DB3$Year), ]
DB3 <- DB3[complete.cases(DB3$Date), ]


################################################################################
# Checkpoint (désactivé)
# print(DB3[DB3$Lat %in% c("49.71013",
#                               "49.7101297")
#           & DB3$ID %in% c("Pipizella virens",
#                           "Pipizella viduata",
#                           "Triglyphus primus",
#                           "Eristalis arbustorum"),
#           ])
################################################################################

###### Make DB3 spatial ----
DB_sf <- st_as_sf(DB3, coords = c("Long", "Lat"), crs = st_crs(4326))
DB_sf <- DB_sf %>%
  st_crop(bbox) %>%
  st_transform("EPSG:2169")

