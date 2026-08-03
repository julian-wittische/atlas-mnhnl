


habitat_richness <- habitat_richness %>%
  mutate(Habitat_Dominant = case_when(
    Habitat_A >= Habitat_B & Habitat_A >= Habitat_C ~ "Grassland",
    Habitat_B >= Habitat_A & Habitat_B >= Habitat_C ~ "Forest",
    TRUE ~ "Other"
  ))

DB2_habitat <- DB2 %>%
  left_join(habitat_richness %>% select(CellID, Habitat_Dominant),
            by = c("Cell" = "CellID"))





plot_habitat_espece <- function(espece, data = DB2_habitat) {
  
  df <- data %>%
    filter(ID == espece) %>%
    count(Habitat_Dominant, name = "n") %>%
    mutate(
      espece = espece,
      pct = 100 * n / sum(n)
    )
 
  
  ggplot(df, aes(x = espece, y = pct, fill = Habitat_Dominant)) +
    geom_col(width = 0.6, color = "black", linewidth = 0.8) +
    geom_text(
      aes(label = paste0(round(pct), "%")), position = position_stack(vjust = 0.5), size = 4, fontface = "bold", color = "black"  ) +
    coord_flip() +
    scale_y_continuous(
      limits = c(0, 100),
      breaks = seq(0, 100, 10),
      expand = c(0, 0)
    ) +
    scale_fill_manual(values = c(
      "Grassland" = "yellow",  "Forest"   = "darkgreen", "Other" = "grey" )) +
    labs(
      title = paste("Habitats —", espece),
      x = NULL, y = NULL, fill = NULL ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", size = 15, margin = margin(b = 14)),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = 10),
      axis.ticks.x = element_line(color = "black"),
      axis.line.x = element_line(color = "black"),
      panel.grid = element_blank(),
      legend.position = "right",
      legend.direction = "vertical",
      legend.text = element_text(size = 12, face = "bold"),
      legend.key.size = unit(1.3, "lines"),
      legend.spacing.y = unit(0.5, "cm"),
      plot.margin = margin(t = 15, r = 10, b = 10, l = 10)
    )
}
# focale / radius 

plot_habitat_espece("Volucella zonaria")


DB2_habitat <- DB2[DB2$Source == "Hand netting",] %>%
  left_join(habitat_richness %>% select(CellID, Habitat_Dominant),
            by = c("Cell" = "CellID"))







