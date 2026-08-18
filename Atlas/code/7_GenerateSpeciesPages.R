######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : génération automatique des fiches espèces avec _template.qmd

############ Chemins ----

species_dir   <- here("Atlas", "species_account")
template_path <- here("Atlas", "species_account", "_template.qmd")
yml_path      <- here("Atlas", "_quarto.yml")
taxo_path <- here("Atlas", "data", "DB_taxo.rds")
images_dir    <- here("Atlas", "images")

############ Chargement des données déjà nettoyées ----

DB_taxo <- readRDS(taxo_path)


############ MODE TEST  ----
## Pour tester le script sur seulement quelques espèces / choix manuel des espèces ---
# species_test <- c(
#   "Temnostoma meridionale",
#   "Myathropa florea",
#   "Blera fallax",
#   "Callicera aurata"
# )
# DB_taxo <- DB_taxo %>% filter(verbatim_name %in% species_test)
############

############ Id de page  ----

# construit un identifiant de fichier a partir du nom latin (sans espaces/accents)
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

doublons_taxo <- DB_taxo %>% count(species_key) %>% filter(n > 1)
if (nrow(doublons_taxo) > 0) {
  warning(
    "DB_taxo contient des species_key en double ",
    paste(doublons_taxo$species_key, collapse = ", "),
    call. = FALSE
  )
}

############  Noms vernaculaires COL-Inat-Wikidata ----


vernacular_lang_codes <- c(EN = "eng", LB = "ltz", FR = "fra", DE = "deu")   # codes CoL (ISO 639-3)
inat_lang_codes       <- c(EN = "en",  LB = "lb",  FR = "fr",  DE = "de")    # codes iNaturalist (ISO 639-1)
wikidata_lang_codes    <- c(EN = "en",  LB = "lb",  FR = "fr",  DE = "de")    # codes Wikidata (ISO 639-1)

# recupere les noms vernaculaires depuis Catalogue of Life
fetch_vernacular_col <- function(species_name) {
  empty <- set_names(rep("", length(vernacular_lang_codes)), names(vernacular_lang_codes))
  usage_id <- tryCatch(col_match(species_name)$usage_id, error = function(e) NA) 
  
  if (is.null(usage_id) || length(usage_id) == 0 || is.na(usage_id)) return(empty) 
  vern <- tryCatch(col_vernacular(usage_id), error = function(e) NULL) 
  if (is.null(vern) || nrow(vern) == 0) return(empty) 
  
  out <- empty 
  for (lbl in names(vernacular_lang_codes)) { 
    hit <- vern %>% filter(language == vernacular_lang_codes[[lbl]])
    if (nrow(hit) > 0) out[[lbl]] <- hit$name[1] # on garde le premier nom si plusieurs existent
  }
  out
}


# recupere les noms vernaculaires depuis l'API iNaturalist, seulement pour les langues encore manquantes
fetch_vernacular_inat <- function(species_name, labels_needed) {
  empty <- set_names(rep("", length(labels_needed)), labels_needed)
  if (length(labels_needed) == 0) return(empty)
  res <- tryCatch(
    httr::GET(
      "https://api.inaturalist.org/v1/taxa",
      query = list(q = species_name, all_names = "true", per_page = 1) ),
    error = function(e) NULL )
  if (is.null(res) || httr::status_code(res) != 200) return(empty)
  data <- tryCatch(
    jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"), flatten = TRUE),
    error = function(e) NULL )
  if (is.null(data) || is.null(data$results) || nrow(data$results) == 0) return(empty)
  noms <- data$results$names[[1]]
  if (is.null(noms) || !"locale" %in% names(noms) || nrow(noms) == 0) return(empty)
  out <- empty
  for (lbl in labels_needed) {
    code <- inat_lang_codes[[lbl]]
    hit <- noms %>% filter(locale == code)
    if ("is_valid" %in% names(hit)) hit <- hit %>% filter(is_valid == TRUE) # ecarte les noms non valides cotes par iNat
    if (nrow(hit) > 0) out[[lbl]] <- hit$name[1]}
  out
}

# recupere les noms vernaculaires depuis Wikidata (SPARQL), en dernier recours
fetch_vernacular_wikidata <- function(species_name, labels_needed) {
  empty <- set_names(rep("", length(labels_needed)), labels_needed)
  if (length(labels_needed) == 0) return(empty)
  codes_needed <- wikidata_lang_codes[labels_needed]
  sparql <- sprintf(
    'SELECT ?commonName ?lang WHERE {
       ?item wdt:P225 "%s" .
       ?item wdt:P1843 ?commonName .
       BIND(LANG(?commonName) AS ?lang)
       FILTER(?lang IN (%s))}',
    species_name,
    paste0('"', codes_needed, '"', collapse = ", ") )
  res <- tryCatch(
    httr::GET(
      "https://query.wikidata.org/sparql",
      query = list(query = sparql, format = "json")),
    error = function(e) NULL)
  if (is.null(res) || httr::status_code(res) != 200) return(empty)
  data <- tryCatch(
    jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"), flatten = TRUE),
    error = function(e) NULL)
  bindings <- data$results$bindings
  if (is.null(bindings) || !is.data.frame(bindings) || nrow(bindings) == 0) return(empty)
  out <- empty
  for (lbl in labels_needed) {
    code <- wikidata_lang_codes[[lbl]]
    hit <- bindings[bindings$lang.value == code, ]
    if (nrow(hit) > 0) out[[lbl]] <- hit$commonName.value[1]}
  out
}

