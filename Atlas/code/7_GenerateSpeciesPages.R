######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : génération automatique des fiches espèces (.qmd) depuis DB3 à partir de _template.qmd



library(tidyverse)
library(here)

# ---- 0. Chemins ------------------------------------------------------
species_dir   <- here("Atlas", "species_account")
template_path <- here("Atlas", "species_account", "_template.qmd")
yml_path      <- here("Atlas", "_quarto.yml")

# ---- 1. Slug + ordre de tri (alphabetique pur par nom d'espece) --------

make_slug <- function(verbatim_name) {
  verbatim_name %>%
    str_trim() %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9]+", "_") %>%
    str_remove("^_+") %>%
    str_remove("_+$")
}

DB_taxo <- DB_taxo %>%
  mutate(
    slug = make_slug(verbatim_name),
    qmd  = paste0(slug, ".qmd")
  ) %>%
  arrange(verbatim_name)

# ---- 2. Noms vernaculaires ---------------------------------------------

lang_codes <- c(EN = "eng", LB = "ltz", FR = "fra", DE = "deu")

get_vernacular <- function(species_name) {
  empty <- set_names(rep("", length(lang_codes)), names(lang_codes))
  usage_id <- tryCatch(col_match(species_name)$usage_id, error = function(e) NA)
  if (is.null(usage_id) || length(usage_id) == 0 || is.na(usage_id)) return(empty)
  vern <- tryCatch(col_vernacular(usage_id), error = function(e) NULL)
  if (is.null(vern) || nrow(vern) == 0) return(empty)
  out <- empty
  for (lbl in names(lang_codes)) {
    hit <- vern %>% filter(language == lang_codes[[lbl]])
    if (nrow(hit) > 0) out[[lbl]] <- hit$name[1]
  }
  out
}

# ---- 3. Generation des fichiers qmd manquants ---------------------------
template_txt <- read_file(template_path)

fill_template <- function(row, vern) {
  txt <- template_txt
  txt <- str_replace_all(txt, fixed("<<species>>"),    row$verbatim_name)
  txt <- str_replace_all(txt, fixed("<<authorship>>"), row$authorship)
  txt <- str_replace_all(txt, fixed("<<slug>>"),       row$slug)
  txt <- str_replace_all(txt, fixed("<<subfamily>>"),  row$Subfamily)
  txt <- str_replace_all(txt, fixed("<<tribe>>"),      row$Tribe)
  txt <- str_replace_all(txt, fixed("<<en>>"), vern[["EN"]])
  txt <- str_replace_all(txt, fixed("<<lb>>"), vern[["LB"]])
  txt <- str_replace_all(txt, fixed("<<fr>>"), vern[["FR"]])
  txt <- str_replace_all(txt, fixed("<<de>>"), vern[["DE"]])
  txt
}

new_files <- character(0)

for (i in seq_len(nrow(DB_taxo))) {
  row <- DB_taxo[i, ]
  out_path <- file.path(species_dir, row$qmd)
  if (file.exists(out_path)) next   # on ne touche jamais un fichier existant
  tryCatch({
    vern <- get_vernacular(row$verbatim_name)
    writeLines(fill_template(row, vern), out_path, useBytes = TRUE)
    new_files <- c(new_files, row$qmd)
    message("Cree : ", row$qmd)
  }, error = function(e) {
    warning("Echec pour '", row$verbatim_name, "' (fichier vise : ", row$qmd, ") : ",
            conditionMessage(e), call. = FALSE)
  })
}

if (length(new_files) == 0) {
  message("Aucune nouvelle espece a generer (tous les fichiers existent deja).")
}

# ---- 4. Mise a jour de _quarto.yml ---------------------------------------
# Repere le bloc `part: Species accounts`, releve l'indentation de ses
# items `chapters:`, puis reecrit la liste complete (existants + nouveaux)
# triee par ordre alphabetique pur du nom d'espece.
update_quarto_yml <- function(yml_path, species_dir, DB_taxo) {
  lines <- readLines(yml_path, encoding = "UTF-8")
  
  part_line <- which(str_detect(lines, "part:\\s*Species accounts"))
  if (length(part_line) != 1) {
    stop("Impossible de localiser un unique bloc 'part: Species accounts' dans _quarto.yml. ",
         "Verifie l'intitule exact du part dans le fichier.")
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
  
  existing_qmds <- DB_taxo$qmd[file.exists(file.path(species_dir, DB_taxo$qmd))]
  new_chapter_lines <- paste0(indent, "- ", file.path(basename(species_dir), existing_qmds))
  
  lines <- c(
    lines[seq_len(chapters_line)],
    new_chapter_lines,
    lines[(end_idx + 1):length(lines)]
  )
  
  writeLines(lines, yml_path, useBytes = TRUE)
}

if (length(new_files) > 0) {
  update_quarto_yml(yml_path, species_dir, DB_taxo)
  message(length(new_files), " page(s) ajoutee(s) a _quarto.yml.")
}

# ---- 5. Injection du contenu texte -----------------------------------------
source(here("Atlas", "code", "8_InjectContent.R"))

