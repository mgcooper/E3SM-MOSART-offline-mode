#!/bin/bash

# USER case-specific values
SITE_NAME='icom_mpas'
RUN_ID='test'          # can be appended to CASE_NAME
START_YEAR=2006
END_YEAR=2008
MOSART_FILE=~/data/e3sm/config/MOSART_${SITE_NAME}.nc
DLND_DIR=/qfs/people/coop558/data/e3sm/usrdat
# DLND_FILE=user_dlnd.streams.txt.lnd.gpcc.${SITE_NAME}.${RUN_ID}
DLND_FILE=user_dlnd.streams.txt.lnd.gpcc.${SITE_NAME}
(( NUM_YEARS=END_YEAR-START_YEAR )) # let NUM_YEARS=END_YEAR-START_YEAR

# set configuration
RES=MOS_USRDAT
COMPSET=RMOSGPCC
MACH=compy
COMPILER=intel
PROJECT=esmd

SRC_DIR=~/source/unstructured/E3SM
CASE_DIR=~/projects/e3sm/sag/$SITE_NAME/cases
# CASE_DIR=${SRC_DIR}/cime/scripts

# set case name
CASE_NAME=${SITE_NAME}.${START_YEAR}.${END_YEAR}.run.$(date "+%Y-%m-%d")
# GIT_HASH=$(git log -n 1 --format=%h)
# CASE_NAME=${SITE_NAME}${GIT_HASH}.$(date "+%Y-%m-%d-%H%M%S")
# CASE_NAME=${SITE_NAME}.${START_YEAR}.${END_YEAR}.run.$(date "+%Y-%m-%d").${RUN_ID}

# create a new case using ./create_newcase script
cd ${SRC_DIR}/cime/scripts || exit
   ./create_newcase -case ${CASE_DIR}/"${CASE_NAME}" \
      -res ${RES} -mach ${MACH} -compiler ${COMPILER} -compset ${COMPSET} --project ${PROJECT}

# go into the case folder
cd ${CASE_DIR}/"${CASE_NAME}" || exit

# copy the user dland file and make it read/writeable
cp ${DLND_DIR}/"${DLND_FILE}" ./user_dlnd.streams.txt.lnd.gpcc
chmod +rw user_dlnd.streams.txt.lnd.gpcc

# make changes before setting up the case
./xmlchange LND_DOMAIN_PATH=~/data/e3sm/config
./xmlchange ATM_DOMAIN_PATH=~/data/e3sm/config
# ./xmlchange LND_DOMAIN_FILE=domain_lnd_Mid-Atlantic_MPAS_c220107.nc
# ./xmlchange ATM_DOMAIN_FILE=domain_lnd_Mid-Atlantic_MPAS_c220107.nc
./xmlchange LND_DOMAIN_FILE=domain_${SITE_NAME}.nc
./xmlchange ATM_DOMAIN_FILE=domain_${SITE_NAME}.nc

# modify env_mach_pes.xml
./xmlchange NTASKS=40 # og syntax
# ./xmlchange -file env_mach_pes.xml -id NTASKS -val 18 # my syntax

# modify env_run.xml
./xmlchange -file env_run.xml -id DOUT_S             	-val FALSE
./xmlchange -file env_run.xml -id INFO_DBUG          	-val 2
# ./xmlchange -file env_run.xml -id DLND_CPLHIST_YR_START -val ${START_YEAR}
# ./xmlchange -file env_run.xml -id DLND_CPLHIST_YR_END 	-val ${END_YEAR}

# modify env_build.xml
./xmlchange STOP_N=${NUM_YEARS}
./xmlchange STOP_OPTION=nyears
./xmlchange RUN_STARTDATE=${START_YEAR}-01-01
# ./xmlchange RUN_STARTDATE=1979-01-01 # og 
./xmlchange CLM_USRDAT_NAME=test_r05_r05
# ./xmlchange ELM_USRDAT_NAME=hcru_hcru
./xmlchange JOB_QUEUE=short
./xmlchange DEBUG=FALSE
./xmlchange CALENDAR=NO_LEAP

# mgc need to confirm these:
# ./xmlchange DATM_CLMNCEP_YR_END=1979
# ./xmlchange DATM_CLMNCEP_YR_START=1979
# ./xmlchange DATM_CLMNCEP_YR_ALIGN=1979
# ./xmlchange DLND_CPLHIST_YR_START=1979
# ./xmlchange DLND_CPLHIST_YR_END=2008
# ./xmlchange DLND_CPLHIST_YR_ALIGN=1979

# modify env_workflow.xml
# ./xmlchange -file env_run.xml -id JOB_WALLCLOCK_TIME # format is DD:HH:MM
# ./xmlchange -file env_run.xml -id JOB_QUEUE # format is DD:HH:MM
# ./xmlchange -file env_run.xml -id RUNDIR -val ${PWD}/run

# mgc check this
./preview_namelists

# this puts the text between << EOF and EOF into user_nl_mosart file even if it doesn't exist
# frivinp_rtm = '/compyfs/xudo627/new_mesh/inputdata/MOSART_Mid-Atlantic_MPAS_c220107.nc'
cat >> user_nl_mosart << EOF
frivinp_rtm = '$MOSART_FILE'
routingmethod = 1
inundflag = .true.
opt_elevprof = 1
EOF

cat >> user_nl_dlnd << EOF
dtlimit=2.0e0
EOF

./case.setup
./case.build
./case.submit

# mgc below builds a file list and then adds it to user_dlnd but that shouldn't be necessary
# so I moved the case.setup/build/submit above and commented below

#  ./case.setup

# files=""
# for i in {1979..2007}
# do
#    files="${files}ming_daily_$i.nc\n"
# done
# files="${files}ming_daily_2008.nc"
# echo "${files}"

# cp ${CASE_DIR}/${CASE_NAME}/CaseDocs/dlnd.streams.txt.lnd.gpcc ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
# chmod +rw ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
# perl -w -i -p -e "s@/compyfs/inputdata/lnd/dlnd7/hcru_hcru@/compyfs/xudo627/inputdata@" ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
# perl -pi -e '$a=1 if(!$a && s/GPCC.daily.nc/ming_daily_1979.nc/);' {CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
# perl -w -i -p -e "s@GPCC.daily.nc@${files}@" ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
# sed -i '/ZBOT/d' ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
# ./case.setup

# ./case.build

# ./case.submit