

# quart de mois
quart_de_mois <- function(date) {
  d <- day(date)
  case_when(
    d <= 7  ~ 1L,
    d <= 14 ~ 2L,
    d <= 21 ~ 3L,
    TRUE    ~ 4L
  )
}

# Grille périodes anné
grille_periodes <- expand.grid(Month = 1:12, Quart = 1:4) %>%
  arrange(Month, Quart) %>%
  mutate(Position = row_number())

# présence par quart de mois
phenologie_espece <- function(data, espece) {
  obs <- data %>%
    filter(ID == espece) %>%
    mutate(Month = month(Date), Quart = quart_de_mois(Date)) %>%
    count(Month, Quart, name = "n")
  
  grille_periodes %>%
    left_join(obs, by = c("Month", "Quart")) %>%
    mutate(n = replace_na(n, 0))
}

# Diagramme en barre
plot_phenologie <- function(data, espece) {
  pheno <- phenologie_espece(data, espece)
  mois_positions <- grille_periodes %>% filter(Quart == 1) %>% pull(Position)
  
  ggplot(pheno, aes(x = Position, y = n)) +
    geom_col(fill = "lightblue", width = 0.85) +
    scale_x_continuous(
      breaks = mois_positions,
      labels = month.abb,
      expand = c(0.01, 0.01)
    ) +
    labs(x = NULL, y = "Observations") +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_text(size = 8),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank()
    )
}

