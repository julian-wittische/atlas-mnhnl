######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : génération automatique des fiches espèces avec _template.qmd
# Suppose DB_taxo déjà nettoyé (noms valides, dédupliqués, sans synonymes ni genres seuls)
# -> tout le nettoyage/vérification taxonomique se fait en amont, dans Taxonomie.R


library(tidyverse)
library(here)
library(glue)

############ Chemins ----

species_dir   <- here("Atlas", "species_account")
template_path <- here("Atlas", "species_account", "_template.qmd")
yml_path      <- here("Atlas", "_quarto.yml")
taxo_path <- here("Atlas", "data", "DB_taxo.rds")


############ Chargement des données déjà nettoyées ----

DB_taxo <- readRDS(taxo_path)


stopifnot(
  "DB_taxo contient des noms manquants ou vides" =
    !any(is.na(DB_taxo$verbatim_name) | str_trim(DB_taxo$verbatim_name) == ""),
  "DB_taxo contient des noms de genre seul (un seul mot)" =
    all(str_count(str_trim(DB_taxo$verbatim_name), "\\S+") >= 2)
)


############ Id de page (slug) ----

build_species_key <- function(verbatim_name) {
  verbatim_name %>%
    str_trim() %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9]+", "_") %>%
    str_remove("^_+") %>%
    str_remove("_+$")
}

DB_taxo <- DB_taxo %>%
  mutate(
    species_key = build_species_key(verbatim_name),
    qmd_file    = paste0(species_key, ".qmd")
  ) %>%
  arrange(verbatim_name)

stopifnot(
  "DB_taxo contient des species_key en double" = !anyDuplicated(DB_taxo$species_key)
)


############ Noms vernaculaires (Catalogue of Life) ----

vernacular_lang_codes <- c(EN = "eng", LB = "ltz", FR = "fra", DE = "deu")

fetch_vernacular_names <- function(species_name) {
  empty <- set_names(rep("", length(vernacular_lang_codes)), names(vernacular_lang_codes))
  usage_id <- tryCatch(col_match(species_name)$usage_id, error = function(e) NA)
  
  if (is.null(usage_id) || length(usage_id) == 0 || is.na(usage_id)) return(empty)
  vern <- tryCatch(col_vernacular(usage_id), error = function(e) NULL)
  if (is.null(vern) || nrow(vern) == 0) return(empty)
  
  out <- empty
  for (lbl in names(vernacular_lang_codes)) {
    hit <- vern %>% filter(language == vernacular_lang_codes[[lbl]])
    if (nrow(hit) > 0) out[[lbl]] <- hit$name[1]
  }
  out
}


############ Génération des fichiers qmd manquants ----

safe_val <- function(x) {
  if (length(x) == 0 || is.na(x)) "" else as.character(x)
}

build_species_page <- function(row, vernacular_names, template_text) {
  glue(
    template_text, .open = "<<", .close = ">>",
    species    = safe_val(row$verbatim_name),
    authorship = safe_val(row$authorship),
    name       = safe_val(row$species_key),
    subfamily  = safe_val(row$Subfamily),
    tribe      = safe_val(row$Tribe),
    en = safe_val(vernacular_names[["EN"]]),
    lb = safe_val(vernacular_names[["LB"]]),
    fr = safe_val(vernacular_names[["FR"]]),
    de = safe_val(vernacular_names[["DE"]])
  )
}

generate_species_pages <- function(DB_taxo, species_dir, template_text) {
  created_files   <- character(0)
  already_present <- character(0)
  
  for (i in seq_len(nrow(DB_taxo))) {
    row <- DB_taxo[i, ]
    output_path <- file.path(species_dir, row$qmd_file)
    
    if (file.exists(output_path)) {
      already_present <- c(already_present, row$verbatim_name)
      next
    }
    
    tryCatch({
      vernacular_names <- fetch_vernacular_names(row$verbatim_name)
      writeLines(
        build_species_page(row, vernacular_names, template_text),
        output_path, useBytes = TRUE, sep = "\n"
      )
      created_files <- c(created_files, row$verbatim_name)
      message("Cree : ", row$qmd_file)
    }, error = function(e) {
      warning(
        "Echec pour '", row$verbatim_name, "' (fichier vise : ", row$qmd_file, ") : ",
        conditionMessage(e), call. = FALSE
      )
    })
  }
  
  list(created_files = created_files, already_present = already_present)
}


############ Mise à jour de _quarto.yml ----

update_quarto_yml <- function(yml_path, species_dir, DB_taxo) {
  lines <- readLines(yml_path, encoding = "UTF-8")
  
  part_line <- which(str_detect(lines, "part:\\s*Species accounts"))
  if (length(part_line) != 1) {
    stop("Impossible de localiser un unique bloc 'part: Species accounts' dans _quarto.yml")
  }
  
  chapters_offset <- which(str_detect(lines[(part_line + 1):length(lines)], "chapters:"))[1]
  chapters_line <- part_line + chapters_offset
  
  first_item_idx <- chapters_line + 1
  indent <- str_extract(lines[first_item_idx], "^\\s*")
  item_pat <- paste0("^", indent, "- ")
  
  end_idx <- chapters_line
  j <- first_item_idx
  while (j <= length(lines) && str_detect(lines[j], item_pat)) {
    end_idx <- j
    j <- j + 1
  }
  
  existing_qmd_files <- DB_taxo$qmd_file[file.exists(file.path(species_dir, DB_taxo$qmd_file))]
  new_chapter_lines <- paste0(indent, "- ", file.path(basename(species_dir), existing_qmd_files))
  
  lines <- c(lines[seq_len(chapters_line)], new_chapter_lines, lines[(end_idx + 1):length(lines)])
  writeLines(lines, yml_path, useBytes = TRUE)
}


############ Exécution ----

template_text <- read_file(template_path) %>%
  str_replace_all("\r\n", "\n") %>%
  str_replace_all("\r", "\n")

gen_result <- generate_species_pages(DB_taxo, species_dir, template_text)

update_quarto_yml(yml_path, species_dir, DB_taxo)

source(here("Atlas", "code", "8_InjectContent.R"))


############ Récap ----

cat("Pages creees (", length(gen_result$created_files), ") :\n", sep = "")
if (length(gen_result$created_files) > 0) {
  cat(paste0("  - ", gen_result$created_files), sep = "\n")
} else cat("  (aucune)\n")

cat("\nPage deja presente (", length(gen_result$already_present), ") :\n", sep = "")
if (length(gen_result$already_present) > 0) {
  cat(paste0("  - ", gen_result$already_present), sep = "\n")
} else cat("  (aucune)\n")

