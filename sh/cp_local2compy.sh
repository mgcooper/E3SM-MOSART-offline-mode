#!/usr/bin/env bash

# ------------------------------------------------------------
# COPY THE RUNOFF FILES FROM LOCAL TO COMPY
# ------------------------------------------------------------

# Full sag basin
SITENAME=sag_basin
RUNID=sag_basin
SRCLIST=("runoff_sag_basin_2013.nc" "runoff_sag_basin_2014.nc" "runoff_sag_basin_2015.nc" "runoff_sag_basin_2016.nc" "runoff_sag_basin_2017.nc" "runoff_sag_basin_2018.nc" "runoff_sag_basin_2019.nc")

# Trib basin
# RUNID=huc0802_gauge15906000_frozen_a5
# SRCLIST=("runoff_trib_basin_1997.nc" "runoff_trib_basin_1998.nc" "runoff_trib_basin_1999.nc" "runoff_trib_basin_2000.nc" "runoff_trib_basin_2001.nc" "runoff_trib_basin_2002.nc" "runoff_trib_basin_2003.nc")

SRCPATH=$USER_DATA_PATH/e3sm/forcing/$SITENAME/ats/$RUNID
# DSTPATH=$COMPY_DATA_PATH/e3sm/forcing/ats/$RUNID
DSTPATH=$COMPY_DATA_PATH/e3sm/forcing/ats

# Note: -a will create the destination directory if it does not exists.

for SRCNAME in "${SRCLIST[@]}"; do
    rsync -a -e ssh -P "$SRCPATH/$SRCNAME" "$DSTPATH/$SRCNAME"
    printf "%s/%s\n" "$SRCPATH" "$SRCNAME"
    printf "%s/%s\n" "$DSTPATH" "$SRCNAME"
done


# # ------------------------------------------------------------
# # COPY THE MOSART CONFIG FILE FROM LOCAL TO COMPY
# # ------------------------------------------------------------

# filename="MOSART_sag_basin.nc"
# SRCPATH="$USER_DATA_PATH/e3sm/config/$filename"
# DSTPATH="$COMPY_ROOT_PATH/qfs/people/coop558/data/e3sm/config"

# # # Check if the file already exists at the destination
# # # This isn't working, the -f doesn't work on the remote drive so I manually back up the file
# # # echo "$USER_DATA_PATH"
# # # echo "$COMPY_ROOT_PATH"
# # if [ -f "$DSTPATH/$filename" ]; then
# #     # echo "$DSTPATH/$filename"
# #     # Append the current date to the existing file's name
# #     backup_filename="${filename%.*}_$(date +%Y%m%d).${filename##*.}"
# #     # mv "$DSTPATH/$filename" "$DSTPATH/$backup_filename"
# #     printf "%s\n" "$DSTPATH/$backup_filename"
# # fi

# # Use rsync to copy the file
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH/$filename"

# # Print the paths (optional)
# # printf "%s -> %s\n" "$SRCPATH" "$DSTPATH/$filename"


# # ------------------------------------------------------------
# # COPY THE DOMAIN FILE FROM LOCAL TO COMPY
# # ------------------------------------------------------------
# 
# filename=domain_sag_basin.nc
# SRCPATH=$USER_DATA_PATH/e3sm/config/$filename
# DSTPATH=$COMPY_ROOT_PATH/qfs/people/coop558/data/e3sm/config/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"
# printf "%s/%s\n" "$SRCPATH" "$DSTPATH"
# 
# # ------------------------------------------------------------
# # COPY THE DLND FILE FROM LOCAL TO COMPY
# # ------------------------------------------------------------

# # filename=user_dlnd.streams.txt.lnd.gpcc.icom_mpas
# # filename=dlnd.streams.txt.lnd.gpcc.icom_mpas
# # filename=user_dlnd.streams.txt.lnd.gpcc.ats.trib_basin

# filename=user_dlnd.streams.txt.lnd.gpcc.ats.sag_basin
# SRCPATH=$(pwd)/$filename
# DSTPATH=coop558@compy01:/qfs/people/coop558/data/e3sm/usrdat/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# # ------------------------------------------------------------
# # COPY THE RUN SCRIPT FROM LOCAL TO COMPY
# # ------------------------------------------------------------

# # filename=MOS_USRDAT_ICoM_MPAS.sh
# # filename=run.icom_mpas.sh
# # filename=run.trib.sh

# filename=run.sag.ats.sh
# SRCPATH=$(pwd)/$filename
# DSTPATH=$COMPY_ROOT_PATH/qfs/people/coop558/projects/e3sm/sag/scripts/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"