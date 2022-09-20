#!/bin/bash

# to copy an individual file to this directory:
SRCNAME=dlnd.streams.txt.lnd.gpcc.icom_mpas
SRCPATH=$COMPYDATAPATH/usrdat/$SRCNAME
DSTPATH=$(pwd)/$SRCNAME

rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"
