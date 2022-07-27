# Procedure notes

##	Arbeitsverfahren
- Daten auf PC in Potsdam mit CDO prozessieren
- Auf Server übertragen und dort rechnen
- Daten über boxup übertragen ins Home Office übertragen


## CDO
- Change working directory
    - cd /mnt/d/user/vogelj/Data/E-OBS
    - cd /mnt/d/user/vogelj/Data/E-OBS/Raw
    - cd /mnt/d/user/vogelj/Data/E-OBS/Processed
- Crop data
    - cdo -z zip_1 -sellonlatbox,-11.50446,47.18304,26.80804,48.02232 pp_ens_mean_0.1deg_reg_v23.0e.nc pp_ens_mean_0.1deg_reg_v23.0e_crop.nc
    - cdo -z zip_1 -sellonlatbox,-11.50446,47.18304,26.80804,48.02232 qq_ens_mean_0.1deg_reg_v23.0e.nc qq_ens_mean_0.1deg_reg_v23.0e_crop.nc
    - cdo -z zip_1 -sellonlatbox,-11.50446,47.18304,26.80804,48.02232 tg_ens_mean_0.1deg_reg_v23.0e.nc tg_ens_mean_0.1deg_reg_v23.0e_crop.nc
    - cdo -z zip_1 -sellonlatbox,-11.50446,47.18304,26.80804,48.02232 tn_ens_mean_0.1deg_reg_v23.0e.nc tn_ens_mean_0.1deg_reg_v23.0e_crop.nc
    - cdo -z zip_1 -sellonlatbox,-11.50446,47.18304,26.80804,48.02232 tx_ens_mean_0.1deg_reg_v23.0e.nc tx_ens_mean_0.1deg_reg_v23.0e_crop.nc
    - cdo -z zip_1 -sellonlatbox,-11.50446,47.18304,26.80804,48.02232 rr_ens_mean_0.1deg_reg_v23.0e.nc rr_ens_mean_0.1deg_reg_v23.0e_crop.nc
- Frost
    - cdo -z zip_1 ltc,0 tn_ens_mean_0.1deg_reg_v23.0e_crop.nc frost_days.nc
- Running means
    - cdo -z zip_1 --timestat_date last runmean,30 pp_ens_mean_0.1deg_reg_v23.0e_crop.nc pp_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc
    - cdo -z zip_1 --timestat_date last runmean,30 qq_ens_mean_0.1deg_reg_v23.0e_crop.nc qq_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc
    - cdo -z zip_1 --timestat_date last runmean,30 tg_ens_mean_0.1deg_reg_v23.0e_crop.nc tg_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc
    - cdo -z zip_1 --timestat_date last runmean,30 tn_ens_mean_0.1deg_reg_v23.0e_crop.nc tn_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc
    - cdo -z zip_1 --timestat_date last runmean,30 tx_ens_mean_0.1deg_reg_v23.0e_crop.nc tx_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc
- Running sums
    - cdo -z zip_1 --timestat_date last runsum,30 rr_ens_mean_0.1deg_reg_v23.0e_crop.nc rr_ens_mean_0.1deg_reg_v23.0e_runsum30zip.nc
    - cdo -z zip_1 --timestat_date last runsum,30 frost_days.nc frost_days_runsum30zip.nc
- Running means
    - cdo -z zip_1 --timestat_date last runmean,15 pp_ens_mean_0.1deg_reg_v23.0e_crop.nc pp_ens_mean_0.1deg_reg_v23.0e_runmean15zip.nc
    - cdo -z zip_1 --timestat_date last runmean,15 qq_ens_mean_0.1deg_reg_v23.0e_crop.nc qq_ens_mean_0.1deg_reg_v23.0e_runmean15zip.nc
    - cdo -z zip_1 --timestat_date last runmean,15 tg_ens_mean_0.1deg_reg_v23.0e_crop.nc tg_ens_mean_0.1deg_reg_v23.0e_runmean15zip.nc
    - cdo -z zip_1 --timestat_date last runmean,15 tn_ens_mean_0.1deg_reg_v23.0e_crop.nc tn_ens_mean_0.1deg_reg_v23.0e_runmean15zip.nc
    - cdo -z zip_1 --timestat_date last runmean,15 tx_ens_mean_0.1deg_reg_v23.0e_crop.nc tx_ens_mean_0.1deg_reg_v23.0e_runmean15zip.nc
