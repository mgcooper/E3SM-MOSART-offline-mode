#!/bin/bash

# i think this one has the error chang
# /compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901016/

# ------------------------------------------------------------
# copy an individual file to this directory:
# ------------------------------------------------------------
# SRCNAME=dlnd.streams.txt.lnd.gpcc.icom_mpas
# SRCPATH=$COMPYDATAPATH/usrdat/$SRCNAME
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

# note the two different directories:
# /compyfs/icom/liao313/04model/pyhexwatershed/icom
# /compyfs/liao313/04model/pyhexwatershed/icom
# the latest data as of jan 2022 is in the first one:

# SRCPATH=coop558@compy01:/compyfs/icom/liao313/04model/pyhexwatershed/icom/pyhexwatershed20221115006/pyflowline
# DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20221115006/pyflowline

SRCPATH=coop558@compy01:/compyfs/icom/liao313/04model/pyhexwatershed/icom/pyhexwatershed20221115006/hexwatershed
DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20221115006/hexwatershed

if [ ! -d $DSTPATH ]; then mkdir $DSTPATH; fi

# this will create the directory at the end of SRCPATH in DSTPATH
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# this will not create the directory at the end of SRCPATH in DSTPATH (it will copy the contents of the directory at the end of SRCPATH into the directory at the end of DSTPATH)
rsync -a -e ssh -P "$SRCPATH/" "$DSTPATH"