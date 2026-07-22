######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : génération automatique des fiches espèces avec _template.qmd


library(tidyverse)
library(here)
library(taxize)
library(glue)

############ Chemins
species_dir   <- here("Atlas", "species_account")
template_path <- here("Atlas", "species_account", "_template.qmd")
yml_path      <- here("Atlas", "_quarto.yml")


############ Id de page + ordre de tri (alphabetique) ----------

build_species_key <- function(verbatim_name) {
  verbatim_name %>%
    str_trim() %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9]+", "_") %>% #on met un _ 
    str_remove("^_+") %>%
    str_remove("_+$")
}


############ statut taxonomique (synonyme /invalide/accepte) ----

# fonction pour voir si nom accepté
taxonomic_status <- function(verbatim_names) {
  raw <- tryCatch(
    taxize::gna_verifier(verbatim_names, data_sources = 1, canonical = TRUE), error = function(e) {
      warning("gna_verifier a echoue : ", conditionMessage(e), call. = FALSE)
      NULL})
  if (is.null(raw) || nrow(raw) == 0) { # mettre des NA si pas accepté
    return(tibble( verbatim_name = verbatim_names, is_synonym = NA,accepted_name = NA_character_))}
  raw %>%
    transmute(verbatim_name = submittedName, is_synonym = isSynonym,accepted_name = currentName)
}

# Regroupe tout le tri taxonomique 
prepare_species_data <- function(DB_taxo) {
  DB_taxo <- DB_taxo %>%
    mutate(
      species_key = build_species_key(verbatim_name),
      qmd_file    = paste0(species_key, ".qmd")
    ) %>%
    arrange(verbatim_name)
  
  taxo_status <- taxonomic_status(DB_taxo$verbatim_name)
  
  #mettre à jour DB_taxo en evitant les doublons
  DB_taxo <- DB_taxo %>%
    select(-any_of(c("is_synonym", "accepted_name"))) %>%
    left_join(taxo_status, by = "verbatim_name")
  
# species_synonyms : taxon reconnu mais synonyme
# species_invalid_taxon : gna_verifier a rien trouve
# species_ok : taxon reconnu et accepte 
  
species_synonyms <- DB_taxo %>% filter(is_synonym %in% TRUE)
species_invalid_taxon <- DB_taxo %>% filter(is.na(is_synonym))
species_ok <- DB_taxo %>% filter(is_synonym %in% FALSE)
  
  # Ecarte noms de genre seul 
species_genus_only <- species_ok %>%
    filter(str_count(str_trim(verbatim_name), "\\S+") < 2) # un mot = juste le genre
species_ok <- species_ok %>%
    filter(str_count(str_trim(verbatim_name), "\\S+") >= 2)
  
  # Lignes avec un verbatim_name vide/NA 
species_invalid_name <- species_ok %>% filter(is.na(verbatim_name) | str_trim(verbatim_name) == "")
species_ok <- species_ok %>% filter(!(is.na(verbatim_name) | str_trim(verbatim_name) == "")) # na = invalide
  
  # Doublons de species_key
species_key_duplicates <- species_ok %>%
    count(species_key, name = "n_variantes") %>% # combien de lignes partagent chaque species_key
    filter(n_variantes > 1) # juste quand y en a plusieurs
  
duplicate_variant_details <- species_ok %>% # voir les lignes en conflit
    semi_join(species_key_duplicates, by = "species_key") %>% #filtre juste species_ok
    arrange(species_key, verbatim_name)
  
  # Une ligne par species_key -> ne pas generer deux fois le meme fichier
  species_to_generate <- species_ok %>% distinct(species_key, .keep_all = TRUE)
  
  list(
    species_ok = species_ok, species_to_generate= species_to_generate, species_synonyms= species_synonyms,
    species_invalid_taxon = species_invalid_taxon,species_genus_only = species_genus_only,
    species_invalid_name = species_invalid_name,species_key_duplicates = species_key_duplicates, duplicate_variant_details = duplicate_variant_details)
}


############ Noms vernaculaires ------
# Catalogue of Life pour langues

vernacular_lang_codes <- c(EN = "eng", LB = "ltz", FR = "fra", DE = "deu")

fetch_vernacular_names <- function(species_name) {
  empty <- set_names(rep("", length(vernacular_lang_codes)), names(vernacular_lang_codes)) # creation du vecteur
  usage_id <- tryCatch(col_match(species_name)$usage_id, error = function(e) NA) # Cherche l'usage_id correspondant au nom d'espèce
  
  if (is.null(usage_id) || length(usage_id) == 0 || is.na(usage_id)) return(empty)
  vern <- tryCatch(col_vernacular(usage_id), error = function(e) NULL) # on recupere les noms grace a l id
  if (is.null(vern) || nrow(vern) == 0) return(empty)
  out <- empty
  
  for (lbl in names(vernacular_lang_codes)) {
    hit <- vern %>% filter(language == vernacular_lang_codes[[lbl]])
    if (nrow(hit) > 0) out[[lbl]] <- hit$name[1]} # on prend le premier nom 
  out
}


############ Generation des fichiers qmd manquants  --

safe_val <- function(x) {
  if (length(x) == 0 || is.na(x)) "" else as.character(x)
}

