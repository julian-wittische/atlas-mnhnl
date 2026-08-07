######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Load and clean up data



############ Lecture des sources ----

###### Bycatch (pan traps / malaise traps) ----

BC <- rbind(
  read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 3)  %>% mutate(Source = "Pan traps"),
  read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 7)  %>% mutate(Source = "Pan traps"),
  read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 8)  %>% mutate(Source = "Malaise traps"),
  read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 11) %>% mutate(Source = "Malaise traps"),
  read_xlsx(paste0(DATAPATH, "ID_Bycatch sorting_20260611.xlsx"), sheet = 12) %>% mutate(Source = "Pan traps")
)

date_5chiffres <- function(x) {
  x <- ifelse(tolower(x) == "na", NA, x)  # uniformiser NA
  x <- as.character(str_extract(x, "\\d+$"))
  x <- ifelse(nchar(x) == 5, paste0("0", x), x) # ajouter un 0
  ifelse(nchar(x) %in% c(6, 8) & !is.na(suppressWarnings(as.numeric(x))), x, NA)
}



BC$Longitude[BC$Longitude == 2723371] <- 5.98
BC$Date <- dmy(date_5chiffres(BC$Date_out))

###### Hand netting ----
HN <- rbind(
  read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 1),
  read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 2),
  read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 4),
  read_xlsx(paste0(DATAPATH, "ID_Hand netting atlas_20260611.xlsx"), sheet = 5)
) %>% mutate(Source = "Hand netting")

HN$Date <- dmy(date_5chiffres(HN$Date_out))

# # #####Checkpoint####################################
# # # vue d'ensemble
# table(HN$Longitude)
# table(HN$Latitude)
# # 
# # 
# # # Isoler les NA 
# sum(HN$Longitude == "NA" | is.na(HN$Longitude), na.rm = TRUE)
# sum(HN$Latitude == "NA" | is.na(HN$Latitude), na.rm = TRUE)
# # 
# # # Isoler les lignes avec un caractère
# HN[grepl("[^0-9.\\-]", HN$Longitude) & !is.na(HN$Longitude) & HN$Longitude != "NA", "Longitude"]
# HN[grepl("[^0-9.\\-]", HN$Latitude) & !is.na(HN$Latitude) & HN$Latitude != "NA", "Latitude"]
# # 
# # 
# # 5 lignes notations scientifiques/ 1 avec ,
# # #########################################################


inserer_point <- function(x, pos) {
  x <- gsub("[^0-9]", "", x)  
  paste0(substr(x, 1, pos), ".", substr(x, pos + 1, nchar(x)))
}

HN$Latitude <- gsub(",$", "", HN$Latitude)
HN$Longitude <- as.numeric(sapply(HN$Longitude, inserer_point, pos = 1))
HN$Latitude <- as.numeric(sapply(HN$Latitude, inserer_point, pos = 2))


table(test$plausible, useNA = "ifany")

lon_num <- as.numeric(HN$Longitude)
lat_num <- as.numeric(HN$Latitude)

# Bornes pour le Luxembourg
lon_min <- 5.6; lon_max <- 6.6
lat_min <- 49.3; lat_max <- 50.3



HN_valid <- HN[valides, ]
HN_valid$lon_tmp <- lon_num[valides]
HN_valid$lat_tmp <- lat_num[valides]

HN_sf <- st_as_sf(HN_valid, coords = c("lon_tmp", "lat_tmp"), crs = 4326, remove = FALSE)
rtp_sf <- st_transform(st_as_sf(rtp), st_crs(HN_sf))
HN_cell <- st_join(HN_sf, rtp_sf)$layer

nrow(HN_sf) == length(HN_cell)   

# ajout de la colonne cell calculées a partir des long et lat utilisables
HN$RightCell <- NA
HN$RightCell[valides] <- HN_cell

# 8 voisin


