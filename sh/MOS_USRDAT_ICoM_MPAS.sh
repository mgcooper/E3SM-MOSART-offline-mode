#!/bin/sh

RES=MOS_USRDAT
COMPSET=RMOSGPCC
MACH=compy
COMPILER=intel
PROJECT=esmd

SRC_DIR=~/e3sm_dev
CASE_DIR=${SRC_DIR}/cime/scripts

cd ${SRC_DIR}/cime/scripts

GIT_HASH=`git log -n 1 --format=%h`
CASE_NAME=ICoM_MPAS_${GIT_HASH}.`date "+%Y-%m-%d-%H%M%S"`

./create_newcase -case ${CASE_DIR}/${CASE_NAME} \
-res ${RES} -mach ${MACH} -compiler ${COMPILER} -compset ${COMPSET} --project ${PROJECT}


cd ${CASE_DIR}/${CASE_NAME}

./xmlchange -file env_run.xml -id DOUT_S             -val FALSE
./xmlchange -file env_run.xml -id INFO_DBUG          -val 2

./xmlchange CALENDAR=NO_LEAP

./xmlchange CLM_USRDAT_NAME=test_r05_r05
./xmlchange LND_DOMAIN_FILE=domain_lnd_Mid-Atlantic_MPAS_c220107.nc
./xmlchange ATM_DOMAIN_FILE=domain_lnd_Mid-Atlantic_MPAS_c220107.nc
./xmlchange LND_DOMAIN_PATH=/compyfs/xudo627/new_mesh/inputdata
./xmlchange ATM_DOMAIN_PATH=/compyfs/xudo627/new_mesh/inputdata

./xmlchange DATM_CLMNCEP_YR_END=1979
./xmlchange DATM_CLMNCEP_YR_START=1979
./xmlchange DATM_CLMNCEP_YR_ALIGN=1979
./xmlchange DLND_CPLHIST_YR_START=1979
./xmlchange DLND_CPLHIST_YR_END=2008
./xmlchange DLND_CPLHIST_YR_ALIGN=1979
./xmlchange RUN_STARTDATE=1979-01-01
#./xmlchange -file env_run.xml -id RUNDIR -val ${PWD}/run

./xmlchange NTASKS=40
./xmlchange STOP_N=30,STOP_OPTION=nyears

./preview_namelists

cat >> user_nl_mosart << EOF
frivinp_rtm = '/compyfs/xudo627/new_mesh/inputdata/MOSART_Mid-Atlantic_MPAS_c220107.nc'
routingmethod = 1
inundflag = .true.
opt_elevprof = 1
EOF

cat >> user_nl_dlnd << EOF
dtlimit=2.0e0
EOF

./case.setup

files=""
for i in {1979..2007}
do
   files="${files}ming_daily_$i.nc\n"
done
files="${files}ming_daily_2008.nc"
echo "${files}"

cp ${CASE_DIR}/${CASE_NAME}/CaseDocs/dlnd.streams.txt.lnd.gpcc ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
chmod +rw ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
perl -w -i -p -e "s@/compyfs/inputdata/lnd/dlnd7/hcru_hcru@/compyfs/xudo627/inputdata@" ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
perl -pi -e '$a=1 if(!$a && s/GPCC.daily.nc/ming_daily_1979.nc/);' {CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
perl -w -i -p -e "s@GPCC.daily.nc@${files}@" ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
sed -i '/ZBOT/d' ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
./case.setup

./case.build

./case.submit