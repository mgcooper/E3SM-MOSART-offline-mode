#!/bin/bash

# copy a folder from the compy scratch directory to local data directory:
SRCNAME=icom_mpas.2006.2008.run.2022-09-15
SRCPATH=$COMPYSCRATCHPATH/$SRCNAME
DSTPATH=$E3SMOUTPUTPATH/

rsync -a -e ssh -P "$SRCPATH" "$DSTPATH"
