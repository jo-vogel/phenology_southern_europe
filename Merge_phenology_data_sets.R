# Make one consistent phenological data set
# Date 07.06.21


# Data sets ####
# phen
# plantas_comb
# agroclim_pro
# agroclim_inrae
# GniPS

library(raster)
library(tidyverse)
library(ncdf4)
library(pbapply)
library(rgdal)



# PEP725
phen <- readr::read_delim("./Code/Data/pep725_Vogel/Original/pep725_2020-11_0.csv", delim = ";", col_types = (cols(subspecies = col_character()))) # use col_types to correct display of subspecies (character, not logical)

# France
# Old
pheno <- read.csv("./Code/Data/perpheclim_Vogel_Johannes_Joscha_201904171559/pheno.csv", sep = ";") 
# New
ods <- read.csv("./Code/Data/tempo_Vogel_Johannes_202011241704/ODS Tela Botanica.csv", sep = ";") 
GnpIS <- read.csv("./Code/Data/tempo_Vogel_Johannes_202011241704/GnpIS.csv", sep = ";")
# agroclim_pro <- read.csv("./Code/Data/tempo_Vogel_Johannes_202011241704/Phenoclim Agroclim Pro.csv", sep = ";")
agroclim_inrae <- read.csv("./Code/Data/tempo_Vogel_Johannes_202011241704/Phenoclim Agroclim INRAE.csv", sep=";")
agroclim_pro <- read.csv("./Code/Data/tempo_Vogel_Johannes_202106101012/phenoclim_agroclim_pro.csv", sep = ";")
colnames(agroclim_pro) <- colnames(agroclim_inrae)
agroclim_inrae <- read.csv("./Code/Data/tempo_Vogel_Johannes_202106101012/phenoclim_agroclim_inrae.csv", sep=";")
colnames(agroclim_inrae) <- colnames(agroclim_pro)
common_dat <- read.csv("./Code/Data/tempo_Vogel_Johannes_202106101012/common_data.csv", sep=";")

# Spain
# Old
plantas <- read.csv("./Code/Data/Phenological data Spain/Datos990190317/Plantas.csv", sep = ";")
# New
Agricolas <- read.csv("./Code/Data/Phenological data Spain/Datos_20_12_03/Agricolas.csv", sep = ";") 
Silvestres <- read.csv("./Code/Data/Phenological data Spain/Datos_20_12_03/Silvestres.csv", sep = ";") 



# Join the datasets for Spain

# Coordinates
# get all unique combinations
combis_coord <- tidyr::expand(plantas, nesting(C_X, C_Y, LONGITUD, LATITUD))
# use combis3 to make a lookup table
lons <- combis_coord$C_X
names(lons) <- combis_coord$LONGITUD
lats <- combis_coord$C_Y
names(lats) <- combis_coord$LATITUD
Silvestres$C_X <- lons[as.character(Silvestres$LONGITUD)]
Silvestres$C_Y <- lats[as.character(Silvestres$LATITUD)]
Agricolas$C_X <- lons[as.character(Agricolas$LONGITUD)]
Agricolas$C_Y <- lats[as.character(Agricolas$LATITUD)]


# Umbenennen
colnames(Agricolas)[1:7] <- colnames(plantas)[1:7]
colnames(Agricolas)[8:9] <- colnames(plantas)[22:23]
colnames(Agricolas)[10:11] <- colnames(plantas)[28:29]
colnames(Agricolas)[12:13] <- colnames(plantas)[33:34]
colnames(Agricolas)[14:15] <- colnames(plantas)[12:13]
colnames(Agricolas)[16] <- colnames(plantas)[30]
Agricolas <- Agricolas %>% mutate(DESCRIPCION_GRUPO = "Plantas agr�colas")
Agricolas <- Agricolas %>% mutate(RIEGO = NA)
colnames(Silvestres)[1:7] <- colnames(plantas)[1:7]
colnames(Silvestres)[8:9] <- colnames(plantas)[22:23]
colnames(Silvestres)[10:11] <- colnames(plantas)[28:29]
colnames(Silvestres)[12:13] <- colnames(plantas)[33:34]
colnames(Silvestres)[14:15] <- colnames(plantas)[12:13]
colnames(Silvestres)[16] <- colnames(plantas)[30]
Silvestres <- Silvestres %>% mutate(DESCRIPCION_GRUPO = "Plantas silvestres")
Silvestres <- Silvestres %>% mutate(RIEGO = NA)
# Zusätzliche Spalten löschen
plantas_short <- plantas
# plantas_short <- plantas_short %>% select(-c(8:11,14,16:21,24:27,31,35:44))
plantas_short <- plantas_short %>% dplyr::select(-c(10:11,14,16:21,24:27,31,35:44))
Silvestres <- Silvestres %>% dplyr::select(-c(17:18))
# Neu arrangieren
Agricolas <- Agricolas[,c(1:7,17:18,14:15,19,8:9,10:11,16,20,12:13)]
Silvestres <- Silvestres[,c(1:7,17:18,14:15,19,8:9,10:11,16,20,12:13)]
# Datum konsistent machen
plantas_short$FECHA <- paste0(str_sub(plantas_short$FECHA, start=7, end=10), "-", str_sub(plantas_short$FECHA, start=4, end=5), "-", str_sub(plantas_short$FECHA, start=1, end=2))
# Datensätze kombinieren
plantas_comb <- rbind(plantas_short,Agricolas,Silvestres)
plantas_comb <- plantas_comb[which(!is.na(plantas_comb$C_X)),] # exclude entries, which only exist in the new data set and therefore the coordinates are unknown
# write.csv(plantas_comb, file="./Code/Data/Phenological data Spain/Datos990190317/Plantas_comb.csv")
plantas_comb_sp <- readOGR(dsn="D:/user/vogelj/Phenology/Code/Data/Phenological data Spain/Datos990190317", layer="plantas_comb")
plantas_comb$lat <- plantas_comb_sp@coords[,2]
plantas_comb$lon <- plantas_comb_sp@coords[,1]



