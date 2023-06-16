#!/usr/bin/env bash

# ------------------------------------------------------------
# COPY THE RUNOFF FILES FROM LOCAL TO COMPY
# ------------------------------------------------------------
SRCLIST=("runoff_trib_basin_1997.nc" "runoff_trib_basin_1998.nc" "runoff_trib_basin_1999.nc" "runoff_trib_basin_2000.nc" "runoff_trib_basin_2001.nc" "runoff_trib_basin_2002.nc" "runoff_trib_basin_2003.nc")
SRCPATH=$USER_DATA_PATH/e3sm/forcing/trib_basin/ats/huc0802_gauge15906000_frozen_a5
DSTPATH=$COMPY_DATA_PATH/forcing/ats/huc0802_gauge15906000_frozen_a5

# Note: -a will create the destination directory if it does not exists.

for SRCNAME in "${SRCLIST[@]}"; do
    rsync -a -e ssh -P "$SRCPATH/$SRCNAME" "$DSTPATH/$SRCNAME"
    printf "%s/%s\n" "$SRCPATH" "$SRCNAME"
    printf "%s/%s\n" "$DSTPATH" "$SRCNAME"
done


# # ------------------------------------------------------------
# # COPY THE MOSART CONFIG FILE FROM LOCAL TO COMPY
# # ------------------------------------------------------------

# filename=MOSART_trib_basin.nc
# SRCPATH=$USER_DATA_PATH/e3sm/config/$filename
# DSTPATH=$COMPY_ROOT_PATH/qfs/people/coop558/data/e3sm/config/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"
# printf "%s/%s\n" "$SRCPATH" "$DSTPATH"

# # ------------------------------------------------------------
# # COPY THE DOMAIN FILE FROM LOCAL TO COMPY
# # ------------------------------------------------------------

# filename=domain_trib_basin.nc
# SRCPATH=$USER_DATA_PATH/e3sm/config/$filename
# DSTPATH=$COMPY_ROOT_PATH/qfs/people/coop558/data/e3sm/config/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"
# printf "%s/%s\n" "$SRCPATH" "$DSTPATH"

# # ------------------------------------------------------------
# COPY THE DLND FILE FROM LOCAL TO COMPY
# ------------------------------------------------------------

# filename=user_dlnd.streams.txt.lnd.gpcc.icom_mpas
# filename=dlnd.streams.txt.lnd.gpcc.icom_mpas

# filename=user_dlnd.streams.txt.lnd.gpcc.ats.trib_basin
# SRCPATH=$(pwd)/$filename
# DSTPATH=coop558@compy01:/qfs/people/coop558/data/e3sm/usrdat/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# ------------------------------------------------------------
# COPY THE RUN SCRIPT FROM LOCAL TO COMPY
# ------------------------------------------------------------

# filename=MOS_USRDAT_ICoM_MPAS.sh
# filename=run.icom_mpas.sh
# filename=run.trib.sh
# SRCPATH=$(pwd)/$filename
# DSTPATH=$COMPY_ROOT_PATH/qfs/people/coop558/projects/e3sm/sag/scripts/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"