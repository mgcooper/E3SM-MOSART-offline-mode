#!/bin/bash

# i think this one has the error chang
# /compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901016/

# ------------------------------------------------------------
# copy the gcam water demand data
# ------------------------------------------------------------

SRCPATH=$COMPY_ROOT_PATH/compyfs/zhou014/ICoM/GCAM_waterdemand_nc/rcp8.5
DSTPATH=$E3SM_DATA_PATH/compyfs/inputdata/waterdemand
SRCNAME=RCP8.5_GCAM_water_demand
MONTHS=( 01 02 03 04 05 06 07 08 09 10 11 12 )
# for i in "${arrayName[@]}"

for year in {1981..2018}; do
    # for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
    for month in "${MONTHS[@]}"; do

        FILENAME=${SRCNAME}_${year}_${month}.nc

        # TEST FIRST
        # printf "%s\n" "$SRCPATH/$FILENAME"

        # copy the files
        rsync -a -e ssh -P "$SRCPATH/$FILENAME" "$DSTPATH/$FILENAME"
    done
done

# ------------------------------------------------------------
# copy an individual file to this directory:
# ------------------------------------------------------------
# SRCNAME=dlnd.streams.txt.lnd.gpcc.icom_mpas
# SRCPATH=$COMPY_DATA_PATH/usrdat/$SRCNAME
# DSTPATH=$(pwd)/$SRCNAME
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# SRCNAME=RUNOFF05_2019_99.mat
# SRCPATH=$COMPY_ROOT_PATH/qfs/people/xudo627/ming/runoff/$SRCNAME
# DSTPATH=$(pwd)/$SRCNAME
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# ------------------------------------------------------------
# copy the hexwatershed mesh file:
# ------------------------------------------------------------
# SRCNAME=hexwatershed.json
# SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901014/hexwatershed/$SRCNAME
# DSTPATH=$(pwd)/$SRCNAME
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# ------------------------------------------------------------
# copy the flowline:
# ------------------------------------------------------------
# SRCNAME=flowline_conceptual.geojson
# SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901014/pyflowline/0001/$SRCNAME
# DSTPATH=$(pwd)/$SRCNAME
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# ------------------------------------------------------------
# copy a list of files:
# ------------------------------------------------------------
# SRCLIST=("flowline_conceptual.geojson" "flowline_conceptual_info.json")
# SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901014/pyflowline/0001
# DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20220901014/pyflowline
# for SRCNAME in "${SRCLIST[@]}"; do
#     rsync -a -e ssh -P "$SRCPATH/$SRCNAME" "$DSTPATH/$SRCNAME"    
#     # printf "%s/%s\n" "$SRCPATH" "$SRCNAME"
#     # printf "%s/%s\n" "$DSTPATH" "$SRCNAME"
# done

# SRCLIST=("mpas.geojson" "mpas_mesh_info.json")
# SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901014/pyflowline
# DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20220901014/pyflowline
# for SRCNAME in "${SRCLIST[@]}"; do
#     rsync -a -e ssh -P "$SRCPATH/$SRCNAME" "$DSTPATH/$SRCNAME"    
#     # printf "%s/%s\n" "$SRCPATH" "$SRCNAME"
#     # printf "%s/%s\n" "$DSTPATH" "$SRCNAME"
# done

# SRCLIST=("domain_lnd_Mid-Atlantic_MPAS_c220107.nc" "MOSART_Mid-Atlantic_MPAS_c220107.nc")
# SRCPATH=coop558@compy01:/compyfs/xudo627/new_mesh/inputdata
# DSTPATH=/Users/coop558/work/data/icom/hexwatershed/mpas_c220107
# for SRCNAME in "${SRCLIST[@]}"; do
#     rsync -a -e ssh -P "$SRCPATH/$SRCNAME" "$DSTPATH/$SRCNAME"    
#     # printf "%s/%s\n" "$SRCPATH" "$SRCNAME"
#     # printf "%s/%s\n" "$DSTPATH" "$SRCNAME"
# done


# SRCNAME=generate_Susquehanna.m
# SRCPATH=$COMPYROOTPATH/compyfs/xudo627/new_mesh/$SRCNAME
# DSTPATH=$(pwd)/$SRCNAME
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# ------------------------------------------------------------
# copy the pyflowline directory
# ------------------------------------------------------------
# SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901014/pyflowline/0001
# DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20220901014/pyflowline

# this will create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# this will not create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH/" "$DSTPATH"


# ------------------------------------------------------------
# copy the  directory
# ------------------------------------------------------------

# note the two different directories:
# /compyfs/icom/liao313/04model/pyhexwatershed/icom
# /compyfs/liao313/04model/pyhexwatershed/icom
# the latest data as of jan 2022 is in the first one:

# SRCPATH=coop558@compy01:/compyfs/icom/liao313/04model/pyhexwatershed/icom/pyhexwatershed20221115006/pyflowline
# DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20221115006/pyflowline

# SRCPATH=coop558@compy01:/compyfs/icom/liao313/04model/pyhexwatershed/icom/pyhexwatershed20221115006/hexwatershed
# DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20221115006/hexwatershed
# 
# if [ ! -d $DSTPATH ]; then mkdir $DSTPATH; fi

# this will create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# this will not create the directory at the end of SRCPATH in DSTPATH (it will copy the contents of the directory at the end of SRCPATH into the directory at the end of DSTPATH)
# rsync -a -e ssh -P "$SRCPATH/" "$DSTPATH"

# ------------------------------------------------------------
# copy the  ming pan runoff half-degree, daily
# ------------------------------------------------------------

# SRCPATH=$COMPY_ROOT_PATH/compyfs/inputdata/lnd/dlnd7/mingpan
# DSTPATH=/Users/coop558/work/data/e3sm/compyfs/inputdata/lnd/dlnd7
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"
