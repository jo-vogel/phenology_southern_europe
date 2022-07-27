# Plant functional types

# Monthly data
# can be run externally (by loading the data here), but is also implemented in the work flow of Basic_setup.R
# load(file="./Code/Workspaces/data_red.RData")
# Daily data
# load(file="./Code/Workspaces/data_red_daily.RData")
# load(file="./Code/Workspaces/data_red_daily_des.RData")

# IGBP classification https://fluxnet.org/data/badm-data-templates/igbp-classification/
sort(table(data_red$species))

# assign a type to each plant
# create lookup table
tb <- c("Acer platanoides" = "Deciduous broadleaf tree", "Crataegus" = "Shrub", "Salix" = "Deciduous broadleaf tree", "Citrus limon" = "Evergreen broadleaf tree", 
        "Laurus nobilis" = "Evergreen broadleaf tree", "Rosa" = "Shrub", "Olea europaea" = "Evergreen broadleaf tree", 
        "Hordeum vulgare Winter" = "Crop", "Secale cereale Winter" = "Crop", "Picea abies" = "Evergreen needleleaf tree", 
        "Taraxacum officinale" = "Perennial herb", "Solanum tuberosum" = "Crop", "Zea mays" = "Crop", "Vitis vinifera" = "Other (Shrub)",
        "Larix decidua" = "Deciduous needleleaf tree", "Sambucus nigra" = "Shrub", "Ficus carica"= "Deciduous broadleaf tree", 
        "Populus" = "Deciduous broadleaf tree", "Punica granatum" = "Deciduous broadleaf tree", "Citrus aurantium" = "Evergreen broadleaf tree",
        "Forsythia suspensa" = "Shrub", "Prunus armeniaca" = "Deciduous broadleaf tree", "Fragaria vesca" = "Perennial herb", "Populus tremula" = "Deciduous broadleaf tree",
        "Calluna vulgaris" = "Shrub (evergreen)", "Juglans regia" = "Deciduous broadleaf tree", "Prunus cerasus" = "Deciduous broadleaf tree", 
        "Betula pubescens" = "Deciduous broadleaf tree", "Prunus persica" = "Deciduous broadleaf tree", "Prunus amygdalus" = "Deciduous broadleaf tree",
        "Fraxinus excelsior" = "Deciduous broadleaf tree", "Vaccinium myrtillus" = "Shrub", "Salix caprea" = "Deciduous broadleaf tree", 
        "Tilia platyphyllos" = "Deciduous broadleaf tree", "Dactylis glomerata" = "Perennial herb", "Alnus glutinosa" = "Deciduous broadleaf tree",
        "Prunus spinosa" = "Shrub", "Cornus mas" = "Shrub", "Hordeum vulgare Summer" = "Crop", "Tussilago farfara" = "Perennial herb", 
        "Ribes rubrum" = "Shrub", "Galanthus nivalis" = "Perennial herb", "Acer pseudoplatanus" = "Deciduous broadleaf tree", "Avena sativa Summer" = "Crop",
        "Triticum aestivum Winter" = "Crop", "Quercus robur" = "Deciduous broadleaf tree", "Syringa vulgaris" = "Shrub", "Zea mays" = "Crop",
        "Sorbus aucuparia" = "Deciduous broadleaf tree", "Robinia pseudoacacia" = "Deciduous broadleaf tree", "perm_grass" = "Herb (Grass)", 
        "Prunus domestica" = "Deciduous broadleaf tree", "Pyrus communis" = "Deciduous broadleaf tree", "Tilia cordata" = "Deciduous broadleaf tree",
        "Malus domestica" = "Deciduous broadleaf tree", "Corylus avellana" = "Shrub", "Betula pendula" = "Deciduous broadleaf tree", "Fagus sylvatica" = 
        "Deciduous broadleaf tree", "Prunus avium" = "Deciduous broadleaf tree", "Aesculus hippocastanum" = "Deciduous broadleaf tree", "Secale cereale" = "Crop",
        "Rosmarinus officinalis" = "Perennial herb", "Cistus ladanifer" = " Perennial herb", "Avena sativa Winter" = "Crop", "Cicer arietinum" = "Crop", "Prunus  dulcis" = "Deciduous broadleaf tree",
        "Quercus pyrenaica" = "Deciduous broadleaf tree", "Cydonia oblonga (= Cydonia vulgaris)" = "Deciduous broadleaf tree", "Vicia faba" = "Crop",
        "Castanea sativa" = "Deciduous broadleaf tree", "Malus domestica (= Malus pumila)" = "Deciduous broadleaf tree",
        "Spartium junceum" = "Shrub", "Mespilus germanica" = "Deciduous broadleaf tree", "Quercus ilex" = "Evergreen broadleaf tree", "Crataegus monogyna" = "Shrub",
        "Acer campestre" = "Deciduous broadleaf tree", "Pisum sativum" = "Annual herb", "Salix alba" = "Deciduous broadleaf tree",
        "Nerium oleander" = "Shrub (evergreen)", "Populus alba" = "Deciduous broadleaf tree", "Populus nigra" = "Deciduous broadleaf tree",
        "Genista scorpius" = "Shrub", "Cistus laurifolius" = "Shrub (evergreen)", "Fraxinus angustifolia" = "Deciduous broadleaf tree",
        "Betula pubescens (B. alba = B. celtiberica)" = "Deciduous broadleaf tree", "Populus sp." = "Deciduous broadleaf tree", "Salix sp." = "Deciduous broadleaf tree",
        "Triticum sp. Winter" = "Crop", "Hordeum vulgare Spring" = "Crop") 

