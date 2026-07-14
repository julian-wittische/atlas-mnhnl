###### PRE-RENDER SCRIPT ----
# Généré automatiquement à chaque rendu du livre

taxon <- "Hoverflies"

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

############ Chargement des données ----

source("code/1_config.R")
source("code/0_Initialisation.R")
source("code/3_LoadData.R")  

dir.create("data", showWarnings = FALSE)
saveRDS(DB3, "data/DB3.rds")

############ Species chapters ----

species_list <- sort(unique(DB3$ID))
species_list <- species_list[!is.na(species_list)]



slugify <- function(x) {
  x <- tolower(x)
  x <- gsub(" ", "-", x)
  gsub("[^a-z0-9-]", "", x)
}
species_slugs <- slugify(species_list)

# nettoyer les anciens fichiers générés 
old_files <- list.files("chapters/species", pattern = "\\.qmd$", full.names = TRUE)
old_files <- old_files[!grepl("_template\\.qmd$|PLACEHOLDER\\.qmd$", old_files)]
if (length(old_files) > 0) file.remove(old_files)

# générer un .qmd par espèce
template <- readLines("chapters/species/_template.qmd")

for (i in seq_along(species_list)) {
  sp <- species_list[i]
  contenu_sp <- gsub("\\{\\{SPECIES\\}\\}", sp, template)
  writeLines(contenu_sp, paste0("chapters/species/", species_slugs[i], ".qmd"))
}

# reconstruire le bloc chapters: sous part: species.qmd
contenu_yml <- readLines("_quarto.yml")

part_line <- grep("part: species\\.qmd", contenu_yml)
chapters_line <- part_line + 1

next_lines <- (chapters_line + 1):length(contenu_yml)
end_offset <- which(!grepl("^        - ", contenu_yml[next_lines]))[1]
block_end <- chapters_line + end_offset - 1

qmd_paths <- paste0("        - chapters/species/", species_slugs, ".qmd")

contenu_yml <- c(
  contenu_yml[1:chapters_line],
  qmd_paths,
  contenu_yml[block_end:length(contenu_yml)]
)

writeLines(contenu_yml, "_quarto.yml")