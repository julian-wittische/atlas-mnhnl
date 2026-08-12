######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Script objective : Comparaison Cell (saisie manuelle) vs RightCell (calculée depuis le GPS) — Bycatch


############ Lignes comparables (Lignes où Cell ET RightCell sont toutes deux renseignées) ----
comparables <- !is.na(BC$Cell) & !is.na(BC$RightCell)
sum(comparables)
nrow(BC)

############ Correspondance Cell == RightCell sur les lignes comparables ----
match <- BC$Cell == BC$RightCell
table(match[comparables], useNA = "ifany")

############ Détail des lignes avec valeurs différentes ----
erreurs <- BC %>%
  filter(comparables & !match) %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date)

print(erreurs, n = Inf)

############ Cas où RightCell n'a pas pu être calculée (pas de GPS exploitable) ----
manque_rightcell <- BC %>%
  filter(!is.na(Cell) & is.na(RightCell)) %>%
  select(Code, Cell, Longitude, Latitude, Date)
nrow(manque_rightcell)


############ Dédoublonnage des erreurs ----
erreurs_uniques <- erreurs %>%
  distinct(Cell, RightCell, Longitude, Latitude, Collecteur, Date, .keep_all = TRUE)
nrow(erreurs_uniques)

###### Distinction cellule voisine vs erreur ----
voisins_liste <- st_touches(rtp_sf, rtp_sf)
noms_cellules <- rtp_sf$layer
voisins_par_cellule <- setNames(
   lapply(voisins_liste, function(idx) noms_cellules[idx]),
   noms_cellules
)

############ Pour chaque erreur unique : vérification si voisin ou non ----
erreurs_uniques$est_voisin <- mapply(function(cell, rightcell) {
  voisins_de_rightcell <- voisins_par_cellule[[as.character(rightcell)]]
  if (is.null(voisins_de_rightcell)) return(NA)
  cell %in% voisins_de_rightcell
}, erreurs_uniques$Cell, erreurs_uniques$RightCell)

table(erreurs_uniques$est_voisin)

############ Cell voisine de RightCell (probable imprécision) ----
erreurs_voisines <- erreurs_uniques %>% filter(est_voisin == TRUE)
nrow(erreurs_voisines)

############ Erreurs suspectes : Cell ni égale ni voisine de RightCell ----
erreurs_suspectes <- erreurs_uniques %>% filter(est_voisin == FALSE)
nrow(erreurs_suspectes)

erreurs_suspectes %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date) %>%
  print(n = Inf)

############ Retrouver dans BC toutes les lignes correspondant à ces combinaisons Cell/RightCell suspectes ----
codes_suspects <- BC %>%
  filter(Cell %in% erreurs_suspectes$Cell &
           RightCell %in% erreurs_suspectes$RightCell) %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date)
print(codes_suspects, n = Inf)

############ Marque pour les lignes de BC, si Cell est voisine de RightCell ----
BC$Erreur <- mapply(function(i, j) {
  voisins_de_j <- voisins_par_cellule[[as.character(j)]]
  if (is.null(voisins_de_j)) return(NA)
  i %in% voisins_de_j
}, BC$Cell, BC$RightCell)

###### Bilan coordonnées non exploitables ----
cat("Long ou Lat manquante :",
    sum(is.na(BC$Longitude) | is.na(BC$Latitude)), "\n")

cat("Non-NA mais hors bornes LU :",
    sum(!is.na(BC$Longitude) & !is.na(BC$Latitude) &
          !(BC$Longitude >= 5.6 & BC$Longitude <= 6.6 &
              BC$Latitude >= 49.3 & BC$Latitude <= 50.3)), "\n")

BC$TFCell <- BC$Cell %in% unlist(voisins_par_cellule)

############ Carte des erreurs graves (Cell ni égale ni voisine de RightCell) ----
map_erreurs_graves <- function(data, rtp, base_map) {
  
  df <- data %>%
    filter(!is.na(Latitude), !is.na(Longitude))
  
  rtp_sf <- st_as_sf(rtp)
  rtp_wgs84 <- st_transform(rtp_sf, 4326)
  
  df_sf <- st_as_sf(
    df,
    coords = c("Longitude", "Latitude"),
    crs = 4326
  )
  
  map_erreurs_graves <- mapView(
    rtp_wgs84,
    color = "red",
    alpha.regions = 0,
    lwd = 2,
    label = rtp_wgs84$layer,
    popup = FALSE,
    legend = FALSE,
    map = base_map,
    layer.name = "Grid"
  ) +
    
    mapView(
      df_sf,
      color = "orange",
      cex = 5,
      alpha.regions = 0.7,
      legend = FALSE,
      layer.name = "Erreurs graves",
      popup = paste0(
        "<b>Collecteur :</b> ", df$Collecteur, "<br>",
        "<b>Date :</b> ", format(df$Date, "%d-%m-%Y"), "<br>",
        "<b>Cell notée :</b> ", df$Cell, "<br>",
        "<b>Cell calculée :</b> ", df$RightCell, "<br>",
        "<b>CODE :</b> ", df$Code, "<br>"
      )
    )
  
  map_erreurs_graves
}

############ Exemple d'appel : toutes les erreurs graves BC ----
map_erreurs_graves(data = codes_suspects, rtp = rtp, base_map = base_map)

