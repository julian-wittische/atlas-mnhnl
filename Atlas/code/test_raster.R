
# nb observations par espece
species_counts <- DB %>% count(ID, name = "n_obs")

#  seuil de 80 espece
species_keep <- species_counts %>% filter(n_obs >= 80) %>% pull(ID)
DB_filtered <- DB %>% filter(ID %in% species_keep)

#  nb d'observations par cellule
obscell <- DB_filtered %>%
  count(ID, Cell) %>%
  pivot_wider(names_from = Cell, values_from = n, values_fill = 0)  # 1 colonne par cellule

# on recupere les noms d'espece 
cell_species <- obscell$ID

# transforme en matrice (ID exclut)
obscell <- as.matrix(obscell[, -1])
# nom especes en titres
rownames(obscell) <- cell_species

# precense/absence

obscell_pa <- (obscell > 0) * 1

#matrice distance
dist_mat <- dist(obscell_pa, method = "binary")

# clustering hierarchique
hc <- hclust(dist_mat, method = "ward.D2")

# dendrogramme
plot(hc, labels = rownames(obscell_pa))


clusters <- cutree(hc, k = 2)
data.frame(espece = names(clusters), cluster = clusters)
table(clusters)





library(vegan)



dist_jaccard <- vegdist(obscell, method = "jaccard", binary = T)

clust_jaccard <- hclust(dist_jaccard)
dendro_jaccard <- as.dendrogram(clust_jaccard)
 
plot(dendro_jaccard, 
 horiz = T, 
 nodePar = list(pch = c(1, NA), cex = 0.5, lab.cex = 0.6),
  main = "Dendrogramme")

