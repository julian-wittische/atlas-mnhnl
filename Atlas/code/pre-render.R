###### PRE-RENDER SCRIPT ----
# Genere automatiquement a chaque rendu du livre

here::i_am("atlas-mnhnl.Rproj")
source(here::here("Atlas", "code", "0_Initialisation.R"))
source(here::here("Atlas", "code", "7_GenerateSpeciesPages.R"))

############ Titres dynamiques ----

titre_book <- paste0("Atlas of ", taxon, " in Luxembourg")
contenu_yml <- readLines(here::here("Atlas", "_quarto.yml"))
contenu_yml <- gsub('^(\\s*title:\\s*).*$', paste0('\\1"', titre_book, '"'), contenu_yml)
writeLines(contenu_yml, here::here("Atlas", "_quarto.yml"))

titre_reel <- paste("Ecology of Luxembourg", taxon)
contenu <- readLines(here::here("Atlas", "ecology.qmd"))
contenu <- gsub('title: ".*"', paste0('title: "', titre_reel, '"'), contenu)
writeLines(contenu, here::here("Atlas", "ecology.qmd"))

titre_history <- paste0("History of ", taxon, " recording in Luxembourg")
contenu2 <- readLines(here::here("Atlas", "history.qmd"))
contenu2 <- gsub('title: ".*"', paste0('title: "', titre_history, '"'), contenu2)
writeLines(contenu2, here::here("Atlas", "history.qmd"))

titre_conservation <- paste0("Conservation of ", taxon, " in Luxembourg")
contenu3 <- readLines(here::here("Atlas", "conservation.qmd"))
contenu3 <- gsub('title: ".*"', paste0('title: "', titre_conservation, '"'), contenu3)
writeLines(contenu3, here::here("Atlas", "conservation.qmd"))

titre_spatial <- paste0("Spatial analysis of ", taxon, " Hoverfly diversity")
contenu4 <- readLines(here::here("Atlas", "spatial.qmd"))
contenu3 <- gsub('title: ".*"', paste0('title: "', titre_spatial, '"'), contenu4)
writeLines(contenu4, here::here("Atlas", "spatial.qmd"))