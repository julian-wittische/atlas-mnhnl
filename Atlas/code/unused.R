############ Graphique smooth ----
grille <- expand.grid(Month = 1:12, Quart = 1:4) %>%
  arrange(Month, Quart) %>%
  mutate(Position = row_number())
base <- grille$Position[grille$Quart == 1]

plot_activite_smooth <- function(species_name, data = DB3) {
  presence <- prepare_presence(species_name, data)
  ggplot(presence, aes(x = Position, y = n)) +
    geom_area(stat = "smooth", fill = "lightblue", span = 1/3, alpha = 0.6, se = FALSE,
              xseq = seq(min(presence[presence$n > 0, "Position"]), max(presence[presence$n > 0, "Position"]), 1)) +
    scale_x_continuous(limits = c(1, 48), breaks = base, labels = month.abb, expand = c(0.1, 0.1)) +
    scale_y_continuous(limits = c(0, NA), expand = c(0, 0)) +
    geom_vline(xintercept = range(presence[presence$n > 0, "Position"])) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_text(size = 15),
      axis.text.y = element_blank(),
      axis.title = element_blank(),
      axis.ticks.y = element_blank(),
      axis.title.y = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_blank()
    )
}