build_species_page <- function(row, vernacular_names, template_text) {
  glue(template_text, .open = "<<", .close = ">>", species    = safe_val(row$verbatim_name),
    authorship = safe_val(row$authorship), name = safe_val(row$species_key), subfamily  = safe_val(row$Subfamily),
    tribe = safe_val(row$Tribe), en = safe_val(vernacular_names[["EN"]]), lb = safe_val(vernacular_names[["LB"]]),
    fr = safe_val(vernacular_names[["FR"]]), de = safe_val(vernacular_names[["DE"]]) )
}

generate_species_pages <- function(species_to_generate, species_dir, template_text) {
  created_files   <- character(0)
  already_present <- character(0)
  
  for (i in seq_len(nrow(species_to_generate))) {
    row <- species_to_generate[i, ]
    output_path <- file.path(species_dir,row$qmd_file)
    if (file.exists(output_path)) {
      already_present <- c(already_present,row$verbatim_name)
      next}
    tryCatch({
      vernacular_names <- fetch_vernacular_names(row$verbatim_name)
      
      writeLines(build_species_page(row, vernacular_names, template_text), output_path,
                 useBytes = TRUE, sep = "\n")
      created_files <- c(created_files, row$verbatim_name)
      message("Cree : ", row$qmd_file)}, error = function(e) {
      warning("Echec pour '", row$verbatim_name, "' (fichier vise : ", row$qmd_file, ") : ",conditionMessage(e), call. = FALSE)})}
  
  list(created_files = created_files, already_present = already_present)
}


############ Mise a jour de _quarto.yml ---


update_quarto_yml <- function(yml_path, species_dir, species_to_generate) {
  lines <- readLines(yml_path, encoding = "UTF-8")
  
  part_line <- which(str_detect(lines, "part:\\s*Species accounts"))
  if (length(part_line) != 1) {
    stop("Impossible de localiser un unique bloc 'part: Species accounts' dans _quarto.yml")
  }
  chapters_offset <- which(str_detect(lines[(part_line + 1):length(lines)], "chapters:"))[1]
  chapters_line <- part_line + chapters_offset
  
  first_item_idx <- chapters_line + 1
  indent <- str_extract(lines[first_item_idx],"^\\s*")
  item_pat <- paste0("^",indent,"- ")
  
  end_idx <- chapters_line
  j <- first_item_idx
  while (j <= length(lines) && str_detect(lines[j], item_pat)) {
    end_idx <- j
    j <- j + 1
  }
  
  existing_qmd_files <- species_to_generate$qmd_file[file.exists(file.path(species_dir, species_to_generate$qmd_file))]
  new_chapter_lines <- paste0(indent, "- ", file.path(basename(species_dir), existing_qmd_files))
  
  lines <- c(lines[seq_len(chapters_line)],new_chapter_lines,lines[(end_idx + 1):length(lines)])
  writeLines(lines, yml_path, useBytes = TRUE)
}


############ Execution

data <- prepare_species_data(DB_taxo)

template_text <- read_file(template_path) %>%
  str_replace_all("\r\n", "\n") %>%
  str_replace_all("\r", "\n")

gen_result <- generate_species_pages(data$species_to_generate, species_dir, template_text)

update_quarto_yml(yml_path, species_dir, data$species_to_generate)

############ Injection du contenu texte pour TOUTES les fiches ---

source(here("Atlas", "code", "8_InjectContent.R"))

############ Recap

cat("Pages creees (", length(gen_result$created_files), ") :\n", sep = "")
if (length(gen_result$created_files) > 0) cat(paste0("  - ", gen_result$created_files), sep = "\n") else cat("  (aucune)\n")

cat("\nPage deja presente (", length(gen_result$already_present), ") :\n", sep = "")
if (length(gen_result$already_present) > 0) cat(paste0("  - ", gen_result$already_present), sep = "\n") else cat("  (aucune)\n")

cat("\nGroupes de noms allant vers le meme fichier (",
    nrow(data$species_key_duplicates), " fichier(s) concerne(s)) :\n", sep = "")
if (nrow(data$duplicate_variant_details) > 0) {
  cat(paste0("  - ", data$duplicate_variant_details$verbatim_name, "  ->  ", data$duplicate_variant_details$qmd_file), sep = "\n")} else {cat(" (aucun)\n")
}

cat("\nNom vide/NA ecarte (", nrow(data$species_invalid_name), ") :\n", sep = "")
if (nrow(data$species_invalid_name) > 0) {
  print(data$species_invalid_name)} else {cat("  (aucun)\n")
}

cat("\nGenre seul ecarte, pas une espece (", nrow(data$species_genus_only), ") :\n", sep = "")
if (nrow(data$species_genus_only) > 0) {
  cat(paste0("  - ", data$species_genus_only$verbatim_name), sep = "\n")
} else { cat("  (aucun)\n")
}

cat("\nTaxon non trouve dans le Catalogue of Life (", nrow(data$species_invalid_taxon), ") :\n", sep = "")
if (nrow(data$species_invalid_taxon) > 0) {
  cat(paste0("  - ", data$species_invalid_taxon$verbatim_name), sep = "\n")} else { cat("  (aucun)\n")
}

cat("\nTaxon synonyme (", nrow(data$species_synonyms), ") :\n", sep = "")
if (nrow(data$species_synonyms) > 0) {
  cat(paste0(
    "  - ", data$species_synonyms$verbatim_name, ifelse(!is.na(data$species_synonyms$accepted_name),
   paste0(" -> nom accepte : ", data$species_synonyms$accepted_name), " -> nom accepte inconnu")), sep = "\n")
} else { cat("  (aucun)\n")
}

