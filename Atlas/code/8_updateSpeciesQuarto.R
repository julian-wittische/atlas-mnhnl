######################## PROJECT: Atlas Template
# Script objective : régénère la liste des chapitres "species accounts" dans _quarto.yml

library(yaml)
library(here)

here::i_am("atlas-mnhnl.Rproj")

qmd_path <- here::here("Atlas", "_quarto.yml")
config <- yaml::read_yaml(qmd_path)

############ Liste des fiches espèces présentes sur le disque ----
fichiers_especes <- list.files(
  here::here("Atlas", "species_account"),
  pattern = "\\.qmd$",
  full.names = FALSE
)
fichiers_especes <- setdiff(fichiers_especes, c("_template.qmd", "PLACEHOLDER.qmd"))
fichiers_especes <- sort(fichiers_especes)
chemins_especes <- paste0("species_account/", fichiers_especes)

############ Construction du bloc "part" ----
part_especes <- list(
  part = "Species accounts",
  chapters = as.list(chemins_especes)
)

############ Nettoyage : retirer toute ancienne trace (species.qmd OU un ancien part "Species accounts") ----
chapters <- config$book$chapters

est_ancien_bloc <- function(ch) {
  identical(ch, "species.qmd") ||
    (is.list(ch) && !is.null(ch$part) && ch$part == "Species accounts")
}

idx_a_retirer <- which(vapply(chapters, est_ancien_bloc, logical(1)))

############ Position d'insertion : juste avant statistics.qmd (donc après glossary.qmd) ----
idx_statistics <- which(chapters == "statistics.qmd")

if (length(idx_a_retirer) > 0) {
  position_insertion <- min(idx_a_retirer)
  chapters <- chapters[-idx_a_retirer]
  # Recalculer la position de statistics.qmd après suppression
  idx_statistics <- which(chapters == "statistics.qmd")
}

if (length(idx_statistics) > 0) {
  chapters <- append(chapters, list(part_especes), after = idx_statistics - 1)
} else {
  # Fallback si statistics.qmd est introuvable : ajoute à la fin
  chapters <- append(chapters, list(part_especes))
}

config$book$chapters <- chapters

yaml::write_yaml(config, qmd_path)
cat("_quarto.yml mis à jour avec", length(fichiers_especes), "fiches espèces.\n")
