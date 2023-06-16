#!/usr/bin/env bash

# Copy water demand files to compute server
SRCPATH=$USER_E3SM_FORCING_PATH/icom_domain/drbc_water_use/
DSTPATH=$COMPY_E3SM_FORCING_PATH/icom_domain/drbc_water_use/

# Check source and dest paths exist 
if [ ! -d "$SRCPATH" ]; then 
    echo "Source path $SRCPATH does not exist!" 
    exit 1 
fi
if [ ! -d "$DSTPATH" ]; then 
    echo "Destination path $DSTPATH does not exist!" 
    exit 1 
fi  

# Create destination dir if it doesn't exist 
if [ ! -d "$DSTPATH" ]; then mkdir "$DSTPATH"; fi  

# Copy files with rsync 
if ! rsync -av -e ssh -P "$SRCPATH" "$DSTPATH"; then
    echo "Rsync failed!"
    exit 1 
fi

echo "Files copied successfully!"

# /Users/coop558/work/data/e3sm/forcing/icom_domain/drbc_water_use

# # Copy the water demand files to compy
# SRCPATH=$USER_E3SM_FORCING_PATH/icom_domain/drbc_water_use/
# DSTPATH=$COMPY_E3SM_FORCING_PATH/icom_domain/drbc_water_use/

# if [ ! -d "$DSTPATH" ]; then mkdir "$DSTPATH"; fi

# # this will create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"


# filename=MOS_USRDAT_ICoM_MPAS.sh
# filename=run.icom_mpas.sh
# SRCPATH=$(pwd)/$filename
# DSTPATH=coop558@compy01:/qfs/people/coop558/projects/e3sm/icom_mpas/scripts/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"


# filename=user_dlnd.streams.txt.lnd.gpcc.icom_mpas
# filename=dlnd.streams.txt.lnd.gpcc.icom_mpas
# SRCPATH=$(pwd)/$filename
# DSTPATH=coop558@compy01:/qfs/people/coop558/data/e3sm/usrdat/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"