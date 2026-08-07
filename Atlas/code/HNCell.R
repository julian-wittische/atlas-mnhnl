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

## Récupérer toutesles lignes d'observations
codes_suspects <- HN %>%
  filter(Cell %in% erreurs_suspectes$Cell & 
           RightCell %in% erreurs_suspectes$RightCell) %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date)
print(codes_suspects, n = Inf)

###### Bilan coordonnées non exploitables ----

## Lignes sans Longitude/ Latitude
cat("Long ou Lat manquante :", 
    sum(is.na(HN$Longitude) | is.na(HN$Latitude)), "\n")

## Lignes avec coordonnées mais hors bornes Luxembourg
cat("Non-NA mais hors bornes LU :", 
    sum(!is.na(HN$Longitude) & !is.na(HN$Latitude) &
          !(HN$Longitude >= 5.6 & HN$Longitude <= 6.6 &
              HN$Latitude >= 49.3 & HN$Latitude <= 50.3)), "\n")