- Running sums
    - cdo -z zip_1 --timestat_date last runsum,15 rr_ens_mean_0.1deg_reg_v23.0e_crop.nc rr_ens_mean_0.1deg_reg_v23.0e_runsum15zip.nc
    - cdo -z zip_1 --timestat_date last runsum,15 frost_days.nc frost_days_runsum15zip.nc
- Deseasonalize after running mean
    - cdo -z zip_1 -L -ydaysub pp_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc -ydaymean pp_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc pp_ens_mean_0.1deg_reg_v23.0e_runmean30_des.nc
    - cdo -z zip_1 -L -ydaysub qq_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc -ydaymean qq_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc qq_ens_mean_0.1deg_reg_v23.0e_runmean30_des.nc
    - cdo -z zip_1 -L -ydaysub rr_ens_mean_0.1deg_reg_v23.0e_runsum30zip.nc -ydaymean rr_ens_mean_0.1deg_reg_v23.0e_runsum30zip.nc rr_ens_mean_0.1deg_reg_v23.0e_runsum30_des.nc
    - cdo -z zip_1 -L -ydaysub tg_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc -ydaymean tg_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc tg_ens_mean_0.1deg_reg_v23.0e_runmean30_des.nc
    - cdo -z zip_1 -L -ydaysub tn_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc -ydaymean tn_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc tn_ens_mean_0.1deg_reg_v23.0e_runmean30_des.nc
    - cdo -z zip_1 -L -ydaysub tx_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc -ydaymean tx_ens_mean_0.1deg_reg_v23.0e_runmean30zip.nc tx_ens_mean_0.1deg_reg_v23.0e_runmean30_des.nc
    - cdo -z zip_1 -L -ydaysub frost_days_runsum30zip.nc -ydaymean frost_days_runsum30zip.nc frost_days_runsum30_des.nc

- Deseasonalize directly after cropping (currently only used for cross correlation function)
    - cdo -z zip_1 -L -ydaysub pp_ens_mean_0.1deg_reg_v23.0e_crop.nc -ydaymean pp_ens_mean_0.1deg_reg_v23.0e_crop.nc pp_ens_mean_0.1deg_reg_v23.0e_des.nc
    - cdo -z zip_1 -L -ydaysub qq_ens_mean_0.1deg_reg_v23.0e_crop.nc -ydaymean qq_ens_mean_0.1deg_reg_v23.0e_crop.nc qq_ens_mean_0.1deg_reg_v23.0e_des.nc
    - cdo -z zip_1 -L -ydaysub rr_ens_mean_0.1deg_reg_v23.0e_crop.nc -ydaymean rr_ens_mean_0.1deg_reg_v23.0e_crop.nc rr_ens_mean_0.1deg_reg_v23.0e_des.nc
    - cdo -z zip_1 -L -ydaysub tg_ens_mean_0.1deg_reg_v23.0e_crop.nc -ydaymean tg_ens_mean_0.1deg_reg_v23.0e_crop.nc tg_ens_mean_0.1deg_reg_v23.0e_des.nc
    - cdo -z zip_1 -L -ydaysub tn_ens_mean_0.1deg_reg_v23.0e_crop.nc -ydaymean tn_ens_mean_0.1deg_reg_v23.0e_crop.nc tn_ens_mean_0.1deg_reg_v23.0e_des.nc
    - cdo -z zip_1 -L -ydaysub tx_ens_mean_0.1deg_reg_v23.0e_crop.nc -ydaymean tx_ens_mean_0.1deg_reg_v23.0e_crop.nc tx_ens_mean_0.1deg_reg_v23.0e_des.nc
    - cdo -z zip_1 -L -ydaysub frost_days.nc -ydaymean frost_days.nc frost_days_des.nc

Access to PC in Potsdam: GEOECOLOGY\vogelh

## Decisions
- r95 can have NA per definition. You can either set it to 0 then or exclude the variable. For now, I will exclude it.
- Spi3 is NA in Jan/Feb 1950. I will exclude this row of data in the respective time series.

## Infos
- Group Lasso: Not available for Poisson regression in glmnet
- Pep725: quality control flags are not in place yet
- Cook’s distance: No way to calculate it for cv.glmnet implemented
