######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Plots for species account


############ Couper les mois en quatre ----
grille <- expand.grid(Month = 1:12, Quart = 1:4) %>%
  arrange(Month, Quart) %>%
  mutate(Position = row_number())

#jours 1–7  quart 1
#jours 8–14  quart 2
#jours 15–21 quart 3
#jours 22–31  quart 4 (ou 5 pour29–31 )

base <- grille$Position[grille$Quart == 1]

############ Prépare les données de présence pour une espèce ----
prepare_presence <- function(species_name, data = DB3 ) {
  data %>%
    filter(ID == species_name) %>%
    mutate(
      Month = month(Date),
      Quart = pmin(ceiling(day(Date) / 7), 4),
      Source2 = ifelse(Source == "Citizen science", "Citizen science", "Other")
    ) %>%
    count(Month, Quart, Source2, name = "n") %>%
    right_join(grille, by = c("Month", "Quart")) %>%
    mutate(n = replace_na(n, 0)) %>%
    group_by(Month, Quart) %>%
    mutate(prop = n / sum(n)) %>%
    ungroup() %>%
    arrange(Position)
}


 ############ Graphique bâtons par source ----
plot_activite_source <- function(species_name, data = DB3) {
  presence <- prepare_presence(species_name, data)
  ggplot(presence, aes(x = Position, y = prop, fill = Source2)) +
    geom_col(width = 0.85) +
    scale_fill_manual(name = NULL, values = c("Citizen science" = "lightgreen", "Other" = "lightblue"), na.translate = FALSE) +
    scale_x_continuous(limits = c(1, 48), breaks = base, labels = month.abb, expand = c(0.1, 0.1)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_text(size = 15),
      axis.text.y = element_blank(),
      axis.title = element_blank(),
      axis.ticks.y = element_blank(),
      panel.grid = element_blank(),
      legend.position = "top",
      legend.text = element_text(size = 15)
    )
}
############ Graphique heatmap ----

plot_heatmap <- function(species_name, data = DB3) {
  presence <- prepare_presence(species_name, data)
  ggplot(presence, aes(x = Position , y= 0.5,fill = n)) +
    geom_tile(width = 1,color = NA) +
    scale_fill_gradient(
      name = "Number of records",
      low = "white",
      high = "darkgreen")+
    coord_fixed(ratio = 10) +
    scale_x_continuous(limits = c(1, 48), breaks = base, labels = month.abb, expand = c(0.1, 0.1)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0,0)) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_blank(),
      axis.title = element_blank(),
      axis.ticks.y = element_blank(),
      panel.grid = element_blank(),
      plot.margin = margin(t = 0, r = 0.5, b = 0, l = 0.5, unit = "cm"),
      legend.title = element_text(size = 12)
    )
}