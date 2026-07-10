######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Store all homemade functions used in the project


############ Cartes interactives (crosstalk/leaflet) ----

##### Dépendances internes ----
attach(loadNamespace("crosstalk"), name = "crosstalk_all")
# nécessaire pour accéder aux fonctions internes

#### Widgets HTML (checkbox) ----

# fonction pour cocher les boites
blockCheckboxSP <- function(id, value, label) {
  tags$div(class = "checkbox",
           tags$label(
             tags$input(type = "checkbox", name = id, value = value, checked = "checked"),
             tags$span(label)
           )
  )
}

inlineCheckboxSP <- function(id, value, label) {
  tags$label(
    class = "checkbox-inline",
    tags$input(
      type = "checkbox",
      name = id,
      value = value,
      checked = "checked"
    ),
    tags$span(label)
  )
}

##### Filtre crosstalk personnalisé ----

# fonction pour utiliser blockcheckboxSP
filter_checkboxSP <- function(id, label, sharedData, group, allLevels = FALSE,
                              inline = FALSE, columns = 1) {
  options <- makeGroupOptions(sharedData, group, allLevels)
  labels  <- options$items$label
  values  <- options$items$value
  options$items <- NULL
  
  makeCheckbox <- if (inline) inlineCheckboxSP else blockCheckboxSP
  
  htmltools::browsable(
    htmltools::attachDependencies(
      tags$div(
        id = id,
        class = "form-group crosstalk-input-checkboxgroup crosstalk-input",
        tags$label(class = "control-label", `for` = id, label),
        tags$div(
          class = "crosstalk-options-group",
          columnize(columns,
                    mapply(labels, values, FUN = function(label, value) {
                      makeCheckbox(id, value, label)
                    }, SIMPLIFY = FALSE, USE.NAMES = FALSE))
        ),
        tags$script(type = "application/json", `data-for` = id,
                    jsonlite::toJSON(options, dataframe = "columns", pretty = TRUE))
      ),
      c(list(jqueryLib()), crosstalkLibs())
    )
  )
}