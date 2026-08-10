######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Comparaison Cell (saisie manuelle) vs RightCell (calculée depuis le GPS)



## Lignes ou Cell ET RightCell sont toutes deux renseignées
comparables <- !is.na(HN$Cell) & !is.na(HN$RightCell)
sum(comparables)
nrow(HN)
# 7272 sur 7334

## Comparaison deux colonnes
match <- HN$Cell == HN$RightCell
table(match[comparables], useNA = "ifany")

## Vue sur les lignes avec valeurs différentes
erreurs <- HN %>%
  filter(comparables & !match) %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date)

print(erreurs, n = Inf)

## Cell renseignée mais RightCell manquante
manque_rightcell <- HN %>%
  filter(!is.na(Cell) & is.na(RightCell)) %>%
  select(Code, Cell, Longitude, Latitude, Date)
nrow(manque_rightcell)

## Regrouper les lignes en erreur par événement 
erreurs_uniques <- erreurs %>%
  distinct(Cell, RightCell, Longitude, Latitude, Collecteur, Date, .keep_all = TRUE)
nrow(erreurs_uniques)


###### Distinction cellule voisine vs erreur ----

## 8 voisins
voisins_liste <- st_touches(rtp_sf, rtp_sf)

## index de polygone -> nom de cellule
noms_cellules <- rtp_sf$layer

voisins_par_cellule <- setNames(
  lapply(voisins_liste, function(idx) noms_cellules[idx]),
  noms_cellules
)

## Vérification du statut de voisin
erreurs_uniques$est_voisin <- mapply(function(cell, rightcell) {
  voisins_de_rightcell <- voisins_par_cellule[[as.character(rightcell)]]
  if (is.null(voisins_de_rightcell)) return(NA)
  cell %in% voisins_de_rightcell
}, erreurs_uniques$Cell, erreurs_uniques$RightCell)

table(erreurs_uniques$est_voisin)

## Cellules voisines 
erreurs_voisines <- erreurs_uniques %>% filter(est_voisin == TRUE)
nrow(erreurs_voisines)

## Écarts suspects
erreurs_suspectes <- erreurs_uniques %>% filter(est_voisin == FALSE)
nrow(erreurs_suspectes)

# Affichage complet et sécurisé avec les codes
erreurs_suspectes %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date) %>%
  print(n = Inf)

## Récupérer toutes les lignes d'observations
codes_suspects <- HN %>%
  filter(Cell %in% erreurs_suspectes$Cell & 
           RightCell %in% erreurs_suspectes$RightCell) %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date)
print(codes_suspects, n = Inf)


HN$Erreur <- mapply(function(i, j) i %in% voisins_par_cellule[[as.character(j)]],
                    HN$Cell, HN$RightCell)

###### Bilan coordonnées non exploitables ----

## Lignes sans Longitude/ Latitude
cat("Long ou Lat manquante :", 
    sum(is.na(HN$Longitude) | is.na(HN$Latitude)), "\n")

## Lignes avec coordonnées mais hors bornes Luxembourg
cat("Non-NA mais hors bornes LU :", 
    sum(!is.na(HN$Longitude) & !is.na(HN$Latitude) &
          !(HN$Longitude >= 5.6 & HN$Longitude <= 6.6 &
              HN$Latitude >= 49.3 & HN$Latitude <= 50.3)), "\n")
table_voisins <- utils::stack(voisins_par_cellule)
HN$TFCell <- HN$Cell %in% voisins_par_cellule 

# Caroline Grounds 2023-06-06


View(HN[HN$Collecteur == "Caroline Grounds" & HN$Date == "2023-06-06",])





library(dplyr)
library(leaflet)

library(dplyr)
library(leaflet)

map_observers <- function(data = HN, Collecteur = NULL, Date = NULL) {
  
  df <- data %>%
    filter(!is.na(Latitude), !is.na(Longitude))
  

  if (!is.null(Collecteur) && nzchar(Collecteur)) {
    search_term <- Collecteur  #
    df <- df %>%
      filter(grepl(search_term, .data$Collecteur, ignore.case = TRUE))
  }
  

  if (!is.null(Date) && any(nzchar(Date))) {
    if (length(Date) == 1) {
      d <- as.Date(Date)
      df <- df %>% filter(.data$Date == d)
    } else if (length(Date) == 2) {
      d1 <- as.Date(Date[1])
      d2 <- as.Date(Date[2])
      df <- df %>% filter(.data$Date >= d1, .data$Date <= d2)
    }
  }
  
  
  
  leaflet(df) %>%
    addTiles() %>%
    addCircleMarkers(
      lng = ~Longitude,
      lat = ~Latitude,
      radius = 5,
      stroke = TRUE,
      color = "darkblue",
      fillOpacity = 0.7,
      popup = ~paste0(
        "<b>Collecteur :</b> ", Collecteur, "<br>",
        "<b>Date :</b> ", format(Date, "%d-%m-%Y"), "<br>",
        "<b>Espèce identifiée :</b> ", ID, "<br>"

      )
    )
}


# une date précise
map_observers(Collecteur = "Caroline Grounds", Date = "2023-06-06")




