######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Comparaison Cell (saisie manuelle) vs RightCell (calculée depuis le GPS)


############ Lignes comparables (Lignes ou Cell ET RightCell sont toutes deux renseignées) ----
comparables <- !is.na(HN$Cell) & !is.na(HN$RightCell)
sum(comparables)
nrow(HN)
# 7272 sur 7334

############ Correspondance Cell == RightCell sur les lignes comparables ----
match <- HN$Cell == HN$RightCell
table(match[comparables], useNA = "ifany")

############ Détail des lignes où avec valeurs différentes ----
erreurs <- HN %>%
  filter(comparables & !match) %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date)

print(erreurs, n = Inf)

############ Cas où RightCell n'a pas pu être calculée (pas de GPS exploitable) ----
manque_rightcell <- HN %>%
  filter(!is.na(Cell) & is.na(RightCell)) %>%
  select(Code, Cell, Longitude, Latitude, Date)
nrow(manque_rightcell)

 
############ Dédoublonnage des erreurs (une même erreur peut se répéter sur plusieurs insectes d'une même sortie -> on ne garde qu'une ligne par combinaison unique) ----
erreurs_uniques <- erreurs %>%
  distinct(Cell, RightCell, Longitude, Latitude, Collecteur, Date, .keep_all = TRUE)
nrow(erreurs_uniques)

###### Distinction cellule voisine vs erreur ----
# objectif : une Cell saisie à la main qui tombe sur la cellule VOISINE de RightCell est probablement juste une imprécision
# (pas une vraie erreur de saisie) ; une Cell qui n'est même pas voisine est plus suspecte

############ Liste d'adjacence des cellules de la grille (8 voisins) ----
voisins_liste <- st_touches(rtp_sf, rtp_sf)

# index de polygone -> nom de cellule
noms_cellules <- rtp_sf$layer

# transforme la liste d'adjacence (indices de polygones) en liste nommée
# cellule -> vecteur des noms de ses cellules voisines
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

# Affichage complet
erreurs_suspectes %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date) %>%
  print(n = Inf)

############ Retrouver dans HN  toutes les lignes correspondant à ces combinaisons Cell/RightCell suspectes (pas seulement une ligne par événement) ----
codes_suspects <- HN %>%
  filter(Cell %in% erreurs_suspectes$Cell & 
           RightCell %in% erreurs_suspectes$RightCell) %>%
  select(Code, Cell, RightCell, Longitude, Latitude, Collecteur, Date)
print(codes_suspects, n = Inf)


############ Marque pour les lignes de HN, si Cell est voisine de RightCell ----
HN$Erreur <- mapply(function(i, j) {
  voisins_de_j <- voisins_par_cellule[[as.character(j)]]
  if (is.null(voisins_de_j)) return(NA)
  i %in% voisins_de_j
}, HN$Cell, HN$RightCell)

###### Bilan coordonnées non exploitables ----
############ Décompte des lignes sans coordonnées----
cat("Long ou Lat manquante :", 
    sum(is.na(HN$Longitude) | is.na(HN$Latitude)), "\n")


############ Décompte des lignes avec coordonnées mais hors des bornes LU (lon 5.6-6.6,lat 49.3-50.3)
cat("Non-NA mais hors bornes LU :", 
    sum(!is.na(HN$Longitude) & !is.na(HN$Latitude) &
          !(HN$Longitude >= 5.6 & HN$Longitude <= 6.6 &
              HN$Latitude >= 49.3 & HN$Latitude <= 50.3)), "\n")

# une ligne par paire cellule/voisin
table_voisins <- utils::stack(voisins_par_cellule)

############ Marque si Cell apparaît comme voisine ----
HN$TFCell <- HN$Cell %in% unlist(voisins_par_cellule)

############ Vérification  d'un événement précis ----
# View(HN[HN$Collecteur == "Caroline Grounds" & HN$Date == "2023-06-06",])

############ Carte interactive des observations ----
map_observers <- function(data = HN, Collecteur = NULL, Date = NULL, rtp, base_map) {
  
  df <- data %>%
    filter(!is.na(Latitude), !is.na(Longitude))
  
  if (!is.null(Collecteur) && nzchar(Collecteur)) {
    search_term <- Collecteur
    df <- df %>%
      filter(grepl(search_term, .data$Collecteur, ignore.case = TRUE))
  }
  
  if (!is.null(Date) && any(nzchar(Date))) {
    if (length(Date) == 1) {
      d <- as.Date(Date)
      df <- df %>%
        filter(.data$Date == d)
    } else if (length(Date) == 2) {
      
      d1 <- as.Date(Date[1])
      d2 <- as.Date(Date[2])
      df <- df %>%
        filter(.data$Date >= d1, .data$Date <= d2)
    }
  }
  
  rtp_sf <- st_as_sf(rtp)
  rtp_wgs84 <- st_transform(rtp_sf, 4326)
  
  df_sf <- st_as_sf(
    df,
    coords = c("Longitude", "Latitude"),
    crs = 4326
  )
  
  map_observers <- mapView(
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
      color = "blue",
      cex = 5,
      alpha.regions = 0.7,
      legend = FALSE,
      layer.name = "Observations",
      popup = paste0(
        "<b>Collecteur :</b> ", df$Collecteur, "<br>",
        "<b>Date :</b> ", format(df$Date, "%d-%m-%Y"), "<br>",
        "<b>Espèce identifiée :</b> ", df$ID, "<br>",
        "<b>CODE :</b> ", df$Code, "<br>"
      )
    )
  
  map_observers
}
############ Exemple d'appel : observations d'un collecteur à une date donnée ----
map_observers(Collecteur = "Caroline Grounds", Date = "2023-06-06", rtp = rtp,base_map = base_map)
