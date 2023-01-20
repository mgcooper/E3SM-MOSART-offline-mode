#!/bin/bash


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
SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901016/pyflowline/0001
DSTPATH=/Users/coop558/work/data/icom/hexwatershed/pyhexwatershed20220901016/pyflowline

# this will create the directory at the end of SRCPATH in DSTPATH
rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# this will not create the directory at the end of SRCPATH in DSTPATH
rsync -a -e ssh -P "$SRCPATH/" "$DSTPATH"