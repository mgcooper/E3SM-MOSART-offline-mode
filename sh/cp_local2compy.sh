#!/bin/bash

# filename=MOS_USRDAT_ICoM_MPAS.sh
# filename=run.icom_mpas.sh
# SRCPATH=$(pwd)/$filename
# DSTPATH=coop558@compy01:/qfs/people/coop558/projects/e3sm/icom_mpas/scripts/$filename
# rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"


# filename=user_dlnd.streams.txt.lnd.gpcc.icom_mpas
filename=dlnd.streams.txt.lnd.gpcc.icom_mpas
SRCPATH=$(pwd)/$filename
DSTPATH=coop558@compy01:/qfs/people/coop558/data/e3sm/usrdat/$filename
rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"