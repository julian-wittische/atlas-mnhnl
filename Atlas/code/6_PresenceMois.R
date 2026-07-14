######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : Plots for species account



############ Couper les mois en quatre ----

grille <- expand.grid(Month = 1:12, Quart = 1:4) %>%
  arrange(Month, Quart) %>% # tri ordre chrono
  mutate(Position = row_number()) # 1 à 48

#jours 1–7  quart 1
#jours 8–14  quart 2
#jours 15–21 quart 3
#jours 22–31  quart 4 (ou 5 pour29–31 )

species <- "Episyrphus balteatus"
species <- "Syritta pipiens"
species <- "Volucella zonaria"
species <- "Blera fallax"
species <- "Myathropa florea"

############ Joindre aux données ----

presence <- DB3 %>%
  filter(ID == species) %>%
  mutate(
    Month = month(Date),
    Quart = pmin(ceiling(day(Date) / 7), 4),
    Source2 = ifelse(Source == "Citizen science", "Citizen science", "Other")
  ) %>%
  count(Month, Quart, Source2, name = "n") %>%
  right_join(grille, by = c("Month", "Quart")) %>%
  mutate(
    n = replace_na(n, 0)
  ) %>%
  group_by(Month, Quart) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup() %>%
  arrange(Position)

base <- grille$Position[grille$Quart == 1] # positions base


############ Diagramme batons / une présence = un trait  ----

g1 <- ggplot(presence, aes(x = Position, y = prop )) +
  geom_col(fill = "lightblue", width = 0.85) +
  scale_x_continuous(
    limits = c(1, 48),
    breaks = base,
    labels = month.abb,
    expand = c(0.1, 0.1)
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    expand = c(0, 0)
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(size = 15),
    axis.text.y = element_blank(),
    axis.title = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid = element_blank(),
    plot.margin = margin(t = 0, r = 0.5, b = 0, l = 0.5, unit = "cm") 
  )


############ Diagramme batons filtré par source / une présence = un trait   ----

gSource <- ggplot(presence, aes(x = Position, y = prop, fill = Source2)) +
  geom_col(width = 0.85) +
  scale_fill_manual(
    name = NULL,
    values = c(
      "Citizen science" = "lightgreen",
      "Other" = "lightblue"
    ),
    na.translate = FALSE
  ) +
  scale_x_continuous(
    limits = c(1, 48),
    breaks = base,
    labels = month.abb,
    expand = c(0.1, 0.1)
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    expand = c(0, 0)
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(size = 15),
    axis.text.y = element_blank(),
    axis.title = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid = element_blank(),
    legend.position = "top",
    legend.text = element_text(size = 15))




############ Graphique smooth   ----
g2 <- ggplot(presence, aes(x = Position, y = n)) +
  geom_area(stat = "smooth", fill = "lightblue", span = 1/3, alpha = 0.6, se = FALSE, xseq=seq(min(presence[presence$n>0, "Position"]), max(presence[presence$n>0, "Position"]), 1)) +
  scale_x_continuous(
    limits = c(1,48),
    breaks = base,
    labels = month.abb,
    expand = c(0.1, 0.1)
  ) +
  scale_y_continuous(limits = c(0, NA), expand = c(0, 0)) +
  geom_vline(xintercept = range(presence[presence$n>0, "Position"])) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(size = 15), axis.text.y = element_blank(), axis.title = element_blank(), axis.ticks.y = element_blank(),
        axis.title.y = element_blank(), panel.grid.minor = element_blank(), panel.grid.major = element_blank()
        )