###### MNHNL (Mdata) ----
MD <- read.csv(paste0(DATAPATH, "Mdata.csv"), header = TRUE, encoding = "latin1")
colnames(MD)[17] <- "Source"
MD$Date <- as.Date(MD$date_start, format = "%d/%m/%Y")
MD$Year <- as.numeric(format(MD$Date, "%Y"))


MD_sf <- st_as_sf(MD, coords = c("Long", "Lat"), crs = 4326, remove = FALSE)
rtp_sf <- st_transform(st_as_sf(rtp), st_crs(MD_sf))
MD_cell <- st_join(MD_sf, rtp_sf)$layer
MD$Cell <- MD_cell


############ Table  unique ----

DB_BC <- BC %>%
  select(Lat = Latitude, Long = Longitude, ID, Source, Year = Année, Date, Cell)

DB_HN <- HN %>%
  select(Lat = Latitude, Long = Longitude, ID, Source, Year = Année, Date, Cell)

DB_MD <- MD %>%
  select(Lat, Long, ID = preferred, Source, Year, Date, Cell)

DB <- rbind(DB_BC, DB_HN, DB_MD)

DB$Source[DB$Source %in% c("Inaturalist", "Observation.org")] <- "Citizen science"
DB$Source[!(DB$Source %in% c("Citizen science", "Hand netting", "Malaise traps", "Pan traps"))] <- "MNHNL"

DB <- DB %>%
  mutate(across(c(Long, Lat, Year, Cell), as.numeric)) %>%
  filter(complete.cases(Long, Lat, Year)) %>%
  slice(-517)  #

###### Version spatiale ----
DB_sf <- st_as_sf(DB, coords = c("Long", "Lat"), crs = 4326) %>%
  st_transform("EPSG:2169")
  #st_crop(bbox) %>%   # !! Cela va cacher les erreurs dans les coordonnées
  



###### DB étendu (colonnes supplémentaires IDENTIFICATEUR, OBSERVATEUR, ETC) ----

DB_BC_full <- BC %>%
  mutate(Observateur = Collecteur, Identifieur = IDENTIFIER, Origin = Source, URL = NA_character_) %>%
  select(Lat = Latitude, Long = Longitude, ID, Source, Origin, Year = Année, Date, Cell,
         Observateur, Identifieur, URL)

DB_HN_full <- HN %>%
  mutate(Observateur = Collecteur, Identifieur = IDENTIFIER, Origin = Source, URL = NA_character_) %>%
  select(Lat = Latitude, Long = Longitude, ID, Source, Origin, Year = Année, Date, Cell,
         Observateur, Identifieur, URL)

DB_MD_full <- MD %>%
  mutate(
    ID = preferred,
    Observateur = Recorders,
    Identifieur = Determiner,
    Origin = case_when(
      startsWith(Observation_Key, "INAT_") ~ "Inaturalist",
      startsWith(Observation_Key, "oOrg_") ~ "Observation.org",
      TRUE ~ "MNHNL"
    ),
    URL = case_when(
      Origin == "Inaturalist" ~ paste0("https://www.inaturalist.org/observations/", sub("^INAT_", "", Observation_Key)),
      Origin == "Observation.org" ~ paste0("https://observation.org/observation/", sub("^oOrg_", "", Observation_Key), "/"),
      TRUE ~ NA_character_
    )
  ) %>%
  select(Lat, Long, ID, Source, Origin, Year, Date, Cell, Observateur, Identifieur, URL)

DB_full <- rbind(DB_BC_full, DB_HN_full, DB_MD_full)

DB_full$Source[DB_full$Origin %in% c("Inaturalist", "Observation.org")] <- "Citizen science"
DB_full$Source[!(DB_full$Source %in% c("Citizen science", "Hand netting", "Malaise traps", "Pan traps"))] <- "MNHNL"

DB_full <- DB_full %>%
  mutate(across(c(Long, Lat, Year, Cell), as.numeric)) %>%
  filter(complete.cases(Long, Lat, Year)) %>%
  slice(-517)  


rm(DB_BC_full , DB_HN_full, DB_MD_full,DB_BC , DB_HN, DB_MD)
