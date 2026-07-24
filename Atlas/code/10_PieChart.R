######################## PROJECT: Atlas Template
# Author: Selene Perez
# Request: Julian Wittische
# Start: Summer 2026
# Script objective : pie chart for tribe and subfamily

####### Tribes ---

plot_tribe_pie <- function(DB_taxo) {
  tribe_counts <- DB_taxo %>%
    filter(!is.na(Tribe)) %>%
    count(Tribe, name = "n") %>%
    left_join(distinct(DB_taxo, Tribe, Subfamily), by = "Tribe") %>%
    arrange(Subfamily, Tribe) %>%
    mutate(
      Tribe = factor(Tribe, levels = Tribe),
      prop = n / sum(n),
      label = paste0(Tribe, "\n(", n, ")"),
      ypos = cumsum(n) - 0.5 * n
    )
  
  base_colors <- setNames(hue_pal()(n_distinct(tribe_counts$Subfamily)), unique(tribe_counts$Subfamily))
  
  tribe_palette <- tribe_counts %>%
    distinct(Subfamily, Tribe) %>%
    group_by(Subfamily) %>%
    group_map(~ setNames(
      colorRampPalette(c(lighten(base_colors[[.y$Subfamily]], 0.5),
                         darken(base_colors[[.y$Subfamily]], 0.3)))(nrow(.x)),
      as.character(.x$Tribe)
    )) %>%
    unlist()
  
  legend_order <- levels(tribe_counts$Tribe)
  
  ggplot(tribe_counts, aes(x = "", y = n, fill = Tribe)) +
    geom_col(width = 1, color = "white", position = position_stack(reverse = TRUE)) +
    coord_polar(theta = "y") +
    scale_fill_manual(values = tribe_palette, breaks = legend_order) +
    theme_void() +
    theme(legend.position = "right", legend.text = element_text(size = 13), legend.title = element_text(size = 15)) +
    geom_text(aes(y = ypos, label = ifelse(prop > 0.04, label, "")),  color = "white", size = 3.5, fontface = "bold") +
    geom_text_repel(
      data = subset(tribe_counts, prop <= 0.04), aes(y = ypos, label = label),size = 3.5, nudge_x = 0.7, segment.color = NA, show.legend = FALSE
    )
}

# tribu de meme sous espece avec meme nuance de couleur

####### Subfamily ---
plot_subfamily_pie <- function(DB_taxo) {
  Subfamily_counts <- DB_taxo %>%
    filter(!is.na(Subfamily)) %>%
    count(Subfamily, name = "n") %>%
    mutate(
      prop = n / sum(n),
      label = paste0(Subfamily, "\n(", n, ")")
    ) %>%
    arrange(desc(Subfamily)) %>%
    mutate(ypos = cumsum(n) - 0.5 * n)
  
  ggplot(Subfamily_counts, aes(x = "", y = n, fill = Subfamily)) +
    geom_col(width = 1, color = "white") +
    coord_polar(theta = "y") +
    theme_void() +
    theme(legend.position = "right", legend.text = element_text(size = 13), legend.title = element_text(size = 15)) +
    geom_text(aes(y = ypos, label = ifelse(prop > 0.04, label, "")), color = "white", size = 3.5, fontface = "bold") +
    geom_text_repel(
      data = subset(Subfamily_counts, prop <= 0.04), aes(y = ypos, label = label), size = 3.5, nudge_x = 0.7, segment.color = NA, show.legend = FALSE
    )
}



