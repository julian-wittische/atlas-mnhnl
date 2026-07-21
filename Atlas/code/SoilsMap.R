######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Soils map


###### Static Soils map ----

.preparer_legende_sols <- function(sols) {
  couleurs_pecode <- c(
    "1" = "#FCCD76", "2" = "#BAEE81", "3" = "#D9F375", "4" = "#73C88F",
    "5" = "#FCA284", "6" = "#FDC5C3", "7" = "#E58391", "8" = "#A28C92",
    "9" = "#BDCDD5", "10" = "#FC8474", "11" = "#F8E2A9", "12" = "#CCA275",
    "13" = "#FEFB6F", "14" = "#FBDE0C", "15" = "#C3A8C9", "16" = "#FEA739",
    "17" = "#FA8D42", "18" = "#B78D7C", "19" = "#C78F5B", "20" = "#C57871",
    "21" = "#9EE0A9", "22" = "#A5E2FC", "23" = "#AFD788", "24" = "#E2ADE6",
    "25" = "#82B7D4", "27" = "#85A3BB", "26" = "white", "32" = "#E58374", "30" = "grey"
  )
  
  labels_pecode <- c(
    "1"  = "Sols limoneux peu caillouteux, non gleyifiés à modérément gleyifiés, à horizon B structural",
    "2"  = "Sols limono-caillouteux à charge schisto-phylladeuse, non gleyifiés, à horizon B structural",
    "3"  = "Sols limono-caillouteux à charge schisto-phylladeuse altérée, non gleyifiés, à horizon B structural",
    "4"  = "Sols limono-caillouteux à charge schisto-phylladeuse, faiblement à modérément gleyifiés, à horizon B structural",
    "5"  = "Sols limono-caillouteux à charge schisto-gréseuse, non gleyifiés, à horizon B structural",
    "6"  = "Sols limono-caillouteux à charge schisto-gréseuse altérée, non gleyifiés, à horizon B structural",
    "7"  = "Sols limono-caillouteux à charge schisto-gréseuse, faiblement à modérément gleyifiés, à horizon B structural",
    "8"  = "Sols limono-caillouteux à charge argilo-schisto-gréseuse, faiblement à modérément gleyifiés, à horizon B structural",
    "9"  = "Sols limono-caillouteux à charge schisteuse, non gleyifiés, à horizon B structural",
    "10" = "Sols limono- et argilo-caillouteux à charge de galets quartzitiques, non gleyifiés à modérément gleyifiés, à horizon B structural ou textural",
    "11" = "Sols argilo-caillouteux à charge dolomitique, non gleyifiés, à horizon B structural",
    "12" = "Sols argilo-caillouteux à charge calcareuse, non gleyifiés, à horizon B structural",
    "13" = "Sols sableux, limono-sableux et sablo-limoneux, non gleyifiés, à horizon B structural ou textural, sur substrat de grès calcaire, de sable ou d'argile d'altération",
    "14" = "Sols sableux, limono-sableux et sablo-limoneux, faiblement à modérément gleyifiés, sur substrat d'argiles",
    "15" = "Sols sablo-limoneux et sablo-argileux, non gleyifiés, à horizon B structural ou textural, sur substrat de grès bigarré",
    "16" = "Sols sablo-limoneux et limoneux, non gleyifiés à modérément gleyifiés, à horizon B textural",
    "17" = "Sols sablo-limoneux et limoneux, fortement à très fortement gleyifiés, à horizon B textural",
    "18" = "Sols argileux et argileux lourds, non gleyifiés, à horizon B structural ou textural, sur substrat de calcaires",
    "19" = "Sols argileux, non gleyifiés, à horizon B structural ou textural, sur substrat de macigno",
    "20" = "Sols argileux, faiblement à modérément gleyifiés, à horizon B textural, sur substrat de macigno",
    "21" = "Sols argileux, faiblement à modérément gleyifiés, à horizon B textural, sur substrat d'argiles",
    "22" = "Sols argileux, non gleyifiés à modérément gleyifiés, à horizon B textural, sur substrat de grès coquillier",
    "23" = "Sols argileux et argileux lourds, non gleyifiés à modérément gleyifiés, à horizon B structural ou textural, sur substrat de marnes et de calcaires",
    "24" = "Sols argileux et argileux lourds, non gleyifiés, à horizon B structural, sur substrat de marnes",
    "25" = "Sols argileux lourds, faiblement à très fortement gleyifiés, à horizon B structural ou textural, sur substrat de marnes",
    "26" = "Colluvions et Alluvions",
    "27" = "Zones de suintement",
    "30" = "Sols en pente",
    "32" = "Sols en pente"
  )
  
  codes_presents <- as.character(sort(unique(as.numeric(as.character(sols$PECODE)))))
  codes_presents <- codes_presents[codes_presents %in% names(couleurs_pecode)]
  
  list(
    couleurs = couleurs_pecode[codes_presents],
    labels   = labels_pecode[codes_presents]
  )
}


plot_carte_sols <- function(datapath) {
  sols <- sf::st_read(file.path(datapath, "Carte_associations_de_sols"), quiet = TRUE)
  
  prep <- .preparer_legende_sols(sols)
  
  ggplot2::ggplot(sols) +
    ggplot2::geom_sf(ggplot2::aes(fill = factor(PECODE)), color = "white", linewidth = 0.05) +
    ggplot2::scale_fill_manual(values = prep$couleurs, na.value = "grey80", guide = "none") +
    ggplot2::theme_void() +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", color = NA))
}


plot_legende_sols <- function(datapath,
                              ncol_legende = 1,
                              cex_legende = 1.28,
                              x_intersp = 0.5,
                              y_intersp = 0.8) {
  sols <- sf::st_read(file.path(datapath, "Carte_associations_de_sols"), quiet = TRUE)
  
  prep <- .preparer_legende_sols(sols)
  
  par(mar = c(0, 0, 0, 0), xpd = TRUE)
  plot.new()
  legend(
    "center", legend = prep$labels, fill = prep$couleurs, border = "grey40",
    ncol = ncol_legende, cex = cex_legende, bty = "n",
    x.intersp = x_intersp, y.intersp = y_intersp,
    text.width = max(strwidth(prep$labels, cex = cex_legende))
  )
}