# convert GnpIS phenophases to BBCH scale ####
##############################################
# phenological states can be related to states 7, 65, 81
# lookup table
phen_conv <- c( "Date bourgeonement" = NA,   "Veraison date (50%)" = 81,  "Flowering date (50%)" = 65, "Budbreak date (50%)" = 7) # Date bourgeonement exists only for 2015
GnpIS$phase_id <- phen_conv[GnpIS$Description.du.stade]
GnpIS <- GnpIS[!is.na(GnpIS$phase_id),]# exclude NAs


# Create joint data set ####
############################

# Add data set name as column to each data set
phen$dataset <- "PEP725"
plantas_comb$dataset <- "AEMET"
agroclim_inrae$dataset <- "agroclim_inrae"
agroclim_pro$dataset <- "agroclim_pro"
# combine both agroclim data sets
agroclim_all <- rbind(agroclim_inrae, agroclim_pro)
GnpIS$dataset <- "GnpIS"

# Nom.scientifique is too specific, merge agroclim_all$Genre and agroclim_all$Espèce instead
agroclim_all$species <- paste(agroclim_all$Genre, agroclim_all$Espèce)
GnpIS$species <- paste(GnpIS$Genre, GnpIS$Espèce)

# Extract year of the date
plantas_comb$year <- str_sub(plantas_comb$FECHA, start=1, end=4) 

# use genus where species is unavailable
phen$species[which(is.na(phen$species == ""))] <- phen$genus[which(is.na(phen$species == ""))] # use genus where species is unavailable
phen$species[grep("Ficus", phen$species)] <- "Ficus carica" # Correct the erroneous display of Ficus carica

# Extract main variables
phen_main_var <- phen[,c("lon", "lat", "alt", "species", "phase_id", "day", "date", "year", "dataset", "cult_season", "affected_flag")]
agroclim_main_var <- agroclim_all[,c("Longitude.du.site", "Latitude.du.site", "Altitude.du.site", "species", "Code.du.stade", "Jour.de.l.année", "Date.AAAA.MM.JJ", "Année", "dataset")]
GnpIS_main_var <- GnpIS[, c("Longitude.du.site", "Latitude.du.site", "Altitude.du.site", "species", "Code.du.stade", "Jour.de.l.année", "Date.AAAA.MM.JJ", "Année", "dataset")]
# plantas_main_var <- plantas_comb[,c("LONGITUD", "LATITUD", "ALTITUD", "NOMBRE_ESPECIE", "COD_EST", "DIA_JULIANO", "FECHA", "dataset", "COMENTARIOS_OBSERVACION", "RIEGO")]
plantas_main_var <- plantas_comb[,c("lon", "lat", "ALTITUD", "NOMBRE_ESPECIE", "COD_EST", "DIA_JULIANO", "FECHA", "year", "dataset", "DESCRIPCION_VARIEDAD", "COMENTARIOS_OBSERVACION", "RIEGO")]
# add missing columns in other data sets
phen_main_var$COMENTARIOS_OBSERVACION <- NA
phen_main_var$RIEGO <- NA
agroclim_main_var$cult_season <- NA
agroclim_main_var$affected_flag <- NA
agroclim_main_var$COMENTARIOS_OBSERVACION <- NA
agroclim_main_var$RIEGO <- NA
GnpIS_main_var$cult_season <- NA
GnpIS_main_var$affected_flag <- NA
GnpIS_main_var$COMENTARIOS_OBSERVACION <- NA
GnpIS_main_var$RIEGO <- NA
plantas_main_var$affected_flag <- NA
# arrange columns correctly
plantas_main_var <- plantas_main_var[,c(1:10, 13, 11:12)]
colnames(agroclim_main_var) <-  colnames(phen_main_var)
colnames(GnpIS_main_var) <-  colnames(phen_main_var)
colnames(plantas_main_var) <-  colnames(phen_main_var)

