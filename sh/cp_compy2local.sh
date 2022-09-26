#!/bin/bash

# to copy an individual file to this directory:
# SRCNAME=dlnd.streams.txt.lnd.gpcc.icom_mpas
# SRCPATH=$COMPYDATAPATH/usrdat/$SRCNAME
# DSTPATH=$(pwd)/$SRCNAME

# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"

# to copy the hexwatershed mesh file:
# SRCNAME=hexwatershed.json
# SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901014/hexwatershed/$SRCNAME
# DSTPATH=$(pwd)/$SRCNAME

# to copy the flowline:
# SRCNAME=flowline_conceptual.geojson
# SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901014/pyflowline/0001/$SRCNAME
# DSTPATH=$(pwd)/$SRCNAME

# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"


# to copy a list of files:
SRCLIST=("flowline_conceptual.geojson" "flowline_conceptual_info.json")
SRCPATH=coop558@compy01:/compyfs/liao313/04model/pyhexwatershed/susquehanna/pyhexwatershed20220901014/pyflowline/0001
DSTPATH=/Users/coop558/mydata/icom/hexwatershed/pyhexwatershed20220901014/pyflowline

for SRCNAME in "${SRCLIST[@]}"; do
    rsync -a -e ssh -P "$SRCPATH/$SRCNAME" "$DSTPATH/$SRCNAME"
    
    # printf "%s/%s\n" "$SRCPATH" "$SRCNAME"
    # printf "%s/%s\n" "$DSTPATH" "$SRCNAME"
done