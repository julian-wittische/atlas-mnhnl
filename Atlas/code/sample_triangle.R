# 
# 
# ## FG CORRELATIONS ----
# 
# # Keep one line with all covers values per functional group 
# dom.fg2 <- itex.dec22 %>% distinct(SiteSubsitePlot, .keep_all = TRUE)
# 
# # Shrub vs Graminoid
# shrub.gram.mod <- brm(PlotGraminoidMean ~ PlotShrubMean, 
#                       data = dom.fg2, iter = 2000, chains = 4, warmup = 400, 
#                       file = "smodels/shrub_gram_mod")
# summary(shrub.gram.mod) # negative significant: more shrubs, less grams. More grams, less shrubs
# 
# # Shrub vs Forb
# shrub.forb.mod <- brm(PlotForbMean ~ PlotShrubMean, 
#                       data = dom.fg2, iter = 2000, chains = 4, warmup = 400, 
#                       file = "models/shrub_forb_mod")
# summary(shrub.forb.mod) # negative significant: more shrubs, less forbs. More forbs, less shrubs.
# 
# # Forb vs Graminoid
# gram.forb.mod <- brm(PlotGraminoidMean ~ PlotForbMean, 
#                      data = dom.fg2, iter = 2000, chains = 4, warmup = 400, 
#                      file = "models/gram_forb_mod")
# summary(gram.forb.mod) # negative significant: more grams, less forbs - more forbs, less grams.
# 
# 
# ## TERNARY PLOT (FIG 1C)
# (tern.plot <- ggtern(data = dom.fg2, aes(x = PlotForbMean, y = PlotGraminoidMean, z = PlotShrubMean)) +
#     geom_point(size = 3, alpha = 0.5, aes(colour = MeanRichness)) +
#     labs(x="Forb Cover", y="Graminoid Cover", z="Shrub Cover", colour = "Plot Richness") +
#     scale_colour_viridis(option = "plasma", begin = 0, end = 0.95) + theme_bw() + 
#     theme(legend.title = element_text(size = 26), legend.text=element_text(size = 20), 
#           tern.axis.text.T = element_text(size =22), tern.axis.text.L = element_text(size =22), 
#           tern.axis.text.R = element_text(size =22), tern.axis.title.T = element_text(size =28), 
#           tern.axis.title.L = element_text(size =28), tern.axis.title.R = element_text(size =28)))
# 
# ggsave(tern.plot, filename = "figures/Figure_1c.png", 
#        width = 25, height = 25, units = "cm")