data_red$plant_type <- tb[data_red$species]
par(mar=c(3,12,1,2))
barplot(sort(table(data_red$plant_type, useNA = "ifany")), horiz=T, las=1)
table(data_red$plant_type, useNA = "ifany")




# Category suggestion
# a) Broadleaf tree, b) Shrub, c) Crop, d) Herb, e) Needleleaf tree


# get most frequent representative of each type
# Deciduous broadleaf tree: Aesculus hippocastanum (374)
# Shrub: Sambucus nigra (212)
# Crop: Zea mays (92)
# Deciduous needleleaf tree: Larix decidua (121)
# Evergreen needleleaf tree: Picea abies (39)
# Herb: Taraxacum officinale (44)
# Evergreen broadleaf tree: Olea europaea (10)

# you could use one Broadleaf tree, shrub, crop and needleleaf tree as four exemplary species
# you can also try to find species which are associated typically with the Mediterranean



# Aggregated phenophases --------------------------------------------------



phases <- c("Dry seed", " Beginning of sprouting", "Coleoptile breaks through soil surface", "First true leaf emerged from coleoptile", "First true leaf, leaf pair or whorl unfolded",
            "2 true leaves, leaf pairs or whorls unfolded", "3 true leaves, leaf pairs or whorls unfolded", "4 true leaves, leaf pairs or whorls unfolded", "5 true leaves, leaf pairs or whorls unfolded",
            "Stem (rosette) 10% of final length", "Maximum stem length or rosette diameter", "Maximum of total tuber mass reached", "Harvestable vegetative plant parts or vegetatively propagated organs have reached final size",
            "Flower buds present", "Inflorescence or flower buds visible", "First individual flowers visible", "First flower petals visible", "Beginnin of flowering", "10% of flowers open",
            "20% of flowers open", "30% of flowers open", "50% of flowers open", "Flowering finishing", "End of flowering", "50% of fruits have reached final size", "olive: fruit deep green colour becomes lightgreen, yellowish",
            "Beginning of ripening or fruit colouration", "Advanced ripening or fruit colouration", "Fruit begins to soften", "Fully ripe: fruit shows fully-ripe colour", "Shoot development completed",
            "Beginning of leaf-fall", "50% of leaves fallen", "End of leaf fall", "start of harvest", "	first cut for silage winning", "first cut for hay winning", "first cut for hay winning (=> 50% of the area)",
            "end of first cut for hay winning", "start of Corn - cob - mix harvest for silage", "25% of the permanent grassland shows fresh green", "start of autumnal colouration", "autumnal colouration >=50%",
            "end of autumnal colouration", "Leaf unfolding (>=50%)", "Grapevine bleeding", "first ripe fruits")

# Group phases
# sprout <- c(7, 9, 10, 11, 12, 13, 14, 15, 31, 223)
# growth <- c(39, 48, 49, 91)
# flower <- c(50, 51, 55, 60, 61, 62, 63, 65, 67, 69)
# fruit <- c(75, 80, 81, 85, 87, 89, 286)
# senes <- c(93, 95, 97, 201, 205, 209)
# harv <- c(100, 111, 131, 135, 139, 161)
# # not assigned: 0, 182, 250
sprout <- c(5, "05X", 7, "07X", 9, "09X", 10, "10X", 11, "11X", 12, "12X", 13, 14, 15, 31, "31X", 223)
growth <- c("21X", 39, "43X", 48, 49, 91)
# flower <- c(50, 51, "51M", "51X", 55, "55M", "55X", "59M", "59X", 60, "60X", 61, "61F", 62, 63, "63F", "63M", "63X", 65, "65F", "65M", "65X", 67, 69, "69F", "69M", "69X")
flower <- c(50, 51, "51M", "51X", "53F", "53M", "53X", 55, "55M", "55X", "59M", "59X", 60, "60X", 61, "61F", 62, 63, "63F", "63M", "63X", 65, "65F", "65M", "65X", 67, 69, "69F", "69M", "69X")
# fruit <- c(71, "71X", 75, "79X", 80, "80X", 81, "81X", 85, "85X", 87, "87X", 89, "89X", 286)
fruit <- c(71, "71X", 75, "79X", 80, "80X", 81, "81X", "83X", 85, "85X", 87, "87X", 89, "89X", 286)
# senes <- c(93, "93X", 95, "95X", 97, "97X", 201, 205, 209)
senes <- c("92X", 93, "93X", "94X", 95, "95X", 97, "97X", 201, 205, 209)
harv <- c(100, 111, 131, 135, 139, 161, "9RX")
# # not assigned: 0, 0SX, 53F, 53M, 53X, 83X, 92X, 94X, 98X, 182, 250, 551
# not assigned: 0, 0SX, 98X, 182, 250, 551

data_red$phase_type <- NA
data_red$phase_type[data_red$phase_id %in% sprout] <- "sprout"
data_red$phase_type[data_red$phase_id %in% growth] <- "growth"
data_red$phase_type[data_red$phase_id %in% flower] <- "flower"
data_red$phase_type[data_red$phase_id %in% fruit] <- "fruit"
data_red$phase_type[data_red$phase_id %in% senes] <- "senes"
data_red$phase_type[data_red$phase_id %in% harv] <- "harv"
table(data_red$phase_type, useNA = "ifany")

# only save it if not used with Basic_setup.R
# save(data_red, file="./Code/Workspaces/data_red.RData")
# save(data_red, file="./Code/Workspaces/data_red_daily.RData")
# save(data_red, file="./Code/Workspaces/data_red_daily_des.RData")