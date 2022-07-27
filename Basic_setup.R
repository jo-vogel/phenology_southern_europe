# Basic setup
# 26.02.21

# Document structure ####
# Load data: climate and phenological data
# get coordinates of phenological data
# extract climate variables at these coordinates (var_loc)
# data reduction: exclude certain countries and exclude entries impaired by pest/disease
# split time series belonging to various crop cultivation seasons (phen_red: first usable set of all meaningful time series)
# add meta data on year and month
# Removal of duplicates by averaging per year for a given combination of species, location and phase
# Relate phenological data with climate variables at certain time lags
# Exclusions
# Exclusion of all the entries with dates before 1950 and entries located in the sea
# Exclude short time series
# Exclude phenophase at the transition from one year to another
# Exclude all entries which are beyond 3*IQR away from the box
# Exclude time series with less than 3 unique values
# Exclude short time series again 
# Add phase_type and plant_type
# Calculate deviations from the mean date
# Add categories of yearly precipitation sums


# Parameters
# fixed and flexible date
# time step and span
# climatic data set (raw / deseasonalised, which moving window)

library(ncdf4)
library(pbapply)
library(tictoc)
library(glmnet)
library(maps)
library(tidyverse)
library(lubridate)
library(raster)
library(foreach)
library(doParallel)


# Load data ---------------------------------------------------------------

# Get coordinates
# Mediterranean extent from previous study: xmin: -11.50446, xmax: 47.18304, ymin: 26.80804, ymax: 48.02232
# Note that the data here does not extent so far to the East as in the previous study
tg_nc <- nc_open("D:/user/vogelj/Data/E-OBS/Processed/tg_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc")
lon <- ncvar_get(tg_nc, "longitude")
lat <- ncvar_get(tg_nc, "latitude")
nc_close(tg_nc)

# load climate data using ncdf4
# var_list <- c("rr_ens_mean_0.1deg_reg_v23.0e_runsum30zip.nc", "tg_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc")
var_list <- c("rr_ens_mean_0.1deg_reg_v23.0e_runsum30_des.nc", "tg_ens_mean_0.1deg_reg_v23.0e_runmean30_des.nc")
var_nc <- vector("list",length(var_list))
vars <- vector("list",length(var_list))
tic()
for (i in 1:length(var_list)){
  var_nc[[i]] <- nc_open(paste0("D:/user/vogelj/Data/E-OBS/Processed/",var_list[i]))
  vars[[i]] <- ncvar_get(var_nc[[i]], start=c(1,1,1), count=c(-1,-1,-1))
  nc_close(var_nc[[i]])
}
toc() # appr. 75 sec for one file
names(var_nc) <- var_list
names(vars) <- var_list


# Phenological data
load("./Code/Workspaces/all_phen.RData") # created with Merge_phenology_data_sets.R
phen <- all_phen

lag_num <- 365
# lag_num <- 180
the_step <- 30
# the_step <- 1
ints <- seq(0,lag_num,the_step) # the time steps of the predictor variables

