#!/bin/bash
filename=dlnd.streams.txt.lnd.gpcc.icom_mpas
SRCPATH=coop558@compy01:/qfs/people/coop558/data/e3sm/usrdat/$filename
DSTPATH=$(pwd)/$filename

rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"
