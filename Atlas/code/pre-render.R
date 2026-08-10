###### PRE-RENDER SCRIPT ----
# Genere automatiquement a chaque rendu du livre


here::i_am("atlas-mnhnl.Rproj")
source(here::here("Atlas", "code", "0_Initialisation.R"))
source(here::here("Atlas", "code", "config.R"))
source(here::here("Atlas", "code", "Taxonomie.R"))  
source(here::here("Atlas", "code", "7_GenerateSpeciesPages.R"))

############ Titres dynamiques ----

titre_book <- paste0("Atlas of ", taxon, " in Luxembourg")
contenu_yml <- readLines("_quarto.yml")
contenu_yml <- gsub('title: ".*"', paste0('title: "', titre_book, '"'), contenu_yml)
writeLines(contenu_yml, "_quarto.yml")

titre_reel <- paste("Ecology of Luxembourg", taxon)
contenu <- readLines("ecology.qmd")
contenu <- gsub('title: ".*"', paste0('title: "', titre_reel, '"'), contenu)
writeLines(contenu, "ecology.qmd")

titre_history <- paste0("History of ", taxon, " recording in Luxembourg")
contenu2 <- readLines("history.qmd")
contenu2 <- gsub('title: ".*"', paste0('title: "', titre_history, '"'), contenu2)
writeLines(contenu2, "history.qmd")

titre_conservation <- paste0("Conservation of ", taxon, " in Luxembourg")
contenu3 <- readLines("conservation.qmd")
contenu3 <- gsub('title: ".*"', paste0('title: "', titre_conservation, '"'), contenu3)
writeLines(contenu3, "conservation.qmd")

