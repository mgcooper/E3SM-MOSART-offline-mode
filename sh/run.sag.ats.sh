#!/bin/bash

# USER case-specific values
SITE_NAME='sag_basin'
RUN_ID='ats' 													# 'ats' or 'pan'
START_YEAR=2014
END_YEAR=2018
(( NUM_YEARS=END_YEAR-START_YEAR+1 ))
DLND_DIR=/qfs/people/coop558/data/e3sm/usrdat
DLND_FILE=user_dlnd.streams.txt.lnd.gpcc.${RUN_ID}.${SITE_NAME}
# DLND_FILE=user_dlnd.streams.txt.lnd.gpcc.pan 					# the mingpan runoff prepared by tian, in gridded format
# DLND_FILE=user_dlnd.streams.txt.lnd.gpcc.pan.test_basin 		# the ming pan runoff prepared by matt, in list (unstructured) format
# DLND_FILE=user_dlnd.streams.txt.lnd.gpcc.new 					# the updated GPCC


# set parameters
RES=MOS_USRDAT
COMPSET=RMOSGPCC
MACH=compy
COMPILER=intel
PROJECT=esmd
SRC_DIR=/qfs/people/coop558/source/unstructured/E3SM
CASE_DIR=/qfs/people/coop558/projects/e3sm/sag/cases

# set case name
CASE_NAME=${SITE_NAME}.${START_YEAR}.${END_YEAR}.run.$(date "+%Y-%m-%d-%H%M%S").${RUN_ID}
# GIT_HASH=`git log -n 1 --format=%h`
	
# create a new case using ./create_newcase script
cd ${SRC_DIR}/cime/scripts || exit
	./create_newcase -case ${CASE_DIR}/"${CASE_NAME}" \
		-res ${RES} -mach ${MACH} -compiler ${COMPILER} -compset ${COMPSET} --project ${PROJECT}	

# go into the case folder
cd ${CASE_DIR}/"${CASE_NAME}" || exit

# copy the user dland file
cp ${DLND_DIR}/${DLND_FILE} ./user_dlnd.streams.txt.lnd.gpcc

# make changes before setting up the case
# ./xmlchange ELM_USRDAT_NAME=hcru_hcru
./xmlchange LND_DOMAIN_FILE=domain_${SITE_NAME}.nc
./xmlchange ATM_DOMAIN_FILE=domain_${SITE_NAME}.nc
./xmlchange LND_DOMAIN_PATH=/qfs/people/coop558/data/e3sm/config
./xmlchange ATM_DOMAIN_PATH=/qfs/people/coop558/data/e3sm/config

# modify env_mach_pes.xml
./xmlchange -file env_mach_pes.xml -id NTASKS -val 18

# modify env_run.xml
./xmlchange -file env_run.xml -id DOUT_S             	-val FALSE
./xmlchange -file env_run.xml -id INFO_DBUG          	-val 2
./xmlchange -file env_run.xml -id DLND_CPLHIST_YR_START -val ${START_YEAR}
./xmlchange -file env_run.xml -id DLND_CPLHIST_YR_END 	-val ${END_YEAR}
./xmlchange -file env_run.xml -id DLND_CPLHIST_YR_ALIGN -val ${START_YEAR}
./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_START -val ${START_YEAR}
./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_END  	-val ${END_YEAR}
./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_ALIGN -val ${START_YEAR}


# modify env_build.xml
./xmlchange STOP_N=${NUM_YEARS}
./xmlchange STOP_OPTION=nyears
./xmlchange RUN_STARTDATE=${START_YEAR}-01-01
./xmlchange CLM_USRDAT_NAME=test_r05_r05
./xmlchange JOB_QUEUE=short
./xmlchange DEBUG=FALSE
./xmlchange CALENDAR=NO_LEAP

# modify env_case.xml
# ./xmlchange NAMELIST_DEFINITION_FILE=
# ./xmlchange CASEROOT=
# ./xmlchange CASE=

# modify env_workflow.xml
# ./xmlchange -file env_run.xml -id JOB_WALLCLOCK_TIME # format is DD:HH:MM
# ./xmlchange -file env_run.xml -id JOB_QUEUE # format is DD:HH:MM

# this puts the text between << EOF and EOF into user_nl_mosart file even if it doesn't exist
fmosart=/qfs/people/coop558/data/e3sm/config/MOSART_${SITE_NAME}.nc

# this writes the default variables to daily timestep, one file per year
cat >> user_nl_mosart << EOF
frivinp_rtm = '$fmosart'
rtmhist_nhtfrq=-24
rtmhist_mfilt=365
EOF

# this writes the default variables to monthly timestep, one file per year, and fincl2 variables to daily timestep, one file per year
# cat >> user_nl_mosart << EOF
# frivinp_rtm = '$fmosart'
# rtmhist_fincl2="RIVER_DISCHARGE_OVER_LAND_LIQ","RIVER_DISCHARGE_TO_OCEAN_LIQ"
# rtmhist_nhtfrq=0,-24
# rtmhist_mfilt=12,365
# EOF

# note:
# rtmhist_nhtfrq=0,-24 	# 0=monthly average, -24=daily average
# rtmhist_mfilt=12,365 	# the number of time slices in these files

# run it
./case.setup
./case.build
./case.submit --mail-user matt.cooper@pnnl.gov --mail-type all

# ./case.setup --reset
# ./case.build --clean
# ./case.submit --mail-user matt.cooper@pnnl.gov --mail-type all


################## NOTES and references
# use <squeue> to see the queue

# modify env_mach_pes.xml # shouldn't need to change anything here, below was to get mosart unstructured
# ./xmlchange NTASKS=15
# ./xmlchange -file env_mach_pes.xml -id NTASKS -val 3266
# modify env_mach_specific.xml # shouldn't ever have to change anything here
# modify env_archive.xml
# modify env_batch.xml (slurm stuff)
# modify env_run.xml
#./xmlchange -file env_run.xml -id PIO_REARR_COMM_MAX_PEND_REQ_COMP2IO       -val -1
#./xmlchange -file env_run.xml -id PIO_REARR_COMM_MAX_PEND_REQ_IO2COMP       -val -1
# modify env_build.xml
# ./xmlchange CIME_OUTPUT_ROOT=/path/to/output # default = /compyfs/coop558/e3sm_scratch (DON'T change, use archive)

# for setting up custom surf data
# cat >> user_nl_elm << EOF
# fsurdat = '<path-to-new-fsurdat-file>/<new-fsurdat-file>'
# EOF
