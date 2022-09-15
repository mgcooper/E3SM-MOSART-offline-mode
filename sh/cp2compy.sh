#!/bin/bash
filename=MOS_USRDAT_ICoM_MPAS.sh
SRCPATH=$(pwd)/$filename
DSTPATH=coop558@compy01:/qfs/people/coop558/projects/e3sm/icom/scripts/$filename
rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"