# Create raster ---------------------------------------------------------------
var_ras <- raster(t(vars[[var_list[1]]][, , 1]), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
var_ras <- flip(var_ras, direction='y')


# Extract climatic predictors at location of phenological observations -------------

phen_coord <- paste(phen$lon,phen$lat)
phen_coord_unique <- phen[!duplicated(phen_coord),]
loc_num <- dim(phen_coord_unique)[1] # Total number of station locations

phen_sp <- SpatialPoints(coords = data.frame(phen_coord_unique$lon,phen_coord_unique$lat), proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
plot(var_ras)
points(phen_sp)

fd_at_loc <- raster::extract(var_ras, phen_sp, cellnumbers=T) # get the cell numbers of the fd pixels corresponding to the phenological observation locations
rowcols <- rowColFromCell(var_ras, fd_at_loc[,1]) # get rows and columns corresponding to the cells
# ?rowFromCell:  Cell numbers start at 1 in the upper left corner, and increase from left to right, and then from top to bottom
# So, it is not handled like matrices in R, but the columns come first, then the rows

# get values from array
rowcols[,1] <- length(lat) + 1 - rowcols[,1] # latitude goes from high to low numbers if you interpret a map like a matrix (top to bottom, left to right),
# but it goes from low to high numbers in the array (fd), so you have to invert it
var_loc <- vector("list",length(vars))
names(var_loc) <- var_list
for (j in seq_along(var_loc)){ # climate variables
  var_mat <- matrix(NA, loc_num, dim(vars[[1]])[3])
  for (i in 1:loc_num){ # Station locations
    var_mat[i,] <- vars[[j]][rowcols[i,2], rowcols[i,1],]
  }
  var_loc[[j]] <- var_mat
}  


# relate the phenological data table with all climatic predictors ####

tg_crop <- nc_open(paste0("D:/user/vogelj/Data/E-OBS/Processed/", var_list[2]))
days_since_1950 <- tg_crop[["dim"]][["time"]][["vals"]]
dates <- as_date(days_since_1950, origin="1950-01-01")
nc_close(tg_crop)

# associate column names of predictors with their date and
# associate row names of predictor tables with coordinates
for (i in seq_along(var_loc)){
  colnames(var_loc[[i]]) <- as.character(dates)
  row.names(var_loc[[i]]) <- unique(phen_coord)
}



# Reduce data (data quality check) ----------------------------------------

# Reduce based on certain features of single entries

phen_no_aff <- phen[!(phen$affected_flag!=0 & !is.na(phen$affected_flag)),] # exclude entries impaired by pest/disease
# http://www.pep725.eu/pep725_affected.php

# exclude Austria, (Romania) and Switzerland
point_country <- map.where("world", phen_no_aff$lon, phen_no_aff$lat)
barplot(sort(table(point_country)), horiz=T, las=2)
# phen_red <- phen_no_aff[-which(point_country=="Austria" | point_country=="Switzerland" | point_country=="Romania"),]
phen_red <- phen_no_aff[-which(point_country=="Austria" | point_country=="Switzerland"),]


# Differentiate cultivation season in species name (for Secale cereale the info is missing in seldom cases)
# http://www.pep725.eu/project/submitting.php
phen_red$cult_season[is.na(phen_red$cult_season)] <- 0 # avoid NAs, this makes it complicated. "0" means "not applicable"
phen_red$species[phen_red$cult_season==1] <- paste(phen_red$species[phen_red$cult_season==1], "Summer")
phen_red$species[phen_red$cult_season==2] <- paste(phen_red$species[phen_red$cult_season==2], "Winter")
phen_red$species[phen_red$cult_season=="avena de ciclo corto o de primavera"] <- paste(phen_red$species[phen_red$cult_season=="avena de ciclo corto o de primavera"], "Spring")
phen_red$species[phen_red$cult_season=="avena de ciclo largo o de invierno"] <- paste(phen_red$species[phen_red$cult_season=="avena de ciclo largo o de invierno"], "Winter")
phen_red$species[phen_red$cult_season=="cebada de ciclo corto o de primavera"] <- paste(phen_red$species[phen_red$cult_season=="cebada de ciclo corto o de primavera"], "Spring")
phen_red$species[phen_red$cult_season=="cebada de ciclo largo o de invierno"] <- paste(phen_red$species[phen_red$cult_season=="cebada de ciclo largo o de invierno"], "Winter")
phen_red$species[phen_red$cult_season=="centeno de ciclo largo o de invierno"] <- paste(phen_red$species[phen_red$cult_season=="centeno de ciclo largo o de invierno"], "Winter")
phen_red$species[phen_red$cult_season=="ciclo corto"] <- paste(phen_red$species[phen_red$cult_season=="ciclo corto"], "Spring")
phen_red$species[phen_red$cult_season=="ciclo largo"] <- paste(phen_red$species[phen_red$cult_season=="ciclo largo"], "Winter")
phen_red$species[phen_red$cult_season=="trigo blando de ciclo corto o de primavera"] <- paste(phen_red$species[phen_red$cult_season=="trigo blando de ciclo corto o de primavera"], "Spring")
phen_red$species[phen_red$cult_season=="trigo blando de ciclo largo o de invierno"] <- paste(phen_red$species[phen_red$cult_season=="trigo blando de ciclo largo o de invierno"], "Winter")
phen_red$species[phen_red$cult_season=="trigo de ciclo largo o de invierno"] <- paste(phen_red$species[phen_red$cult_season=="trigo de ciclo largo o de invierno"], "Winter")

# Subset of all time series (phen_red): add meta data
phen_red$lonlat <- paste(phen_red$lon,phen_red$lat)
phen_red$dates_split <- str_sub(phen_red$date, start=1, end=7) # get info on year and month
phen_red$month <- str_sub(phen_red$date, start=6, end=7) # get info on month



# Create list-columns (meta-data plus lists with corresponding climate and phenological data)
all_data <- phen_red %>%
  group_by(lonlat, phase_id, species, dataset) %>%
  nest()
all_data <- with(all_data, tibble(species, phase_id, lonlat, data, dataset)) # save it in the previous order (data in fourth column)


# Removal of duplicates (use average for the given year) ####
dups <- sapply(1:dim(all_data)[1], function(x) which(table(all_data[["data"]][[x]]$year) > 1))
dups_ind <- which(sapply(1:length(dups), function(x) length(dups[[x]])) > 0) # indices where duplicates occur

for (ind in dups_ind){
  for (i in names(which(table(all_data[["data"]][[ind]]$year) > 1))){
    all_data[["data"]][[ind]]$day[all_data[["data"]][[ind]]$year==i] <- round(mean(all_data[["data"]][[ind]]$day[all_data[["data"]][[ind]]$year==i])) # replace by average of the given year
    all_data[["data"]][[ind]] <- all_data[["data"]][[ind]][!duplicated(all_data[["data"]][[ind]]$year),] # keep only one entry for the given year with several entries
  }
}


# Calculate mean date for each combination of phase, species and lonlat ####
for (i in 1:dim(all_data)[1]){
  all_data[["data"]][[i]]$meanDOY <- round(mean(all_data[["data"]][[i]]$day))
  all_data[["data"]][[i]]$meanDate <- as.Date(all_data[["data"]][[i]]$meanDOY, origin = paste0(all_data[["data"]][[i]]$year, "-01-01")) # convert to date format
}
# phen$meanDate <- as.Date(phen$meanDOY, origin = paste0(phen$year, "-01-01")) # convert to date format




# Locations of stations without climatological data
na_var <- apply(var_loc[[var_list[1]]], 1, function(x) (all(is.na(x))))
which(na_var) # there are locations at the sea which have therefore NA values
na_var_loc <- names(which(na_var))
na_loc <- str_split(na_var_loc, " ", simplify = T)
phen_sp_red <- phen_sp[phen_sp@coords[,1] %in% na_loc[,1] & phen_sp@coords[,2] %in% na_loc[,2]]
plot(var_ras)
points(phen_sp_red)
# those locations will be jointly removed below with all the entries with dates before 1950
'exclude stations located in a grid pixels in the sea for now'



# Relate phenological data with climate variables at certain time lags  --------

phen <- unnest(all_data, cols = c(data))

# Avoid numeric(0), replace negative / zero entries by NA instead, so you do not get issues with the integrity of the data
relate_vars <- function(vari, thelag){
  map_dbl(1:dim(phen)[1], function(x) ifelse(match(as.character(phen$date[x]), colnames(vari)) - thelag <= 0, NA, 
                                             vari[match(phen$lonlat[x], row.names(vari)), match(as.character(phen$date[x]), colnames(vari)) - thelag ]) )
}

relate_vars_fixed <- function(vari, thelag){
  map_dbl(1:dim(phen)[1], function(x) ifelse(match(as.character(phen$meanDate[x]), colnames(vari)) - thelag <= 0, NA, 
                                             vari[match(phen$lonlat[x], row.names(vari)), match(as.character(phen$meanDate[x]), colnames(vari)) - thelag ]) )
}

Sys.time()
tic()
no_cores <- detectCores() - 1
cl<-makeCluster(no_cores)
registerDoParallel(cl)
var_for_phen_lag <- foreach (k = ints, .combine=cbind, .packages = c("correlation", "tidyverse")) %dopar% {
  # flexible date
  var_for_phen_lag_var1 <- relate_vars(var_loc[[var_list[1]]], thelag=k)
  var_for_phen_lag_var2 <- relate_vars(var_loc[[var_list[2]]], thelag=k)
  # fixed date
  # var_for_phen_lag_var1 <- relate_vars_fixed(var_loc[[var_list[1]]], thelag=k)
  # var_for_phen_lag_var2 <- relate_vars_fixed(var_loc[[var_list[2]]], thelag=k)
  cbind(var_for_phen_lag_var1, var_for_phen_lag_var2)
}
stopCluster(cl)
toc() # about 22 minutes (3:45h without parallelisation)
var_for_phen_lag <- var_for_phen_lag[,c(seq(1,length(ints)*2-1,2),seq(2,length(ints)*2,2))] # separate both variables
var_for_phen_lag_df <- as.data.frame(var_for_phen_lag) # rows: number of time series, columns: variables*lag
colnames(var_for_phen_lag_df) <- paste0(rep(var_list, each = length(ints)),"_l", rep(ints, length(var_list)))

# create Dataframe with both predictors and predictands ####
phen <- tibble(phen, var_for_phen_lag_df)

# colnames(phen)[str_detect(colnames(phen), "nc")] <- str_remove(colnames(phen)[str_detect(colnames(phen), "nc")], "_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc")
# colnames(phen)[str_detect(colnames(phen), "nc")] <- str_remove(colnames(phen)[str_detect(colnames(phen), "nc")], "_ens_mean_0.1deg_reg_v23.0e_runsum30zip.nc")
# colnames(phen)[str_detect(colnames(phen), "nc")] <- str_remove(colnames(phen)[str_detect(colnames(phen), "nc")], "_runsum30zip.nc")
colnames(phen)[str_detect(colnames(phen), "nc")] <- str_remove(colnames(phen)[str_detect(colnames(phen), "nc")], "_ens_mean_0.1deg_reg_v23.0e_runmean30_des.nc")
colnames(phen)[str_detect(colnames(phen), "nc")] <- str_remove(colnames(phen)[str_detect(colnames(phen), "nc")], "_ens_mean_0.1deg_reg_v23.0e_runsum30_des.nc")
colnames(phen)[str_detect(colnames(phen), "nc")] <- str_remove(colnames(phen)[str_detect(colnames(phen), "nc")], "_runsum30_des.nc")



# Exclusion of all the entries with dates before 1950 and entries located in the sea
var_cols <- str_detect(colnames(phen), "rr") | str_detect(colnames(phen), "tg")
phen_omit <- phen[complete.cases(phen[,var_cols]),] # drop rows with NAs
phen_red <- phen_omit [,c("species","phase_id", "lonlat", "lon", "lat", "alt", "year", "month", "date", "dataset", "cult_season", "day", colnames(phen_omit)[var_cols])] 

# Renest the data set again"
# Create list-columns (meta-data plus lists with corresponding climate and phenological data)
all_data <- phen_red %>%
  group_by(lonlat, phase_id, species, dataset, lon, lat, alt) %>%
  nest()




# Reduce based on certain features of a time series ####
########################################################

# Exclude time series where spring and winter Triticum seem to be mixed up
data_red <- all_data[!with(all_data, phase_id==13 & species=="Triticum aestivum Winter" & lonlat=="15.283 45.267"),]

"remember that you might still want to exclude data series with a clear split like Malus domestica, phase 87 and 95"


# 15 years time series (this is repeated at the end to exclude also time series who do not fulfill this after the next steps)
ts_len <-  sapply(data_red$data, dim) # length of each time series
# ts_lon <- which(ts_len[1,] >= 20) # threshold for time series length 
ts_lon <- which(ts_len[1,] >= 15) # threshold for time series length 
data_red <- data_red[ts_lon,] 


# Exclude phenophase at the transition from one year to another
# three entries of the hazel flowering are affected and one time Prunus persica flowering
# 02.02.22: only one entry of Hordeum vulgare is excluded now
ranges <- map_dbl(1:dim(data_red)[1], function(x) (diff(range(data_red[["data"]][[x]]$day))) )
for (i in seq_along(which(ranges > 300))){
  data_red[["data"]][[which(ranges > 300)[i]]] <- data_red[["data"]][[which(ranges > 300)[i]]][!data_red[["data"]][[which(ranges > 300)[i]]]$day >300,]
}



# Exclude all entries which are beyond 3*IQR away from the box
sds_pre <- map_dbl(1:dim(data_red)[1], function(x) (sd(data_red[["data"]][[x]]$day)) )
ranges_pre <- map_dbl(1:dim(data_red)[1], function(x) (diff(range(data_red[["data"]][[x]]$day))) )
summary(sds_pre)
summary(ranges_pre)

box_r3 <- pblapply(1:dim(data_red)[1], function(x) (boxplot.stats(data_red[["data"]][[x]]$day, coef = 3)) )
out_iqr_r3_pos <- lapply(1:dim(data_red)[1], function(x) (data_red[["data"]][[x]]$day %in% box_r3[[x]]$out) )
data_red[["data"]]<- lapply(1:dim(data_red)[1], function(x) (data_red[["data"]][[x]][!out_iqr_r3_pos[[x]],]) )

sds_aft <- map_dbl(1:dim(data_red)[1], function(x) (sd(data_red[["data"]][[x]]$day)) )
ranges_aft <- map_dbl(1:dim(data_red)[1], function(x) (diff(range(data_red[["data"]][[x]]$day))) )
summary(sds_aft)
summary(ranges_aft)


# Less than 3 unique values
num_val <- sapply(1:dim(data_red)[1], function(x) (length(unique(data_red[["data"]][[x]]$day))) ) # number of unique values
data_red <- data_red[-which(num_val<=3),]


# 15 years time series (this is repeated here to exclude also time series who do not fulfill this after the previous steps)
ts_len <-  sapply(data_red$data, dim) # length of each time series
# ts_lon <- which(ts_len[1,] >= 20) # threshold for time series length (At least 10 / 20 years (Templ.2017, Menzel.2001))
ts_lon <- which(ts_len[1,] >= 15) # threshold for time series length (At least 10 / 20 years (Templ.2017, Menzel.2001))
data_red <- data_red[ts_lon,] 



# Add phase_type and plant_type ####
source("./Code/Plant functional types and phenotypes.R")


# Calculate deviations from the mean date ####
for (i in 1:dim(data_red)[1]){
  data_red[["data"]][[i]]$devDOY <- data_red[["data"]][[i]]$day - mean(data_red[["data"]][[i]]$day)
}


# Categories of yearly precipitation sums similar to Jochner.2016

# This should be calculated on the final data set used for modelling
# because otherwise excluded time series will bias the calculation of quantiles


# extract yearly precipitation sum at each location
# Create matrix with daily precipitation
prec_daily_nc <- nc_open("D:/user/vogelj/Data/E-OBS/Processed/rr_ens_mean_0.1deg_reg_v23.0e_crop.nc")
prec_daily <- ncvar_get(prec_daily_nc, start=c(1,1,1), count=c(-1,-1,-1))
nc_close(prec_daily_nc)

prec_mat <- matrix(NA, loc_num, dim(prec_daily)[3])
for (i in 1:loc_num){ # Station locations
  prec_mat[i,] <- prec_daily[rowcols[i,2], rowcols[i,1],]
}

tg_daily <- nc_open("D:/user/vogelj/Data/E-OBS/Processed/tg_ens_mean_0.1deg_reg_v23.0e_crop.nc")
days_since_1950_daily <- tg_daily[["dim"]][["time"]][["vals"]]
dates_daily <- as_date(days_since_1950_daily, origin="1950-01-01")
nc_close(tg_daily)

for (i in seq_along(var_loc)){
  colnames(prec_mat) <- as.character(dates_daily)
  row.names(prec_mat) <- unique(phen_coord)
}


red_loc <- rownames(prec_mat) %in% unique(data_red$lonlat) # actual occurring locations in reduced data set
rr_red <- prec_mat[red_loc,] # reduced location set

# get yearly precipitation sum
rr_sum_loc <- apply(rr_red, 1, sum, na.rm = T)/length(1950:2020) 
plot(rr_sum_loc, main = "Yearly precipitation sum of all locations")
hist(rr_sum_loc, main = "Yearly precipitation sum of all locations")

# calculate percentiles (20% steps)
quants <- quantile(rr_sum_loc, probs = c(0.25, 0.5, 0.75, 1))

# look up table
rr_class_loc <- factor(x= "A", levels = c("A", "B", "C", "D"))
rr_class_loc[rr_sum_loc < quants[1]] <- "A"
rr_class_loc[rr_sum_loc > quants[1] & rr_sum_loc < quants[2]] <- "B"
rr_class_loc[rr_sum_loc > quants[2] & rr_sum_loc < quants[3]]  <- "C"
rr_class_loc[rr_sum_loc > quants[3] & rr_sum_loc < quants[4]]  <- "D"

# Add precipitation class to data frame ####
names(rr_class_loc) <- rownames(var_loc[[var_list[1]]])[red_loc]
names(rr_class_loc) <- rownames(var_loc[[var_list[1]]])[red_loc]
data_red$prec_class <- rr_class_loc[match(data_red$lonlat, names(rr_class_loc))]

plot(data_red$prec_class) # Die Zeitreihen sind ungleich verteilt, wenige trockene Standorte im Vergleich zu vielen feuchten Standorten


# plot it on map ####
# All points
# Reduced set of points
phen_sp_rr_class <- SpatialPointsDataFrame(coords = data.frame(phen_coord_unique$lon[red_loc],phen_coord_unique$lat[red_loc]),
                                           data = as.data.frame(rr_class_loc),
                                           proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
# png("./Code/Output/Precipitation_grouped_by_3percentiles.png", width = 17, height = 17, units = "cm", res = 1200)
plot(var_ras)
points(phen_sp_rr_class, col = phen_sp_rr_class@data[["rr_class_loc"]], pch=16)
# 1: black, 2: red, 3: green, 4: blue, 5: cyan
# dev.off()


# save(var_loc, data_red, all_data, phen, file = "./Code/Workspaces/Processed_data.RData")
save(var_loc, data_red, all_data, phen, file = "./Code/Workspaces/Processed_data_30day_des_4prec_classes.RData")
# var_loc: Subset of climate variables at all grid cells with phenological data
# data_red: data set used for modelling
# all_data: data set with (almost) all data prior to reduction
# phen: raw table with phenological dates and corresponding climate variables at certain lags