# Convert phases to factors
"spanish phenology phase distinguishes male (M) and female (F)"
phen_main_var$phase_id <- as.factor(phen_main_var$phase_id)
agroclim_main_var$phase_id <- as.factor(agroclim_main_var$phase_id)
GnpIS_main_var$phase_id <- as.factor(GnpIS_main_var$phase_id)
plantas_main_var$phase_id <- as.factor(plantas_main_var$phase_id)

# add altitude from DEM at locations of french stations

# load DEM
DEM_proj <- raster("./Code/Data/DEM/eu_dem_v11_E30N20_projWGS84.tif") # projected DEM created with QGIS

# plot DEM and french stations
agroclim_all_coord <- paste(agroclim_main_var$lon,agroclim_main_var$lat)
agroclim_all_coord_unique <- agroclim_main_var[!duplicated(agroclim_all_coord),]
agroclim_all_sp <- SpatialPoints(coords = data.frame(agroclim_all_coord_unique$lon,agroclim_all_coord_unique$lat), proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

GnpIS_all_coord <- paste(GnpIS_main_var$lon,GnpIS_main_var$lat)
GnpIS_all_coord_unique <- GnpIS_main_var[!duplicated(GnpIS_all_coord),]
GnpIS_all_sp <- SpatialPoints(coords = data.frame(GnpIS_all_coord_unique$lon,GnpIS_all_coord_unique$lat), proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

plot(DEM_proj)
points(GnpIS_all_sp, col="blue", pch=4)
points(agroclim_all_sp, col="orange", pch=7)

# extract altitude at locations of french stations
agroclim_main_var_alt <- raster::extract(DEM_proj, agroclim_all_sp, df=T)
GnpIS_main_var_alt <- raster::extract(DEM_proj, GnpIS_all_sp, df=T)
agroclim_all_coord_unique$alt <- agroclim_main_var_alt$eu_dem_v11_E30N20_projWGS84
GnpIS_all_coord_unique$alt <- GnpIS_main_var_alt$eu_dem_v11_E30N20_projWGS84
agroclim_lonlat <- paste(agroclim_main_var$lon, agroclim_main_var$lat)
agroclim_unique_lonlat <- paste(agroclim_all_coord_unique$lon, agroclim_all_coord_unique$lat)
GnpIS_lonlat <- paste(GnpIS_main_var$lon, GnpIS_main_var$lat)
GnpIS_unique_lonlat <- paste(GnpIS_all_coord_unique$lon, GnpIS_all_coord_unique$lat)
agroclim_main_var$alt <- agroclim_main_var_alt[match(agroclim_lonlat, agroclim_unique_lonlat),2]
GnpIS_main_var$alt <- GnpIS_main_var_alt[match(GnpIS_lonlat, GnpIS_unique_lonlat),2]


# combine all data sets
all_phen <- rbind(phen_main_var, agroclim_main_var, GnpIS_main_var, plantas_main_var)
all_phen$year <- as.numeric(all_phen$year)
# save(all_phen, file="D:/user/vogelj/Phenology/Code/Workspaces/all_phen.RData")









# Plot phenological maps

phen_coord <- paste(phen$lon,phen$lat)
phen_coord_unique <- phen[!duplicated(phen_coord),]
phen_sp <- SpatialPoints(coords = data.frame(phen_coord_unique$lon,phen_coord_unique$lat), proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

plantas_coord <- paste(plantas_main_var$lon,plantas_main_var$lat)
plantas_coord_unique <- plantas_main_var[!duplicated(plantas_coord),]
plantas_sp <- SpatialPoints(coords = data.frame(plantas_coord_unique$lon,plantas_coord_unique$lat), proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

tg_nc <- nc_open("D:/user/vogelj/Data/E-OBS/Processed/tg_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc")
lon <- ncvar_get(tg_nc, "longitude")
lat <- ncvar_get(tg_nc, "latitude")
nc_close(tg_nc)

tg_daily_nc <- nc_open("D:/user/vogelj/Data/E-OBS/Processed/tg_ens_mean_0.1deg_reg_v23.0e_crop.nc")
tg_daily <- ncvar_get(tg_daily_nc, start=c(1,1,1), count=c(-1,-1,-1))
nc_close(tg_daily_nc)
tg_ras <- raster(t(tg_daily[, , 1]), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
tg_ras <- flip(tg_ras, direction='y')

plot(tg_ras)
points(phen_sp)
points(agroclim_all_sp, col="blue", pch=4)
points(agroclim_all_sp, col="orange", pch=7)
points(plantas_sp, col="red", pch=3)
