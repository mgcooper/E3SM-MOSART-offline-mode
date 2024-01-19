#!/bin/bash

# the latest hex output:
# /compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901016/

# ------------------------------------------------------------
# copy E3SM output 
# ------------------------------------------------------------
# run_name=trib_basin.1997.2003.run.2023-06-16-120102.ats
run_name=sag_basin.2013.2019.run.2024-01-19-105008.ats
SRCPATH=$COMPY_SCRATCH_PATH/$run_name
DSTPATH=$USER_E3SM_OUTPUT_PATH

# this will create the directory at the end of SRCPATH in DSTPATH
rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# this will not create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH/" "$DSTPATH"

# ------------------------------------------------------------
# copy the sag run script to this directory:
# ------------------------------------------------------------
# SRCNAME=run.trib.sh
# SRCNAME=run.trib.test.sh
# SRCPATH=$COMPY_ROOT_PATH/qfs/people/coop558/projects/e3sm/sag/scripts/$SRCNAME
# DSTPATH=$(pwd)/$SRCNAME
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# ------------------------------------------------------------
# copy the dlnd.streams file to this directory:
# ------------------------------------------------------------
# SRCNAME=dlnd.streams.txt.lnd.gpcc.icom_mpas
# SRCNAME=user_dlnd.streams.txt.lnd.gpcc.ats.trib_basin
# SRCPATH=$COMPY_DATA_PATH/usrdat/$SRCNAME    
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
# copy a directory
# ------------------------------------------------------------
# SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901014/pyflowline/0001
# DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20220901014/pyflowline

# this will create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# this will not create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH/" "$DSTPATH"


# ------------------------------------------------------------
# copy a directory
# ------------------------------------------------------------
# SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901016/pyflowline/0001
# DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20220901016/pyflowline

# # this will create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# # this will not create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH/" "$DSTPATH"