# chaine les 3 sources par ordre de priorite (CoL > iNat > Wikidata), en ne requetant que ce qui manque encore

fetch_vernacular_names <- function(species_name) {
  out <- fetch_vernacular_col(species_name)
  
  manquants <- names(out)[out == ""]
  if (length(manquants) > 0) {
    Sys.sleep(1)  
    depuis_inat <- fetch_vernacular_inat(species_name, manquants)
    out[manquants] <- depuis_inat[manquants]
  }
  
  manquants2 <- names(out)[out == ""]
  if (length(manquants2) > 0) {
    Sys.sleep(1)
    depuis_wiki <- fetch_vernacular_wikidata(species_name, manquants2)
    out[manquants2] <- depuis_wiki[manquants2]
  }
  
  out
}

############ Images : avec <slug>.<Photographe>.<Licence>.png ----
# Exemple : temnostoma_meridionale.Sam_Schaack.CC-BY-NC.png
#   -> species_key = "temnostoma_meridionale"
#   -> photographe = "Sam Schaack"   (underscore remplacé par un espace)
#   -> licence     = "CC-BY-NC"

build_image_table <- function(images_dir) {
  fichiers_images <- list.files(images_dir, pattern = "\\.(png|jpg|jpeg)$", ignore.case = TRUE)

  fichiers_images <- fichiers_images[str_count(fichiers_images, "\\.") >= 3] # ecarte les fichiers hors convention
  if (length(fichiers_images) == 0) {
    return(tibble(fichier = character(), species_key = character(),
                  photographe = character(), licence = character())) }
  
  parties <- str_split_fixed(fichiers_images, "\\.", 4)  
  
  tibble(
    fichier     = fichiers_images,
    species_key = parties[, 1],
    photographe = str_replace_all(parties[, 2], "_", " "),
    licence     = parties[, 3])
}

get_image_info <- function(species_key, images_table) {
  ligne <- images_table %>% filter(species_key == !!species_key)
  if (nrow(ligne) == 0) {
    warning("Aucune image trouvee pour : ", species_key, call. = FALSE)
    return(list(fichier = "", credit = ""))}
  
  list(fichier = ligne$fichier[1], credit  = paste(ligne$licence[1], ligne$photographe[1])) 
}


############ Génération des fichiers qmd manquants ----

safe_val <- function(x) {
  if (length(x) == 0 || is.na(x)) "" else as.character(x)
}

# remplit le template (balises <<...>>) avec les infos taxo, noms vernaculaires et image de l'espece
build_species_page <- function(row, vernacular_names, image_info, template_text) {
  glue(
    template_text, .open = "<<", .close = ">>",
    species      = safe_val(row$verbatim_name),
    authorship   = safe_val(row$authorship),
    name         = safe_val(row$species_key),
    subfamily    = safe_val(row$Subfamily),
    tribe        = safe_val(row$Tribe),
    en = safe_val(vernacular_names[["EN"]]),
    lb = safe_val(vernacular_names[["LB"]]),
    fr = safe_val(vernacular_names[["FR"]]),
    de = safe_val(vernacular_names[["DE"]]),
    image_file   = safe_val(image_info$fichier),
    image_credit = safe_val(image_info$credit))
}

# genere un .qmd par espece de DB_taxo, sans ecraser les fichiers deja presents
generate_species_pages <- function(DB_taxo, species_dir, template_text, images_table) {
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
      image_info <- get_image_info(row$species_key, images_table)
      writeLines(
        build_species_page(row, vernacular_names, image_info, template_text),
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

# insere les nouveaux .qmd dans le bloc "chapters:" sous "part: Species accounts"
update_quarto_yml <- function(yml_path, species_dir, DB_taxo) {
  lines <- readLines(yml_path, encoding = "UTF-8")
  
  part_line <- which(str_detect(lines, "part:\\s*Species accounts"))
  if (length(part_line) != 1) {
    stop("Impossible de localiser un unique bloc 'part: Species accounts' dans _quarto.yml")
  }
  
  chapters_offset <- which(str_detect(lines[(part_line + 1):length(lines)], "chapters:"))[1]
  if (is.na(chapters_offset)) {
    stop("Impossible de localiser 'chapters:' sous 'part: Species accounts' dans _quarto.yml")
  }
  chapters_line <- part_line + chapters_offset

  # si e bloc Species accounts est vide :
  indent <- str_extract(lines[chapters_line], "^\\s*")
  item_pat <- paste0("^", indent, "- ")
  
  end_idx <- chapters_line
  j <- chapters_line + 1
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

images_table <- build_image_table(images_dir)

doublons <- images_table %>% count(species_key) %>% filter(n > 1)
if (nrow(doublons) > 0) {
  warning(
    "Plusieurs images trouvees pour : ", paste(doublons$species_key, collapse = ", "),
    " -- seule la premiere est utilisee.",
    call. = FALSE
  )
}
images_table <- images_table %>%
  arrange(fichier) %>%
  distinct(species_key, .keep_all = TRUE)

gen_result <- generate_species_pages(DB_taxo, species_dir, template_text, images_table)

# en mode test : commenter la ligne ci-dessous pour ne pas réécrire _quarto.yml avec seulement les espèces testées
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